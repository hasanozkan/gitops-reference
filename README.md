# GitOps reference

[![ci](https://github.com/hasanozkan/gitops-reference/actions/workflows/ci.yml/badge.svg)](https://github.com/hasanozkan/gitops-reference/actions/workflows/ci.yml)
![flux](https://img.shields.io/badge/Flux-v2-5468FF) ![license](https://img.shields.io/badge/license-MIT-green)

A small, complete GitOps setup you can run on a laptop in one command: Flux
reconciles a service from Git, in dependency order, onto restricted
workloads — and **a merge to `main` in the application repository becomes a
deploy through a commit here**.

The service is the library API from
[spec-driven-ddd-sample](https://github.com/hasanozkan/spec-driven-ddd-sample),
published to `ghcr.io/hasanozkan/library-sample` on every merge.

```mermaid
flowchart LR
  subgraph app["application repo"]
    M[merge to main] --> CI[CI: build + push<br/>main-&lt;ts&gt;-&lt;sha&gt;]
  end
  CI --> REG[(ghcr.io)]
  subgraph cluster["cluster (Flux)"]
    IR[ImageRepository] --> IP[ImagePolicy<br/>newest by ts]
    IP --> IUA[ImageUpdateAutomation]
    GR[GitRepository] --> K1[Kustomization<br/>infrastructure] --> K2[Kustomization<br/>apps]
  end
  REG --> IR
  IUA -- "commit: new tag" --> G[(this repo)]
  G --> GR
  K2 --> D[Deployment library]
```

## Run it

Needs Docker, [k3d](https://k3d.io), the [flux](https://fluxcd.io/flux/installation/) CLI and kubectl.

```sh
make up        # k3d cluster + Flux, reconciled from this repo's main branch
make smoke     # borrow a book through the deployed API, check the catalog follows
make status    # flux get all -A
kubectl -n library scale deploy/library --replicas=0   # drift...
flux reconcile kustomization apps                      # ...corrected from Git
make down
```

`make up` deploys and resolves the image policy (`flux get images policy
library` shows the newest tag) but writes nothing back. To see the full
loop, fork this repository and run
`GITOPS_REPO=https://github.com/<you>/gitops-reference GITHUB_TOKEN=<token with contents:write> make up`:
new images now arrive as `chore(image): … -> …` commits in your fork.

## Layout

| Path | What it holds |
|---|---|
| [`clusters/local/sync.yaml`](clusters/local/sync.yaml) | The entry point: Git source → `infrastructure` → `apps` |
| [`clusters/local/image-policy.yaml`](clusters/local/image-policy.yaml) | Registry scan + "newest `main-<ts>-<sha>`" policy |
| [`clusters/local/image-update.yaml`](clusters/local/image-update.yaml) | Write-back: new tags committed to Git |
| [`infrastructure/`](infrastructure) | Namespace with `restricted` Pod Security, default-deny network policy |
| [`apps/base/library/`](apps/base/library) | Hardened Deployment (with the `$imagepolicy` setter) and Service |
| [`apps/local/`](apps/local), [`apps/production/`](apps/production) | Overlays: local ingress · production replicas, spread and disruption budget |

## What CI proves

| Job | Proves |
|---|---|
| `validate` | Every overlay and the cluster entry point render, and pass strict schema validation (Kubernetes + Flux CRDs) |
| `e2e` | On a fresh kind cluster, Flux reconciles **this commit**; `infrastructure` then `apps` become Ready; the service passes the smoke test through its Service; the image policy resolves a tag from the registry |

## Decisions

- [ADR-0001 — A merge to main is a deploy, and the deploy is a commit](docs/adr/0001-merge-is-deploy.md)
- [ADR-0002 — Platform before apps, and Ready means serving](docs/adr/0002-ordered-reconciliation.md)
- [ADR-0003 — Workloads are restricted by default](docs/adr/0003-secure-by-default-workloads.md)

## Deliberate simplifications

One cluster, one app, no database. In a production setup the same shape
grows: secrets encrypted in Git (SOPS + age) or pulled from a secret store,
a migration Job gated before each rollout, alerting on failed reconciliations,
and more environments as more `clusters/<name>` entry points over the same
`apps/` overlays.

---

Part of a set: [spec-driven-ddd-sample](https://github.com/hasanozkan/spec-driven-ddd-sample)
· [llm-tool-calling-assistant](https://github.com/hasanozkan/llm-tool-calling-assistant)
· [ai-native-engineering](https://github.com/hasanozkan/ai-native-engineering).
By [Hasan Özkan](https://github.com/hasanozkan) · [LinkedIn](https://www.linkedin.com/in/hasanozkan/)
