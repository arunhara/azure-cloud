# Step 2: Resource Group

We add a **resource group** per environment so all other resources (VNet, Databricks, Key Vault, Storage) live inside it.

---

## What We're Creating

| Item | Details |
|------|--------|
| **Azure resource** | One `azurerm_resource_group` per environment (dev, prod). |
| **Naming** | `rg-{org_name}-{environment}` → e.g. `rg-philomath-dev`, `rg-philomath-prod`. |
| **Location** | Australia East (from `var.location`). |
| **Tags** | Optional: `Environment`, `Project`, `ManagedBy = Terraform`. |

---

## Terraform Resource

- **Type:** `azurerm_resource_group`
- **Arguments we'll use:** `name`, `location`, `tags`.

---

## Module Layout

- **Path:** `modules/resource-group/`
- **Files:** `main.tf` (resource), `variables.tf` (inputs), `outputs.tf` (resource group `id`, `name`, `location`).

**Inputs:** `name`, `location`, `tags` (optional).

**Outputs:** `id`, `name`, `location` (so other modules can reference the resource group).

---

## Reusing the Same Module in Dev and Prod

We write the **resource-group module once** and use it for both dev and prod. Only the **inputs** (and where we run Terraform) change; the code stays the same.

**One module, two uses**

- The module under `modules/resource-group/` defines *how* to create a resource group (name, location, tags). It does **not** hard-code "dev" or "prod".
- Each **environment** has its own Terraform root (e.g. `environments/dev/` and `environments/prod/`). Each root has its own `main.tf` that **calls** the same module with different variable values.

**How it works in practice**

1. **Dev:** You run `terraform apply` from `environments/dev/` (using e.g. `dev.auto.tfvars`). That run calls the resource-group module with `environment = "dev"`, so the module creates a resource group named `rg-philomath-dev` in Australia East. Terraform stores this in **dev's state file** (e.g. `environments/dev/terraform.tfstate`).

2. **Prod:** You run `terraform apply` from `environments/prod/` (using e.g. `prod.auto.tfvars`). That run calls the **same** module with `environment = "prod"`, so the module creates a resource group named `rg-philomath-prod` in Australia East. Terraform stores this in **prod's state file** (e.g. `environments/prod/terraform.tfstate`).

So:

- **Same module code** → used by both dev and prod.
- **Different inputs** (e.g. `environment`, or different tags/SKUs) → different resource names and settings.
- **Separate state per environment** → dev and prod don't overwrite each other; you can change one without affecting the other.

**Example (conceptual)**

In `environments/dev/main.tf` you might have:

```hcl
module "resource_group" {
  source   = "../../modules/resource-group"
  name     = "rg-${var.org_name}-${var.environment}"   # e.g. rg-philomath-dev
  location = var.location
  tags     = var.tags
}
```

In `environments/prod/main.tf` the block is the **same**; only `var.environment` (and possibly `var.tags`) come from `prod.auto.tfvars`, so the created resource group is `rg-philomath-prod`. No copy-paste of the resource group logic—just one module, two calls, two resource groups.

---

## How It Gets Used

- **Environments** (Step 9): `environments/dev` and `environments/prod` will each call this module with their own `environment` value and use the same `location` and `org_name`. So we don't add a root-level `main.tf` that creates the resource group; the **environment** folder will call the module.
- For **this step** we only add the **module** and a **single example use** so you can run `terraform plan` from one place (e.g. root or `environments/dev`) and see the resource group. So we'll add:
  1. The reusable module under `modules/resource-group/`.
  2. A way to run it (e.g. root `main.tf` that calls the module with `environment = "dev"` for now, or a minimal `environments/dev/main.tf`). That way you can plan/apply and see the resource group created.

---

## Verification

After implementation:

- From the directory that calls the module (root or `environments/dev`):  
  `terraform plan` should show **1 resource to add** (the resource group).  
- After `terraform apply`, Azure will show `rg-philomath-dev` (or `rg-philomath-prod` if you applied from prod) in Australia East.

---

## Summary

- One reusable **resource-group** module.
- One resource group per environment; naming: `rg-philomath-{dev|prod}`, location Australia East.
- Next step after this: **Step 3 – Network** (`03_network.md`).

---

## What to Do Next to Validate (Step 2)

Run these from the **project root** (`c:\Code\azure-cloud`):

1. **Re-initialize** (so Terraform picks up the new module):
   ```powershell
   terraform init
   ```

2. **Validate** the configuration:
   ```powershell
   terraform validate
   ```
   You should see: `Success! The configuration is valid.`

3. **Plan** (no changes made; shows what would be created):
   ```powershell
   terraform plan
   ```
   You should see **1 resource to add** (the resource group, e.g. `rg-philomath-dev`).

4. **Apply** (optional – creates the resource group in Azure):
   ```powershell
   terraform apply
   ```
   Type `yes` when prompted. Then check the Azure Portal: resource group `rg-philomath-dev` should exist in Australia East.

**Note:** You must be logged in to Azure (`az login`) and have permissions to create resources in the subscription. To target prod later, use a different root (e.g. `environments/prod`) or pass `-var="environment=prod"` when we wire environments in Step 9.
