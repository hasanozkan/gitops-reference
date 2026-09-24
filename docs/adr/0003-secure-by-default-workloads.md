# ADR-0003 — Workloads are restricted by default

**Status:** accepted

## Decision
The `library` namespace enforces the `restricted` Pod Security Standard and
denies inbound traffic by default; each app opens only its own port. The
Deployment runs as a non-root user with a read-only root filesystem, no
privilege escalation and all capabilities dropped.

## Why
Hardening added later is hardening negotiated with every team that already
depends on the defaults. Starting restricted costs a few lines per workload
and makes every exception visible in review.
