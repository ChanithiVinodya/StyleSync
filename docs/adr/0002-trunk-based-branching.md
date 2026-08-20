# ADR 0002: Trunk-Based Branching Model

**Status:** Accepted
**Date:** 2026-08-18
**Deciders:** Team (all 4 members)

## Context

Four people need to push code into the same repo over 9 weeks with as
little merge friction as possible, while still keeping `main` deployable
and passing CI at all times (required for continuous demo-readiness and
for the "no last-day dumps" git history requirement).

## Decision

Use **trunk-based development**: `main` is the single long-lived branch.
Everyone branches off `main` for each piece of work
(`feature/<component>-<short-description>`), keeps branches short-lived
(merge within 1–3 days where possible), and merges back into `main` via a
reviewed PR that passes required CI checks.

## Alternatives Considered

- **GitFlow (`main` + `develop` + feature branches):** rejected. GitFlow's
  extra `develop` branch buys safety for projects with scheduled,
  versioned releases — we deploy continuously from `main` instead, so that
  benefit doesn't apply. It would add a second merge step
  (feature→develop→main) and therefore a second place conflicts can occur,
  for a 9-week student project where the team is small enough to coordinate
  directly.
- **Long-lived per-student branches** (one branch per person, merged only
  near the deadline): rejected outright — this is close to the "last-day
  dump" pattern the assignment brief explicitly penalizes, and it
  maximizes merge conflict size instead of minimizing it, since changes
  pile up before ever touching `main`.

## Consequences

- `main` must be protected: PR + review + required CI checks
  (`backend-ci`, `frontend-ci`) before merge (see `docs/CI-CD.md`).
- The team needs the discipline to actually keep branches short-lived —
  trunk-based only pays off if people don't let branches sit for a week.
- Combined with the modular folder structure from ADR 0001 (each student
  mostly touching their own module folder), most branches touch largely
  non-overlapping files, so conflicts should be rare and small when they
  do happen.
