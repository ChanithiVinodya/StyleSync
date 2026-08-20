# Contributing Guide

## Branching Model: Trunk-Based

We use **trunk-based development**: `main` is always the single source of
truth, and everyone works in short-lived feature branches off `main`.

### Why this over GitFlow

- Our 4 components are naturally decoupled — each student mostly touches
  their own folder, so branches rarely conflict with each other.
- Deployment is continuous (from `main`), not release-cycle based, so a
  separate `develop` branch buys us nothing.
- Fewer branches = fewer places for conflicts to happen.

### Branch naming

```
feature/<component>-<short-description>
fix/<component>-<short-description>

# Examples
feature/designers-search-filter
feature/project-requests-photo-upload
fix/quotes-budget-validation-bug
```

### Workflow

1. `git pull origin main` before starting anything new
2. Create your branch: `git checkout -b feature/designers-search-filter`
3. Commit small, focused changes with clear messages (no "wip" or "fix stuff")
4. Push and open a PR into `main` **early** — don't sit on a branch for days
5. Keep branches short-lived: merge within 1–3 days where possible
6. At least one teammate reviews before merging (CODEOWNERS will
   auto-suggest the right reviewer based on the folders you touched)
7. Required CI checks (Backend CI, Frontend CI — see `docs/CI-CD.md`) must
   pass before merging
8. Delete your branch after merging

### Minimizing merge conflicts (project-specific rules)

- **Stay inside your module folder.** Each business component has its own
  folder in every app (`backend/.../Modules/<X>/`,
  `frontend-react/src/modules/<x>/`, `flutter-app/lib/modules/<x>/`,
  `ai-service/app/agents/<x>_agent.py`). Cross-module changes are rare and
  should be discussed first.
- **Shared files are edit-with-care zones**: `AppDbContext.cs`,
  `Program.cs`, `app/schemas.py`, `app/orchestrator.py`. Only add your own
  line(s) — never reformat or reorder someone else's.
- **EF Core migrations are sequential and easy to conflict.** Only one
  migration should be "in flight" (created but not yet merged) at a time.
  Check with the team before running `dotnet ef migrations add`.
- **Pull before you push, and pull often** — not just at the start of your
  branch.

## Commit Messages

Use a short imperative summary, optionally with more detail below:

```
Add designer search filtering by style and budget

- Adds query params to GET /api/designers
- Adds unit tests for the filter logic
```

## Git History Requirement

The assignment brief requires real, incremental commit history — **no
last-day dumps**. Commit as you go, even small WIP-but-working increments,
so your individual contribution is visible and explainable in the viva.
