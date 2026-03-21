# Step 4: Network Security Groups (NSGs) and Subnet Association

This document explains what an **NSG** is, why subnets get one in this project, how Terraform creates and **associates** them, and how to add **security rules** when you need explicit allow/deny behavior.

Prerequisite: [Step 3: VNet and Subnet](03_vnet_and_subnet.md) (VNet and subnets already exist).

---

## 1) Concepts (Plain English)

### What is a Network Security Group?

An **NSG** is Azure’s stateful **packet filter** attached to **network interfaces** or **subnets**. It evaluates traffic against **rules** (allow/deny, direction, ports, source/destination).

Think of it as a **firewall policy object**: the NSG holds rules; the **association** says “apply this policy to this subnet (or NIC).”

### Why associate an NSG to a subnet?

When an NSG is **associated with a subnet**, the rules apply to **all resources in that subnet** (unless overridden by NIC-level NSGs—NIC rules are evaluated too; this project uses **subnet-level** NSGs only).

Benefits:

- **Consistent policy** for everything in that subnet (e.g. all app-tier VMs or private endpoints).
- **Clear place to evolve security** as you add services (add rules to the right NSG).
- **Separation by tier**: `app` NSG vs `data` NSG can diverge over time.

### Default rules vs your rules

Every NSG includes **platform default rules** (for example, traffic within the VNet, load balancer probes, and a final deny). Those defaults are **not** defined in this repo’s Terraform unless you add them explicitly.

This step creates **empty** NSGs (no custom `security_rule` resources yet) and associates them. That is enough to:

- establish the **attachment** pattern in Terraform and Azure, and  
- add **explicit** allow/deny rules later without redesign.

---

## 2) What This Project Creates (Step 4)

For **each key** in `subnet_prefixes` (e.g. `app`, `data`), Terraform now creates:

1. **`azurerm_network_security_group`** — one NSG named `nsg-<subnet-key>` (e.g. `nsg-app`, `nsg-data`) in the same resource group as the VNet.
2. **`azurerm_subnet_network_security_group_association`** — links that NSG to the subnet with the **same** key.

So the **map keys** for subnets and NSGs stay aligned: one subnet name → one subnet → one NSG → one association.

Important Azure constraint: a subnet may have **at most one** subnet-level NSG association. This design respects that (exactly one per subnet).

---

## 3) Where the Code Lives

| Piece | Location |
|--------|-----------|
| VNet, subnets, NSGs, associations | `modules/network/main.tf` |
| Module outputs (`subnet_ids`, `nsg_ids`) | `modules/network/outputs.tf` |
| Environment wiring (unchanged module call) | `environments/dev/main.tf`, `environments/prod/main.tf` |
| Root outputs exposing `nsg_ids` | `environments/dev/outputs.tf`, `environments/prod/outputs.tf` |

No new variables are required in environments for this step: NSGs are driven by the **same** `subnet_prefixes` map as the subnets.

---

## 4) How Terraform Implements It

### Same `for_each` keys as subnets

Subnets are already created with:

```hcl
for_each = var.subnet_prefixes
```

NSGs and associations reuse **`var.subnet_prefixes`** with the **same** `for_each` so each instance shares the same key (`app`, `data`, …).

### Resources (conceptual)

1. **NSG** — `for_each = var.subnet_prefixes`  
   - `name = "nsg-${each.key}"`  
   - Same `location`, `resource_group_name`, and `tags` as the rest of the module.

2. **Association** — `for_each = var.subnet_prefixes`  
   - `subnet_id = azurerm_subnet.subnet[each.key].id`  
   - `network_security_group_id = azurerm_network_security_group.subnet[each.key].id`  

The `[each.key]` indexing ties the three resources (subnet, NSG, association) to the **same** map entry.

### Outputs

- **`nsg_ids`**: map of subnet name → NSG resource ID, for future modules (e.g. logging, policy, or documentation).

---

## 5) Adding Security Rules (When You Need Them)

Custom rules are typically **`azurerm_network_security_rule`** resources (separate from the NSG body) or `security_rule` blocks on the NSG, depending on team style. HashiCorp’s docs cover both patterns.

Example pattern (illustrative only—adjust sources, ports, and priority for your security model):

```hcl
resource "azurerm_network_security_rule" "app_allow_https_inbound" {
  name                        = "AllowHTTPSInbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.subnet["app"].name
}
```

Notes:

- **Priority** must be unique within that NSG; lower numbers are evaluated first.
- Opening **Internet → subnet** is powerful; prefer **jump boxes**, **private access**, **Application Gateway**, or **private endpoints** when possible.
- For **east-west** traffic (e.g. app subnet → SQL on data subnet), rules often use **service tags**, **IP ranges**, or **Application Security Groups** instead of `Internet`.

Place new rules in the **module** next to the NSG resources, or introduce a dedicated submodule when rule sets grow large.

---

## 6) Commands to Apply

From `environments/dev` (then `environments/prod` when ready):

```powershell
terraform plan
terraform apply
```

What to expect in **plan** (relative to before Step 4):

- **2 × N** new resources for **N** subnets: **N** NSGs + **N** associations (e.g. for `app` and `data`, **4** new resources).

---

## 7) How to Confirm in Azure Portal

1. Open the environment resource group (e.g. `rg-philomath-dev`).
2. Find NSGs named **`nsg-app`**, **`nsg-data`** (or your subnet keys).
3. Open the VNet → **Subnets** → select a subnet → verify **Network security group** shows the matching NSG.
4. Open the NSG → **Inbound/Outbound security rules** — you will see **default** rules; custom rules appear here after you add them in Terraform.

---

## 8) Common Pitfalls

| Issue | What to know |
|--------|----------------|
| **One NSG per subnet** | Azure allows one subnet-level NSG per subnet; don’t associate two. |
| **Rule priority clashes** | Duplicate priorities in the same NSG cause API/Terraform errors. |
| **Overly broad `source_address_prefix`** | `*` or `Internet` is easy but risky; tighten for production. |
| **NSG on subnet vs NIC** | This project uses **subnet** association; NIC-level NSGs are a different pattern. |

---

## 9) Why This Step Comes After VNet/Subnets

Order:

1. Resource group  
2. VNet + subnets (addressing)  
3. **NSGs + associations (policy shell)** ← this step  
4. Optional: route tables (UDR), then workloads (VMs, private endpoints, etc.)

Putting NSGs in place early avoids “everything is wide open” drift while you still have few resources.

---

## Summary

- An **NSG** holds firewall rules; **associating** it to a subnet applies those rules to resources in that subnet.
- This repo creates **one NSG per `subnet_prefixes` key** and associates it to the matching subnet using the same `for_each` keys.
- NSGs start with **no custom rules** in Terraform; **default** Azure rules still apply; add **`azurerm_network_security_rule`** when you need explicit allows/denies.
- **`nsg_ids`** is exported from the network module and environments for downstream use.

**Next (optional):** route tables / UDRs for hub-spoke or forced tunneling, then placing workloads into subnets.
