# ADR 0001: Monorepo with a Modular Monolith Backend

**Status:** Accepted
**Date:** 2026-08-18
**Deciders:** Team (all 4 members)

## Context

We are 4 students, each owning one business component, building a single
integrated system (React + Flutter + ASP.NET Core + PostgreSQL + Agentic
AI) over 9 weeks. We need a repo structure and backend architecture that
minimizes merge conflicts while still meeting the assignment's requirement
that React and Flutter share the same API, identity, and business rules.

## Decision

- **One monorepo** containing `backend/`, `frontend-react/`,
  `flutter-app/`, and `ai-service/`, rather than 4 separate repos.
- **Backend is a single ASP.NET Core Web API project structured as a
  modular monolith** — one folder per business component under
  `Modules/`, each with its own Controllers/Models/Services/Data, rather
  than 4 separate microservices or 4 separate class-library projects.
- **EF Core entity configuration is auto-discovered** via
  `ApplyConfigurationsFromAssembly`, so adding a new entity doesn't
  require editing the shared `AppDbContext.cs` beyond one `DbSet<T>` line.

## Alternatives Considered

- **Multi-repo (one repo per app):** rejected — coordinating 4 repos for
  a single demo, with cross-repo API contract changes, adds overhead with
  no real benefit for a team this size and timeline. A single PR that
  spans backend + frontend for one feature is also easier to review.
- **Microservices per component:** rejected — real service-to-service
  networking, auth propagation, and deployment across 4 independent
  services is significantly more infrastructure than a 9-week student
  project needs, and works against the requirement that both clients talk
  to one single backend as the source of truth.
- **4 separate class-library projects (one per module) instead of
  folders:** considered, but rejected for now — it adds project-reference
  and build-config overhead without a strong payoff at our scale. Folder
  separation gives us most of the conflict-reduction benefit with less
  ceremony. This could be revisited if module boundaries need to be
  enforced more strictly later.

## Consequences

- Each student's work stays physically separated by folder in every app,
  which keeps merge conflicts low without needing GitFlow-style branch
  overhead (see ADR 0002 on trunk-based branching).
- `AppDbContext.cs` and `Program.cs` remain small, shared, low-conflict
  files as long as everyone follows the "add one line, don't reformat"
  convention documented in `docs/CONTRIBUTING.md`.
- If a component's logic grows large enough to genuinely need independent
  deployment or scaling, extracting it into its own service later is
  possible without a full rewrite, since business logic is already
  folder-isolated.
