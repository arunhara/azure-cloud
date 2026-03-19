# Terraform Getting Started – What We're Going to Create

This guide is for anyone new to Terraform. It explains the basics and then lists **exactly** what we will create, step by step. For each step, a **separate markdown file** will be created with full details so you can verify before we move on.

---

## Part 1: What Is Terraform?

**Terraform** is a tool that lets you define cloud (or other) infrastructure **as code**. Instead of clicking in the Azure Portal to create resources, you write configuration files. Terraform then creates or updates those resources for you in a repeatable way.

- **Write** – You describe what you want (e.g. "a resource group named rg-philomath-dev").
- **Plan** – Terraform shows you what it will add, change, or delete.
- **Apply** – You approve, and Terraform creates or updates the real resources in Azure.

---

## Part 2: Key Terraform Ideas (Simple Definitions)

| Term | Meaning |
|------|--------|
| **Provider** | Plugin that talks to a cloud (e.g. Azure). We use the **Azure (azurerm)** provider. |
| **Resource** | One piece of infrastructure (e.g. one Resource Group, one Storage Account). |
| **Module** | A reusable bundle of resources (e.g. "network module" = VNet + subnets). |
| **Variable** | Input you can change (e.g. environment name `dev` or `prod`) without editing code. |
| **Output** | Value Terraform prints after running (e.g. Databricks workspace URL). |
| **State** | A file where Terraform records what it created so it can update or destroy it later. |
| **Plan** | Command that shows "what would change" without changing anything. |
| **Apply** | Command that actually creates or updates resources in Azure. |

---

## Part 3: Our Project at a Glance

- **Organization:** Philomath  
- **Region:** Australia East (all resources)  
- **Environments:** `dev` and `prod` (separate folders, separate state)  
- **Goal:** Create Azure Databricks, Key Vault, and Storage Account per environment, with **no public access** to Databricks (private endpoints only).

---

## Part 4: Step-by-Step – What We Will Create (In Order)

We will create things in this order so that dependencies are ready first (e.g. Resource Group before anything else, VNet before private endpoints).

Each step has a **dedicated markdown file** (e.g. `01_project_foundation.md`) with full details. You can review that file and confirm before we write the Terraform code for the next step.

| Step | What we create | Terraform resource types | Doc to review |
|------|----------------|---------------------------|---------------|
| **1** | Project foundation | Terraform & provider config, folder structure, variables | `01_project_foundation.md` |
| **2** | Resource Group | One resource group per environment (dev, prod) | `02_resource_group.md` |
| **3** | Virtual Network & subnets | VNet, subnets (private endpoints, Databricks public/private), optional NSG | `03_network.md` |
| **4** | Databricks workspace | Databricks workspace (no public access) | `04_databricks_workspace.md` |
| **5** | Private endpoints & DNS for Databricks | Private endpoints (control + data), Private DNS zone, links, A records | `05_databricks_private_endpoints.md` |
| **6** | Key Vault | Key Vault, optional private endpoint + DNS | `06_key_vault.md` |
| **7** | Storage Account | Storage account, optional containers, optional private endpoint + DNS | `07_storage_account.md` |
| **8** | Identity & RBAC | Role assignments so Databricks can use Key Vault and Storage | `08_identity_rbac.md` |
| **9** | Environment wiring | Dev and prod `main.tf` + `.tfvars` so you can run `terraform apply` per env | `09_environment_wiring.md` |

---

## Part 5: How We'll Work Step by Step

1. **I create the next MD file** (e.g. `02_resource_group.md`) with:
   - What this resource is and why we need it
   - Exact resource names and settings (Philomath, Australia East)
   - The Terraform resource type(s) and main arguments
   - Any variables or outputs

2. **You review** that MD file and tell me if you want any changes.

3. **I add the Terraform code** (module or config) for that step and point you to the files.

4. We repeat for the next step until everything is in place.

---

## Part 6: Folder Structure We'll End Up With

```
azure-cloud/
├── knowledge/                    # All .md docs
│   ├── 00_TERRAFORM_GETTING_STARTED.md
│   ├── 01_project_foundation.md
│   ├── 02_resource_group.md
│   └── ...
├── versions.tf
├── variables.tf
├── outputs.tf
├── main.tf
├── modules/
│   ├── resource-group/
│   ├── network/
│   ├── databricks/
│   ├── key-vault/
│   └── storage/
└── environments/
    ├── dev/
    └── prod/
```

---

## Part 7: What You Need Before We Start

- **Azure subscription** and permissions to create resources (e.g. Contributor) in Australia East.
- **Terraform** installed locally (e.g. from [terraform.io](https://www.terraform.io/downloads)).
- **Azure CLI** installed and logged in (`az login`) so Terraform can use your credentials (or we can use a service principal later).

---

## Next: Step 1

The next file is **`01_project_foundation.md`**. It describes the project setup (versions, provider, variables, folder layout) so we can run `terraform init` and then add resources step by step.
