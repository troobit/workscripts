#!/bin/bash
# Manually roll a Container App to the image declared in the checked-in config.
# Mirrors the deploy-container-app workflow template; adapted from sanarte's
# scripts/deploy.sh (plus its config/sed.sh image-override one-liner).
#
# Usage (from repo root, after az login):
#   RESOURCE_GROUP=rg-myapp-prod APP_NAME=ca-myapp-prod ./deploy.sh
#   IMAGE=ghcr.io/owner/app@sha256:... ./deploy.sh   # optionally pin an image first
set -euo pipefail

RESOURCE_GROUP="${RESOURCE_GROUP:-<RESOURCE_GROUP>}"
APP_NAME="${APP_NAME:-<CONTAINERAPP_NAME>}"
CONFIG_FILE="${CONFIG_FILE:-containerapp.yml}"

# optional: rewrite the container image in place before applying (sed.sh pattern)
if [ -n "${IMAGE:-}" ]; then
  yq e ".properties.template.containers[0].image = \"$IMAGE\"" "$CONFIG_FILE" -i
fi

az containerapp update \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NAME" \
  --yaml "$CONFIG_FILE"
