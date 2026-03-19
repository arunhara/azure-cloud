# Root Folder vs `environments/dev` and `environments/prod` (Terraform)

This repo uses Terraform in a common pattern:

1. `modules/` contains the reusable resource logic (this is the "real code" you maintain once).
2. `main.tf` exists in multiple places (`/` and `/environments/*`) as *entrypoints* (Terraform "root modules") that wire provider + variables + modules together.

Even if the `main.tf` files look almost identical, they exist for a practical reason: **Terraform treats each directory as its own root module and (by default) keeps its own state there**.

---

## What Terraform means by "root module"

When you run Terraform from a folder, Terraform loads all `*.tf` files in that folder and builds a configuration:

- Provider configuration (`provider "azurerm" { ... }`)
- Variable definitions (`variable ... { ... }`)
- Outputs (`output ... { ... }`)
- Module calls (`module "resource_group" { source = ... }`)

So `c:\Code\azure-cloud\` and `c:\Code\azure-cloud\environments\dev` are **two different root modules** because you run Terraform from two different directories.

---

## What the root folder files (`/main.tf`, `/variables.tf`, `/outputs.tf`, `/versions.tf`) are for

In this repo, the root folder is a *single, optional entrypoint*.

Key characteristics:

- `/main.tf` calls the shared module using a relative path like:
  - `source = "./modules/resource-group"`
- `/variables.tf` includes **defaults** (for example `location`, `org_name`, and `environment` have default values).

That means you can run Terraform from the root without providing `-var-file` and it will use the defaults.

Common uses:

- Quick experiments / learning
- A "single environment" workflow (only one state)
- A fallback if you want to deploy without the `environments/` structure

---

## What `environments/dev` and `environments/prod` are for

Each of these folders is also a Terraform root module, with the same shared module wired in:

- `environments/dev/main.tf` calls:
  - `source = "../../modules/resource-group"`
- `environments/prod/main.tf` calls the same shared module:
  - `source = "../../modules/resource-group"`

The important difference is the environment-specific inputs:

- `environments/dev/dev.auto.tfvars`
  - sets `environment = "dev"` (and dev-specific tags/values)
- `environments/prod/prod.auto.tfvars`
  - sets `environment = "prod"` (and prod-specific tags/values)

In addition, in this repo the environment `variables.tf` files do **not** provide those same defaults, so the intended workflow is:

- run dev by running `terraform plan` / `terraform apply` from `environments/dev`
- run prod by running `terraform plan` / `terraform apply` from `environments/prod`

---

## Why `main.tf` can look duplicated (but isn't "duplicate resource code")

Yes, you have multiple `main.tf` files, but they are thin entrypoints. The actual reusable resource definition is inside:

- `modules/resource-group/main.tf`

That module is written once and reused by both environments.

So the duplication is only in *wiring* (provider + module call + variable wiring). Your real infrastructure code is still centralized in `modules/`.

---

## Why you generally want separate `environments/`* roots

The big operational benefits are about *state and safety*:

- **Separate state per environment by directory**
  - Since you currently don't have a `backend*.tf` in this repo, Terraform typically stores local state in the directory you run it from.
  - Result: applying from `environments/dev` affects only dev state files; applying from `environments/prod` affects only prod state files.
- **Lower chance of applying the wrong environment**
  - You `cd` into the environment folder you want, and you pass the tfvars from that same folder.

If you keep only a root folder state, then both dev and prod would share the same state file unless you also set up separate backends/state/workspaces.

---

## "But how is it one code if I have to write two `main.tf` files?"

You are writing the "environment entrypoint" twice, but you are not writing the "infrastructure resources" twice.

Think of it like this:

- `modules/resource-group` = one implementation of "create a resource group"
- `environments/dev/main.tf` = one *configuration* that says "use the resource-group module with dev inputs"
- `environments/prod/main.tf` = one *configuration* that says "use the resource-group module with prod inputs"

Terraform "code reuse" is achieved by modules; environment roots are just configuration boundaries.

---

## Do you *need* both root and `environments/`?

No. You can choose one of these approaches:

### Option A: Keep `environments/`* (safer, clearer)

- Separate state automatically (by directory)
- Separate `dev.auto.tfvars` and `prod.auto.tfvars`
- You run Terraform separately per environment folder

### Option B: Use only the root folder (no env wrappers)

- Keep only `/main.tf` and put `dev.auto.tfvars` and `prod.auto.tfvars` in the root
- Run from `/` and pass `-var-file=dev.auto.tfvars` or `-var-file=prod.auto.tfvars`

However, without separate backend/state/workspaces, dev and prod would be using the same state file, which increases risk.

---

## Common Practice (Industry)

Most Terraform teams do **environment separation** for two reasons: **state isolation** and **operational safety**.

### 1) Usually: `environments/<env>/` with separate state

Common pattern:

- `modules/` holds the reusable infrastructure implementation (one place to maintain).
- `environments/dev/` and `environments/prod/` (or `staging/`) provide:
  - different variable values (`*.tfvars`)
  - separate state (often via separate `backend` configuration per folder)

Even if `main.tf` wiring is repetitive, the duplication is low-risk "configuration glue," while the real logic stays centralized in `modules/`.

### 2) Also common: root-only + `-var-file` (but state must be isolated)

Another accepted approach is:

- One root Terraform configuration (`/main.tf`, `/variables.tf`, `/outputs.tf`)
- Dev/prod selected using different `-var-file` values

This is only safe when you also ensure **separate state** for each environment, typically by:

- using different remote backends per environment (most common)
- or using Terraform workspaces (less common today than separate backends)

### 3) Workspaces vs separate folders

- **Workspaces** can work, but many teams prefer separate folders/backends because it is clearer and easier to control access and locking at the storage level.

---

## Recommendation for your repo

Given your current structure already uses `environments/dev` and `environments/prod`, the "common practice" choice is:

- Keep `modules/` as the single source of infrastructure code.
- Treat `environments/*` as environment-specific roots (wiring + state isolation).
- Eventually add a backend configuration per environment (so state separation is guaranteed even in CI/CD and not only by "what folder you run from").

## Summary

- Root (`/`) is an optional single-entrypoint workflow with variable defaults.
- `environments/dev` and `environments/prod` are environment-specific root modules intended to run separately with `dev.auto.tfvars` / `prod.auto.tfvars`.
- The important shared “one code” part lives in `modules/`; the env `main.tf` files are just wiring and boundaries for state and safety.

