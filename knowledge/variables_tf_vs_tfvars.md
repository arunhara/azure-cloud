# Difference: `variables.tf` vs `*.tfvars` (Terraform)

In Terraform, you usually have two different kinds of files:

## `variables.tf` (variable definitions)
This file defines the *inputs* your Terraform configuration accepts.

Typical contents:

- `variable "name" { ... }` blocks
- type constraints (e.g. `type = string`)
- optional default values (`default = ...`)
- descriptions and documentation

What it means:

`variables.tf` tells Terraform:

- which variables exist
- what type they should be
- whether they have defaults
- what they are used for

But it does **not** provide the real values for your environment.

## `*.tfvars` (variable values)
These files provide *actual values* for the variables defined by `variables.tf`.

Typical contents:

- simple assignments like `location = "australiaeast"`
- maps/objects like:
  - `tags = { Environment = "dev" }`
- environment selectors like `environment = "dev"`

What it means:

`*.tfvars` tells Terraform:

- “When you see variable `location`, use this value”
- “When you see variable `tags`, use this map”

## How Terraform uses them together

When you run Terraform, Terraform loads:

1. `*.tf` files (definitions + configuration)
2. `*.tfvars` files you specify (values)

For example, to run dev with `environments/dev/dev.auto.tfvars`:

```powershell
cd environments\dev
terraform plan
```

After that, `var.location`, `var.org_name`, `var.tags`, etc. get their values from the auto-loaded `*.auto.tfvars` in that folder.

## Why you need both

- `variables.tf` makes your code reusable and validates input types.
- `*.tfvars` makes the same code configurable per environment (dev/prod) without editing the Terraform code.

## Quick mental model

- `variables.tf` = “What inputs do you support?”
- `*.tfvars` = “What values should those inputs have right now?”

