# Why Use Environment Folders When Root Can Do Everything?

You can run everything from the **project root** and switch environments using variables (e.g. `-var="environment=prod"` or different `.tfvars` files). So why have separate folders like `environments/dev` and `environments/prod`?

**Using `dev.auto.tfvars` and `prod.auto.tfvars` in each environment folder is what makes this approach make sense:** each folder has its own variable values file, so you always know which environment you're targeting. You run Terraform from that folder and Terraform auto-loads the `.auto.tfvars` values—no risk of applying dev values in prod or the other way around.

---

## You Can Do It All from Root

- One root directory with `main.tf`, `variables.tf`, etc.
- Use `terraform plan -var="environment=prod"` or `terraform plan -var-file=prod.auto.tfvars` to target prod.
- Use `terraform plan -var-file=dev.auto.tfvars` (or defaults) for dev.
- Same code, different variable values = different resource names and settings (e.g. `rg-philomath-dev` vs `rg-philomath-prod`).

So the **environments** folders are a **choice** for safety and clarity, not a technical requirement.

---

## Why Use Separate Environment Roots?

### 1. Separate state per environment

- **Single root:** One `terraform.tfstate` (or one remote state) holds **all** environments. If you run `terraform apply` with the wrong `-var` or wrong `.tfvars`, you can change or destroy the wrong environment.
- **Separate roots:** `environments/dev` has its own state; `environments/prod` has its own. Apply from `environments/prod` only updates prod. Dev state is never touched. You reduce the risk of accidentally changing prod when you meant to change dev.

### 2. Smaller blast radius

- You **cd** into the environment you care about. `terraform plan` and `terraform apply` in that folder only affect that environment. No "I thought I was in dev but had prod tfvars" mistakes.

### 3. Different backends per environment

- Dev might use **local state** or a dev storage account; prod might use a **prod storage account** with stricter access and locking. Each root can have its own `backend` block.

### 4. Access control

- Easier to give people (or CI/CD) access only to **dev state** or only to **prod state** when state lives in different backends per folder.

---

## How to Use Environments and Run Dev vs Prod from Their Folders

Each environment has its **own Terraform root**. You run all commands from that folder; Terraform uses that folder’s state and variables.

### Folder layout

```
azure-cloud/
├── modules/                    # Shared modules (resource-group, network, etc.)
│   ├── resource-group/
│   └── ...
├── environments/
│   ├── dev/
│   │   ├── main.tf             # Provider + module calls for dev
│   │   ├── variables.tf        # Variable definitions
│   │   ├── dev.auto.tfvars    # Dev values (environment = "dev", etc.)
│   │   ├── versions.tf         # Terraform & provider versions (optional; can live in root)
│   │   └── outputs.tf          # Outputs
│   └── prod/
│       ├── main.tf             # Provider + module calls for prod
│       ├── variables.tf
│       ├── prod.auto.tfvars    # Prod values (environment = "prod", etc.)
│       └── outputs.tf
```

Each environment folder has:

- **`dev.auto.tfvars`** (in `environments/dev/`) or **`prod.auto.tfvars`** (in `environments/prod/`) – the variable values for that environment. This is what makes the separation clear: dev values live in dev, prod values in prod. You never share one tfvars file across envs.
- **`main.tf`**, **`variables.tf`**, **`versions.tf`**, **`outputs.tf`** – same structure in both; only the `.tfvars` content differs (`environment = "dev"` vs `"prod"`, and any env-specific tags or SKUs).

Each environment’s `main.tf` calls the shared modules with a **relative path**, e.g. `source = "../../modules/resource-group"`. When you run `terraform plan` from `environments/dev`, Terraform uses that folder’s state and the auto-loaded **dev.auto.tfvars** values; when you run from `environments/prod` it uses **prod.auto.tfvars**. So the `.auto.tfvars` file in each folder is the clear, single source of “which env am I in?”

### Running Dev

1. Open a terminal and go to the dev folder:
   ```powershell
   cd c:\Code\azure-cloud\environments\dev
   ```
2. First time (or after changing providers/backend):
   ```powershell
   terraform init
   ```
3. Plan (see what would change):
   ```powershell
   terraform plan
   ```
 Because Terraform auto-loads `*.auto.tfvars`, you can just run:
   ```powershell
   terraform plan
   ```
4. Apply (create or update dev resources):
   ```powershell
   terraform apply
   ```
   Type `yes` when prompted.

State is stored in **that folder** (e.g. `environments/dev/terraform.tfstate`) or in the backend configured in that folder. Only **dev** resources are in that state.

### Running Prod

1. Open a terminal and go to the prod folder:
   ```powershell
   cd c:\Code\azure-cloud\environments\prod
   ```
2. First time (or after changing providers/backend):
   ```powershell
   terraform init
   ```
3. Plan:
   ```powershell
   terraform plan
   ```
4. Apply:
   ```powershell
   terraform apply
   ```
   Type `yes` when prompted.

State is stored in **that folder** (e.g. `environments/prod/terraform.tfstate`) or in the backend for prod. Only **prod** resources are in that state.

### Summary of the workflow

| Step        | Dev folder                          | Prod folder                          |
|------------|--------------------------------------|--------------------------------------|
| **cd**     | `cd environments\dev`               | `cd environments\prod`               |
| **init**   | `terraform init`                    | `terraform init`                     |
| **plan**   | `terraform plan`                   | `terraform plan`                    |
| **apply**  | `terraform apply`                  | `terraform apply`                   |

You always run from the environment folder you want to change. No shared state between dev and prod—so applying in `environments/dev` cannot change prod, and vice versa.

---

## Why `dev.auto.tfvars` and `prod.auto.tfvars` in Each Folder Makes Sense

- **One tfvars per environment** – `environments/dev/dev.auto.tfvars` and `environments/prod/prod.auto.tfvars` hold that environment’s values. You don’t pass the wrong file because you’re already in the right folder.
- **Same variable names, different values** – Both files set `environment`, `location`, `org_name`, `tags`, etc. Dev might have `environment = "dev"` and lighter tags; prod has `environment = "prod"` and stricter tags. Same code, different inputs.
- **Commands stay simple** – From `environments/dev` you run `terraform plan`; from `environments/prod` you run `terraform plan`. The folder + tfvars name make it obvious which env you’re affecting.

So the environment folders plus **dev.auto.tfvars** and **prod.auto.tfvars** are what make the setup sensible: separate state, clear variable files, and no cross-environment mistakes.

---

## Summary

| Approach | Pros | Cons |
|--------|------|------|
| **Single root** + variables | Simple; one place to edit. | One state for all envs; wrong `-var`/tfvars can touch the wrong env. |
| **Environment folders** + **dev.auto.tfvars** / **prod.auto.tfvars** | Separate state per env; one tfvars per folder; clear which env you're changing; different backends possible. | Slightly more structure (one root per env). |

Environment folders with **dev.auto.tfvars** and **prod.auto.tfvars** give you separate state, a clear “which env” signal, and the option to use different backends and access control per environment.
