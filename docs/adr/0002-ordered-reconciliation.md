# ADR-0002 — Platform before apps, and Ready means serving

**Status:** accepted

## Decision
Two Flux Kustomizations: `infrastructure` (namespaces, pod security,
network policy) and `apps`, which `dependsOn` it. Both use `wait: true`, so
Flux reports Ready only when the objects are healthy — for a Deployment, when
its pods pass readiness probes.

## Why
Without ordering, an app can land in a namespace that does not exist yet and
fail on the first reconcile, "fixing itself" on the next — noise that hides
real failures. Without `wait`, "Ready" means "the YAML was accepted", and a
crash-looping release looks green.
