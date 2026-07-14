---
description: 'Terraform guidelines'
applyTo: '**/*.tf'
---

# Terraform Coding Conventions

## Terraform Instructions

- When running terraform in the CLI - use the aliased command `tf` instead of `terraform` for brevity.
- Use `tf plan -var-file=environments/prod.tfvars` and `tf apply -var-file=environments/prod.tfvars` to ensure the correct environment variables are used.
- Use `-auto-approve` flag with `tf apply` to skip interactive approval in automated scripts.
- Use `-refresh=true` flag with `tf plan` to ensure the state is up-to-date before planning changes.