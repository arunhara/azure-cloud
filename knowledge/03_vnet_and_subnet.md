# Step 3: VNet and Subnet (Beginner Friendly Guide)

This document explains, from scratch, what a **Virtual Network (VNet)** and **subnet** are, why they are needed, and exactly how Terraform creates them in this project.

If you are new to Azure + Terraform, read this top-to-bottom once, then run the commands in the "How Terraform Creates It" section.

---

## 1) Concepts First (Plain English)

### What is a VNet?

A **Virtual Network** is your private network in Azure.

Think of it like your office building boundary:

- The building = **VNet**
- Rooms/floors inside the building = **subnets**
- People/resources (VMs, app services, databases) live in specific rooms/subnets

Without a VNet, many private networking scenarios are not possible.

### What is a subnet?

A **subnet** is a smaller network range inside the VNet.

You create subnets to separate workloads, for example:

- `app` subnet for app services/VMs
- `data` subnet for databases/private endpoints

This helps with:

- clean organization
- security policy separation (later with NSGs and routes)
- future scaling

### What is CIDR (like `10.10.0.0/16`)?

CIDR defines IP ranges.

- VNet range: larger block, for example `10.10.0.0/16`
- Subnet range: smaller block inside it, for example `10.10.1.0/24`

Rules:

- subnet range must be inside VNet range
- subnets must not overlap each other
- dev and prod should use different VNet ranges

---

## 2) What This Project Creates

For each environment (`dev`, `prod`), Terraform creates:

1. One VNet
2. Multiple subnets from a map

Current naming pattern:

- VNet: `vnet-{org_name}-{environment}`
- Example: `vnet-philomath-dev`

Current environment CIDRs:

- **dev**
  - VNet: `10.10.0.0/16`
  - Subnets: `app = 10.10.1.0/24`, `data = 10.10.2.0/24`
- **prod**
  - VNet: `10.20.0.0/16`
  - Subnets: `app = 10.20.1.0/24`, `data = 10.20.2.0/24`

---

## 3) Where the Terraform Code Lives

### Reusable module

- Path: `modules/network/`
- Files:
  - `main.tf` -> actual Azure resources
  - `variables.tf` -> inputs for customization
  - `outputs.tf` -> values returned to callers

### Environment entry points

- `environments/dev/main.tf`
- `environments/prod/main.tf`

Each environment calls the same module with different values.

---

## 4) How the Module Works

The module creates these Azure resources:

- `azurerm_virtual_network` (the VNet)
- `azurerm_subnet` (one resource per subnet map item)

Important behavior:

- `for_each = var.subnet_prefixes` tells Terraform to expand this block into **one subnet resource per map entry**.
- If the map has `app` and `data`, Terraform creates 2 subnets.
- If you later add `private-endpoints = "10.10.3.0/24"`, Terraform creates one more subnet.

### How Terraform knows to “loop” (`for_each`)

Terraform does **not** use a `for` loop keyword on resources. Instead, **`for_each` is a special argument (a “meta-argument”)** on the `resource` block.

When you write:

```hcl
resource "azurerm_subnet" "subnet" {
  for_each = var.subnet_prefixes
  # ...
}
```

Terraform looks at the **type and shape** of `var.subnet_prefixes`:

- In this module it is declared as `map(string)` in `modules/network/variables.tf`.
- For a **map**, Terraform creates **one instance** of `azurerm_subnet.subnet` for **each key** in that map.

So “looping” is really: **Terraform multiplies this single block into N separate resource instances**, where N is the number of keys in the map. There is no separate loop syntax—`for_each` *is* the mechanism.

You can also use `for_each` with a **set of strings** (e.g. `toset(["a", "b"])`) where each string becomes one instance; here we use a map because each subnet needs both a **name** (key) and a **CIDR** (value).

### How the `each` object is used

Inside **any** block that has `for_each`, Terraform defines a read-only object named **`each`**. It exists **only** in that block’s body.

For **`for_each` over a map** (our case):

| Expression   | Meaning |
|-------------|---------|
| `each.key`  | The map **key** — here, the subnet **name** Terraform will use in Azure (e.g. `app`, `data`). |
| `each.value`| The map **value** — here, the **CIDR string** for that subnet (e.g. `10.10.1.0/24`). |

Applied to the subnet resource:

```9:16:modules/network/main.tf
resource "azurerm_subnet" "subnet" {
  for_each = var.subnet_prefixes

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value]
}
```

- `name = each.key` — Azure subnet name comes from the tfvars map key.
- `address_prefixes = [each.value]` — Azure expects a **list** of prefixes; we wrap the single CIDR string in `[...]`.

**Addresses in state and references:** instances are indexed by map key, for example:

- `azurerm_subnet.subnet["app"]`
- `azurerm_subnet.subnet["data"]`

So elsewhere in Terraform you refer to a specific subnet by that index, or use `azurerm_subnet.subnet` as a map of all instances.

---

## 5) Inputs and Outputs (What Goes In and Comes Out)

### Module inputs

- `name`: VNet name
- `location`: Azure region
- `resource_group_name`: existing resource group name
- `address_space`: list of VNet CIDRs
- `subnet_prefixes`: map of subnet name => CIDR
- `tags`: resource tags

### Module outputs

- `vnet_id`: Azure resource ID of VNet
- `vnet_name`: VNet name
- `subnet_ids`: map of subnet name => subnet ID

Why outputs matter:

- future modules (VM, storage private endpoint, AKS, firewall, etc.) can consume these IDs without hardcoding.

---

## 6) How Terraform Creates It (Execution Flow)

When you run Terraform in an environment folder, this is the flow:

1. Terraform reads `main.tf`, `variables.tf`, and auto-loaded values from `*.auto.tfvars`.
2. It loads module code from `../../modules/network`.
3. It builds a dependency graph:
   - resource group must exist first
   - VNet is created in that resource group
   - subnets are created inside that VNet
4. `terraform plan` shows what will be created.
5. `terraform apply` calls Azure APIs and creates resources.
6. Terraform writes created resource IDs to that environment state file.

Because dev and prod run in separate folders/state files, they are isolated from each other.

---

## 7) Commands to Run (Step by Step)

Run from `environments/dev` first:

```powershell
terraform init -upgrade
terraform validate
terraform plan
terraform apply
```

Then do the same from `environments/prod` when ready.

What to expect in `plan`:

- 1 VNet to add
- N subnets to add (based on your map)

---

## 8) How to Confirm in Azure Portal

After apply:

1. Open your resource group (`rg-philomath-dev` or `rg-philomath-prod`).
2. Open the created VNet.
3. Check "Address space" matches expected CIDR.
4. Check "Subnets" list contains expected names and CIDRs.

If names/CIDRs differ, check your environment tfvars values.

---

## 9) Common Beginner Mistakes and Fixes

### Mistake: Overlapping ranges

- Example: dev subnet `10.10.1.0/24` and another subnet also inside same range.
- Fix: use non-overlapping CIDRs.

### Mistake: Subnet outside VNet range

- Example: VNet `10.10.0.0/16`, subnet `10.30.1.0/24`.
- Fix: subnet must be inside VNet range.

### Mistake: Running in wrong folder

- Running in root instead of `environments/dev` can target wrong config/state.
- Fix: always run in the environment folder you intend to change.

### Mistake: Expecting tfvars to be shared automatically

- `*.auto.tfvars` is ignored in this repo.
- Fix: share non-secret defaults via `*.example` files or docs.

---

## 10) Why This Step Comes Right After Resource Group

Logical infrastructure order:

1. Resource Group
2. Network (VNet/Subnets)  <- this step
3. Security controls (NSG/UDR)
4. Compute/data services into those subnets

This order avoids redesign later.

---

## Summary

- A VNet is your private Azure network; subnets split it into workload zones.
- Terraform creates VNet first, then subnets, using one reusable module.
- Dev and prod use the same code, different CIDR inputs, separate state.
- Next step: add NSGs and associate them with subnets.
