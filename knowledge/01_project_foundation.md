# Step 1: Project Foundation

This step sets up the Terraform project so we can run `terraform init` and have a place for all future resources. **No Azure resources are created yet** – only configuration files and folder structure.

---

## What We're Creating (No Azure Resources)

| Item | Purpose |
|------|--------|
| `versions.tf` | Pins Terraform and Azure provider versions so runs are consistent. |
| Azure provider block | Tells Terraform to use Azure (azurerm). |
| Base `variables.tf` | Defines variables we'll use across the project (org, region, environment, etc.). |
| Empty or minimal `outputs.tf` | Placeholder for outputs we'll add as we add resources. |
| Folder structure | `modules/` and `environments/dev/`, `environments/prod/` as planned. |

---

## 1. Terraform and Provider Versions (`versions.tf`)

- **Terraform:** `>= 1.0`
- **Azure Provider (azurerm):** `~> 4.0`

No `backend` block in this step – we start with **local state**. Backend can be added later.

---

## 2. Azure Provider Configuration

- **Provider:** `azurerm` with `features {}`.
- Optional: `subscription_id` from variable (if empty, uses default from Azure CLI).
- **Note:** The azurerm provider does **not** support a top-level `location` argument; each resource sets its own `location`.

---

## 3. Base Variables (`variables.tf`)

| Variable | Description | Example / Default |
|----------|-------------|-------------------|
| `location` | Azure region for all resources | `"australiaeast"` |
| `subscription_id` | Azure subscription ID (optional) | `""` |
| `org_name` | Organization prefix for naming | `"philomath"` |
| `environment` | Environment name (dev / prod) | `"dev"` |
| `project_name` | Short project identifier | `"azure-cloud"` |
| `tags` | Tags to apply to resources | `{}` |

---

## 4. Outputs (`outputs.tf`)

Placeholder outputs: `location`, `environment`. Resource-specific outputs (e.g. resource group ID) are added as we add modules.

---

## 5. Folder Structure

- **Root:** `versions.tf`, `variables.tf`, `outputs.tf`, `main.tf` (provider + module calls).
- **modules/** – Reusable modules: `resource-group`, `network`, `databricks`, `key-vault`, `storage`.
- **environments/** – `dev/`, `prod/` for separate roots (used when we wire env-specific runs).

---

## 6. What You Can Run After This Step

From the project root:

```powershell
terraform init
terraform validate
```

- **init** – Downloads the Azure provider; no backend (local state).
- **validate** – Checks syntax and references.

We do **not** run `terraform plan` or `apply` until we add resources (e.g. resource group in Step 2).

---

## 7. Verification Checklist

- [ ] `versions.tf` has `required_version >= 1.0` and `azurerm ~> 4.0`.
- [ ] Provider block has no `location` (not supported by azurerm).
- [ ] Variables include `location`, `org_name`, `environment`, `tags`.
- [ ] Root `terraform init` and `terraform validate` succeed.
- [ ] Folders `modules/` and `environments/dev`, `environments/prod` exist.

Next: **Step 2 – Resource Group** (`02_resource_group.md`).
