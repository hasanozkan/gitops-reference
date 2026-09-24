#!/usr/bin/env bash
# Render every entry point and validate it against Kubernetes and Flux
# schemas. Catches what `kubectl apply --dry-run=client` would miss offline:
# a typo'd field, a wrong apiVersion, a CRD object with an invalid spec.
set -euo pipefail
cd "$(dirname "$0")/.."
CRDS='https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'
validate() { kubeconform -strict -summary -schema-location default -schema-location "$CRDS" "$@"; }
for overlay in infrastructure apps/local apps/production; do
  echo "== $overlay"
  kustomize build "$overlay" | validate -
done
echo "== clusters/local"
validate clusters/local
