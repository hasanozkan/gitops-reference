#!/usr/bin/env bash
# A local cluster reconciled from this repository's main branch.
#   make up                       read-only: Flux deploys, image policy resolves
#   GITHUB_TOKEN=... make up      + image automation commits new tags back
#                                  (use a fork: set GITOPS_REPO to its URL)
set -euo pipefail
cd "$(dirname "$0")/.."
CLUSTER=gitops-reference
REPO="${GITOPS_REPO:-https://github.com/hasanozkan/gitops-reference}"

k3d cluster list "$CLUSTER" >/dev/null 2>&1 || \
  k3d cluster create "$CLUSTER" --agents 1 --port "8080:80@loadbalancer" --wait
kubectl config use-context "k3d-$CLUSTER" >/dev/null

flux install --components-extra=image-reflector-controller,image-automation-controller

sed "s#https://github.com/hasanozkan/gitops-reference#$REPO#" clusters/local/sync.yaml | kubectl apply -f -
kubectl apply -f clusters/local/image-policy.yaml   # scan + policy: what WOULD deploy
if [ -n "${GITHUB_TOKEN:-}" ]; then
  flux create secret git gitops-push --url="$REPO" --username=git --password="$GITHUB_TOKEN"
  kubectl -n flux-system patch gitrepository gitops-reference --type merge \
    -p '{"spec":{"secretRef":{"name":"gitops-push"}}}'
  kubectl apply -f clusters/local/image-update.yaml  # commit new tags back to Git
fi

flux reconcile source git gitops-reference
kubectl -n flux-system wait kustomization/infrastructure kustomization/apps --for=condition=Ready --timeout=5m
flux get kustomizations
flux get images policy library || true
