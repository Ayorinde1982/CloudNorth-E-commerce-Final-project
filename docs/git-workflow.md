# Git Workflow (CloudNorth)

Branches:
- main: stable, production-ready. Protected.
- dev: integration branch; auto-deploy to staging later.
- feature/*: short-lived branches off dev.

Flow:
1) Create feature branch from dev.
2) Commit small, focused changes.
3) Open PR to dev; require review.
4) Merge to dev after CI passes.
5) Periodically open PR from dev -> main; production deploy follows approvals.

```mermaid
gitGraph
   commit id: "init"
   branch dev
   commit id: "infra phase1"
   branch feature/ci-foundation
   checkout feature/ci-foundation
   commit id: "templates"
   checkout dev
   merge feature/ci-foundation
   checkout main
   merge dev tag: "v0.1.0"
