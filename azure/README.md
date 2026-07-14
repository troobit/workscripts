# Azure deployment patterns

Reusable Azure Container Apps deployment patterns, GitHub workflow templates,
and agent-instruction templates, extracted from the sanarte project. Nothing
here runs in this repo — everything is a template to be copied into a target
repo and parameterised.

## Layout

```
azure/
├── github-workflows/          # workflow templates for OTHER repos' .github/workflows/
│   ├── build-container.yml    # build+push to GHCR, auto-deploy digest on main
│   ├── deploy-container-app.yml # manual deploy of any tag via declarative YAML
│   ├── tf-deploy.yml          # IaC plan/apply/destroy with OIDC + state firewall
│   └── update-kv-secret.yml   # refresh the GHCR pull secret in Key Vault
├── container-apps/
│   ├── containerapp.yml       # generalised declarative Container App config
│   ├── deploy.sh              # local deploy: az containerapp update --yaml
│   └── setup_permissions.sh   # one-time role grants for the managed identity
├── hosted-runner/
│   ├── Dockerfile             # Alpine CI runner/tooling image
│   ├── docker-compose.yml     # runner + envvars sidecar compose file
│   └── requirements.txt       # placeholder pip requirements for the image
└── agent-templates/
    ├── chatmodes/             # VS Code / Copilot chat modes (*.chatmode.md)
    ├── instructions/          # scoped coding instructions (*.instructions.md)
    └── prompts/               # reusable agent prompts (*.prompt.md)
```

## Using the patterns

### Greenfield (primary)

Everything here assumes infrastructure and configuration as code from day one.
For a new environment:

1. Provision the subscription-level plumbing with OpenTofu (see the roots under
   `../tofu/`): resource group, Container Apps environment, Key Vault, a
   user-assigned managed identity, and a storage account for state.
2. Federate the managed identity with the GitHub repo (an OIDC federated
   credential for the repo/environment) and run
   [`container-apps/setup_permissions.sh`](container-apps/setup_permissions.sh)
   to grant it the roles it needs.
3. Copy the four templates from [`github-workflows/`](github-workflows/) into
   the target repo's `.github/workflows/`, set the repo variables listed in
   each file's header, and replace the `<PLACEHOLDER>` values (workflow inputs
   and env defaults cannot read repo vars).
4. Copy [`container-apps/containerapp.yml`](container-apps/containerapp.yml)
   into the target repo (sanarte keeps it at `config/frontend.yml`, which is
   the path the deploy workflow expects) and fill in the placeholders.

### Brownfield (secondary)

For an existing environment the same files apply, but resource creation is
skipped: point the repo variables at the existing resource group, Container
App, and Key Vault, import existing resources into OpenTofu state where drift
management is wanted, and run `setup_permissions.sh` against the existing
tfstate storage account. The declarative `containerapp.yml` is safe to adopt
incrementally — `az containerapp update --yaml` only changes what the file
declares.

## Auth model: OIDC with a user-assigned managed identity

All four workflow templates authenticate the same way: `azure/login@v2` with a
**user-assigned managed identity** whose client ID is federated to the GitHub
repository via OpenID Connect. GitHub mints a short-lived ID token per job;
Entra ID exchanges it for an access token because the token's subject
(repo/environment) matches the identity's federated credential.

There are **no client secrets** anywhere in the chain: nothing to rotate,
nothing to leak from repo secrets, and a compromise of the repo cannot exfiltrate
a long-lived credential — the identity only works from the federated workflow
context. The same identity is reused by the build, deploy, IaC, and Key Vault
workflows, so its role assignments (granted once by `setup_permissions.sh`)
are the single place access is controlled.

Configuration is via repo **variables**, not secrets, across all four
templates (`AZ_CLIENT_ID`, `AZ_TENANT_ID`, `AZ_SUBSCRIPTION_ID`, plus
`AZ_RESOURCE_GROUP`, `AZ_CONTAINERAPP_NAME`, `AZ_KEYVAULT_NAME` where needed).
None of these IDs are secret — keeping them as vars makes runs debuggable
(values appear in logs) and keeps real secrets (`GHCR_PAT`) the exception.
The source's `update-kv-secret.yml` used `secrets.AZURE_*`; the template is
normalised to the same vars mechanism, and its `workflow_run` trigger — which
referenced a workflow name that no longer existed — now points at
"Infrastructure Deployment" (`tf-deploy.yml`).

The IaC toolchain in the templates uses OIDC end to end too: `ARM_USE_OIDC`
plus `ARM_OIDC_REQUEST_TOKEN`/`ARM_OIDC_REQUEST_URL` authenticate both the
azurerm provider and the state backend without any stored credential. Locally
the toolchain is OpenTofu (`tf` aliased to `tofu`); the workflow internals keep
their existing `hashicorp/setup-terraform` step and `terraform` commands as
imported, deliberately unchanged.

## Key patterns

### tfstate storage-firewall open/close (`tf-deploy.yml`)

The state storage account keeps its network firewall closed by default.
Each run of `tf-deploy.yml`:

1. Looks up the runner's public IP (`api.ipify.org`).
2. Reads the storage account and resource group out of the committed
   `environments/prod-backend.hcl` (single source of truth — the workflow never
   hardcodes them) and adds the IP with
   `az storage account network-rule add`, then waits ~10s for propagation.
3. Runs init/validate/plan/apply against the now-reachable backend.
4. Removes the IP again in an `if: always()` step, so the firewall closes even
   when the deploy fails.

State stays unreachable from the internet except for the minutes a run is in
flight, from exactly one IP, with no standing allow-list to maintain.

### Deploy by immutable digest (`build-container.yml`)

The auto-deploy job updates the Container App with
`--image <registry>/<image>@<digest>` — the digest output by the build step —
never a mutable tag. A `:latest` or `:main` tag does not change the image
string when new content is pushed, so Container Apps would consider the app
unchanged and keep the old revision running. A digest always differs when
content changes, so every build reliably rolls a new revision, and the running
revision is pinned to exactly the bytes that were built. Manual/ad-hoc deploys
of arbitrary tags go through `deploy-container-app.yml`, which rewrites the
image in the declarative YAML with `yq` and applies the whole file.

### Declarative app config (`container-apps/containerapp.yml`)

The Container App's runtime shape (ingress port, registry pull secret,
resources, scale-to-zero rules, env) lives in one committed YAML applied with
`az containerapp update --yaml`. Gotcha inherited from sanarte: the ingress
`targetPort` and any health probes must match the port the container actually
listens on — a mismatch leaves the revision "Healthy" but unreachable. The
registry block references a Container App secret (`cr-password`) holding a
GHCR pull token; `update-kv-secret.yml` keeps the Key Vault copy of that token
fresh. If that secret disappears, scale-from-zero cold starts fail to pull.

## hosted-runner

An Alpine-based tooling image for a self-hosted CI runner, imported verbatim
from `~/Downloads/tf/az_hostedrunner` (only provenance headers added):
[`Dockerfile`](hosted-runner/Dockerfile),
[`docker-compose.yml`](hosted-runner/docker-compose.yml), and
[`requirements.txt`](hosted-runner/requirements.txt). Note it is a snapshot,
not a finished build: the Dockerfile `COPY github /work/githubtoken` expects a
token file that is deliberately not committed, the pip install line is
commented out, and `requirements.txt` holds placeholder lines.

## agent-templates

VS Code / GitHub Copilot customisation files from sanarte, copied verbatim
with their YAML front-matter intact. Drop them into a target repo's `.github/`
(same subdirectory names) to reuse:

- **chatmodes/** — personas selectable in Copilot Chat: an Azure principal
  architect (Well-Architected Framework guidance), a systematic debugger, and
  a prompt engineer.
- **instructions/** — auto-applied coding rules scoped by `applyTo` glob:
  development-plan format, Python conventions, and IaC conventions
  (`terraform-use.md`, kept under its original name; it targets `*.tf` files).
  `markdown.instructions.md.ignore` was disabled in the source and is carried
  over still disabled — remove the `.ignore` suffix to activate it.
- **prompts/** — on-demand agent tasks: Azure cost optimisation (creates
  GitHub issues per finding), implementation-plan authoring, README
  generation, and chatmode discovery.
