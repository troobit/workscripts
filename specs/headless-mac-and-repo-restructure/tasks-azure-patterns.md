---
references:
    - prd.md
---
# Headless Mac setup and repo restructure — azure-patterns

## Workflow templates

- [ ] 1. Import 4 sanarte workflows as parameterised templates under azure/github-workflows/ <!-- id:v0eba5l -->
  - Sources: /Users/r/repos/sanarte/.github/workflows/{build-container,deploy-container-app,tf-deploy,update-kv-secret}.yml (read-only)
  - Replace sanarte identifiers (client/tenant/subscription IDs, rg-sanarte-prod, ca-sanarte-prod, ghcr.io/troobit/sanarte, hardcoded ARM env) with vars/secrets refs or marked placeholders
  - Normalise auth to repo vars across all four; fix or remove dead workflow_run trigger in update-kv-secret.yml
  - Each template parses via yq eval (or actionlint if installed)
  - NOT under this repo's own .github/workflows/
  - Stream: 1

## Container Apps patterns

- [ ] 2. Capture Container Apps deployment pattern under azure/container-apps/ <!-- id:v0eba5m -->
  - Generalised declarative app YAML from config/frontend.yml
  - deploy.sh local deploy pattern and setup_permissions.sh OIDC bootstrap, placeholders instead of sanarte values
  - Stream: 2

- [ ] 3. Import az_hostedrunner from /Users/r/Downloads/tf as azure/hosted-runner/ <!-- id:v0eba5n -->
  - Unchanged apart from short provenance header note
  - Dockerfile, compose file, requirements referenced from area README
  - Stream: 2

## Agent templates and docs

- [ ] 4. Import sanarte agent-customisation templates under azure/agent-templates/ <!-- id:v0eba5o -->
  - chatmodes, instructions, prompts with YAML front-matter intact
  - Stream: 3

- [ ] 5. Write azure/README.md <!-- id:v0eba5p -->
  - Layout; greenfield (primary) vs brownfield (secondary) application
  - OIDC/user-assigned-managed-identity auth model, why no client secrets
  - tfstate firewall open/close and deploy-by-immutable-digest patterns
  - lychee --offline passes
  - Blocked-by: v0eba5l (Import 4 sanarte workflows as parameterised templates under azure/github-workflows/), v0eba5m (Capture Container Apps deployment pattern under azure/container-apps/), v0eba5n (Import az_hostedrunner from /Users/r/Downloads/tf as azure/hosted-runner/), v0eba5o (Import sanarte agent-customisation templates under azure/agent-templates/)
