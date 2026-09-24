# ADR-0004 — Observability as code, held to the services' telemetry contracts

**Status:** accepted

## Decision
- **Apps declare how they are watched.** Each app carries a `ServiceMonitor`
  and a `PrometheusRule` next to its Deployment. Only the Prometheus Operator
  CRDs are platform (infrastructure/), so every cluster — CI included — accepts
  them, whether or not a full stack runs there.
- **The stack is a separate Kustomization** (observability/): Prometheus +
  Alertmanager + Grafana, Loki with Alloy for logs, Tempo for traces. It can
  take minutes to become Ready without holding the apps back, and CI leaves it
  out.
- **Dashboards are JSON in Git**, loaded by Grafana's sidecar through a label.
- **Queries are checked against contracts.** Every series and label a
  dashboard or an alert uses must exist in the library's `specs/telemetry.yaml`
  or the assistant's `observability/telemetry.yaml`; a rename in a service
  breaks this repository's build instead of silently emptying a panel.
- **Alerts are tested where they are written.** The assistant's rules are
  unit-tested in its repository and mirrored here by a generator whose output
  CI compares; the library's rules are tested here. Both with `promtool`.

## Rejected
- **Dashboards clicked together in the UI** — unreviewed, unversioned, and lost
  with the Grafana volume.
- **Checking dashboards against a live Prometheus in CI** — slow and flaky; the
  contracts already say what exists.
