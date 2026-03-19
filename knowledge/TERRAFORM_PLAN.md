# Terraform Azure Infrastructure Plan

## Overview

This document describes the planned Terraform project for provisioning Azure resources with **dev** and **prod** environments. Databricks workspaces will be accessible only via private endpoints (no public network access).

- **Organization:** Philomath  
- **Region:** All resources will be deployed in **Australia East**.

---

## 1. Target Resources

| Resource | Purpose |
|----------|---------|
| **Azure Databricks** | Analytics workspace; will be private-endpoint only (no public access). |
| **Azure Key Vault** | Secrets, keys, and certificates; can optionally use private endpoint. |
| **Storage Account** | Data lake / blob storage; can optionally use private endpoint. |

---

## 2. Environments

- **dev** – Development (smaller SKUs, optional cost-saving settings).
- **prod** – Production (appropriate SKUs, stricter naming/labels, backup/retention if needed).

Separation via **environment folders** (`environments/dev`, `environments/prod`) and variable files (`dev.auto.tfvars`, `prod.auto.tfvars`).

---

## 3. Private Access for Databricks

1. **Virtual Network (VNet)** – Subnets for private endpoints and Databricks (public/private node subnets).
2. **Private Endpoints** – Databricks control plane and data plane; workspace with `public_network_access_enabled = false`.
3. **DNS** – Private DNS zones so Databricks hostnames resolve to private IPs.
4. **Optional** – Private endpoints for Key Vault and Storage (recommended for prod).

---

## 4. Proposed Project Structure

```
azure-cloud/
├── knowledge/              # All .md documentation
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

## 5. List of All Azure Resources (Per Environment)

All resources use **Philomath** and **Australia East**. Counts are per environment; **total** = dev + prod.

| Category | Resources (examples) | Per env | Total |
|----------|----------------------|---------|--------|
| Foundation | Resource Group | 1 | 2 |
| Networking | VNet, subnets (private endpoints, Databricks public/private), NSG | 4–6 | 8–12 |
| Databricks | Workspace | 1 | 2 |
| Private Link (Databricks) | Private endpoints (control + data), Private DNS zone, links, A records | 6 | 12 |
| Key Vault | Key Vault, private endpoint, Private DNS, link, A record | 5 | 10 |
| Storage | Storage account, containers, private endpoint, Private DNS (blob + dfs), links, A records | 8–10 | 16–20 |
| RBAC | Role assignments (Databricks → Key Vault, Storage) | 2 | 4 |

**Summary:** ~29–33 resources per environment; ~58–66 total.

---

## 6. Implementation Details (High Level)

- **Resource Group** – One per env, e.g. `rg-philomath-dev`, `rg-philomath-prod`.
- **Network** – VNet, subnets for private endpoints and Databricks; NSGs as needed.
- **Databricks** – Workspace with no public access; secure cluster connectivity; private endpoints + Private DNS.
- **Key Vault** – Per env; optional private endpoint + DNS.
- **Storage** – Per env; optional private endpoint + DNS (blob + dfs).
- **Identity** – Databricks managed identity with roles on Key Vault and Storage.

---

## 7. Dependencies

1. Resource Group → all resources.
2. VNet & Subnets → Private Endpoints, Databricks.
3. Databricks workspace → Databricks private endpoints.
4. Key Vault & Storage → optional private endpoints depend on VNet.

---

## 8. Terraform Backend in Practice

The state backend (e.g. Azure Storage) is usually **bootstrapped separately**:

- **Pattern A – Out-of-band:** Platform team creates storage account + container; Terraform references it in `backend` block.
- **Pattern B – Bootstrap stack:** Small Terraform config (local state) creates backend resources once; main project uses that backend.
- **Pattern C – Local first:** Start with local state; migrate to remote backend later with `terraform init -migrate-state`.

This project does **not** create the backend storage account in the same state.

---

## 9. What You Need to Provide

- **Azure subscription** and (if using remote backend) backend details.
- **Organization & region** (fixed): **Philomath**, **Australia East**.
- **Tags** (e.g. Environment, Project, CostCenter).
- Whether Key Vault and Storage should be private-endpoint only in prod.

---

## 10. Next Steps

1. Create folder structure and base files (Step 1 – done).
2. Implement modules in order: resource-group → network → databricks (+ private endpoints) → key-vault → storage.
3. Add identity/RBAC (Databricks → Key Vault, Storage).
4. Wire `environments/dev` and `environments/prod` with their own `main.tf` and `.tfvars` (see `knowledge/WHY_ENVIRONMENTS.md`).
