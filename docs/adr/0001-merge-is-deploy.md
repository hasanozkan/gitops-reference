# ADR-0001 — A merge to main is a deploy, and the deploy is a commit

**Status:** accepted

## Decision
Application CI publishes an image tagged `main-<unix-ts>-<sha>` on every
merge. Flux's image automation picks the newest by the timestamp and commits
the new tag into this repository; the cluster reconciles that commit.

## Why
- **Git is the audit log.** "What is running, since when, and why" is a
  `git log` on this repository — including the tag bumps.
- **Rollback is a revert**, reviewed like any change.
- **No cluster credentials in application CI.** Pipelines publish images;
  only the in-cluster controllers pull and apply (the pull model).
- **Sortable tags.** A timestamp prefix orders images without relying on
  registry push time; the SHA ties each image to a commit.

## Rejected
- **`latest` + restart** — nothing records what ran when; rollbacks are guesses.
- **CI runs `kubectl apply`** — every pipeline holds cluster-admin-shaped keys.
- **SemVer tags for every merge** — ceremony without information in a
  continuously deployed service; release versions still exist for clients.
