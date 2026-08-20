# ADR 0007: Cloud Deployment Platform

**Status:** Accepted (subject to revision if free-tier limits or setup issues appear)
**Date:** 2026-08-20
**Deciders:** Team (all 4 members)

## Context

The assignment requires the ASP.NET Core API, PostgreSQL, and React app to
be deployed live with working URLs (health endpoint, Swagger URL, and a
live React URL), and requires that this be achievable using
institution-provided or no-cost services — no paid subscriptions required
(§14). The Flutter app is submitted as source code + a runnable APK
rather than deployed to an app store. The Agentic AI service may be
deployed or run locally, as long as setup, model/framework requirements,
and startup order are fully documented (§14).

We need one platform (or a small, clearly justified combination) that can
host all three required live pieces without requiring a credit card or
paid plan, and that the whole team can access and redeploy to
independently.

## Decision

We will deploy on **Microsoft Azure**, using free-tier services available
through **Azure for Students** (no credit card required, avoids the
"paid subscription" problem entirely):

| Component | Azure service | Notes |
|---|---|---|
| ASP.NET Core API | **Azure App Service** (Free F1 tier) | Deploys directly from our GitHub repo; gives us the health + Swagger URLs the spec requires |
| PostgreSQL | **Azure Database for PostgreSQL – Flexible Server** (Burstable/free-eligible tier) | Matches our existing EF Core + Npgsql setup with no code changes; migrations run the same way as local dev |
| React app | **Azure Static Web Apps** (Free tier) | Built-in GitHub Actions deployment workflow, free custom preview URLs per PR which is useful for demoing incremental progress |
| Agentic AI service (Python/LangGraph) | **Run locally for development; Azure Container Apps (Consumption free grant) if we have time/credit remaining for a live deployment** | The spec explicitly allows "deploy or run locally as appropriate" for this component — we're treating a live deployment as a stretch goal, not a hard requirement, to protect our free-tier credit for the three components that *must* be live |
| Flutter app | Not deployed — submitted as source + built APK | Matches the spec's requirement exactly; no hosting decision needed here |

We keep local-dev instructions (`docs/setup/*.md`) fully working
regardless of deployment status, so the whole system can always be
demonstrated locally as a fallback if a live service has an outage near
submission — the spec explicitly allows reporting a confirmed outage with
evidence, but a working local fallback is safer than relying on that.

## Alternatives Considered

- **Render** — genuinely strong free tier for small APIs and static sites,
  simple to set up. Considered seriously, but Azure for Students gives the
  team Azure credit at no cost anyway (most SLIIT students already have
  institutional access), and consolidating everything under one account
  the whole team can access is simpler than juggling multiple platform
  logins across 4 people.
- **Railway** — good developer experience, but its free tier has become
  more limited/trial-based over time, which risked running out mid-project
  rather than lasting the full 9 weeks — a real risk for a graded deadline.
- **AWS Free Tier** — powerful but has a steeper setup curve (IAM, VPC
  configuration, etc.) than the team's timeline comfortably supports for a
  9-week assignment where deployment is one requirement among many, not
  the main focus.
- **Split-platform approach** (e.g. Vercel for React + Supabase for
  Postgres + Render for the API) — technically viable, but rejected in
  favour of one platform to reduce the number of separate accounts,
  billing/credential surfaces, and things that can independently break
  right before a demo.

## Consequences

- The whole team needs Azure for Students access set up early (Week 1–2),
  not left until deployment week — this should go on the project timeline.
- Connection strings and secrets (JWT signing key, DB credentials, any
  LLM API key) must be stored in Azure App Service's Configuration
  (environment variables), never committed to the repo — this is already
  consistent with our `.env.example` / `appsettings.json` placeholder
  pattern.
- If Azure for Students credit or free-tier limits become a problem before
  submission, the fallback documented here is Render (closest free-tier
  equivalent, minimal migration effort since both support standard
  Docker/GitHub-based deploys) — if we switch, this ADR should be updated
  and marked Superseded rather than silently changing platforms.
- Because the Flutter app isn't deployed anywhere, evaluators will only
  ever run it via the submitted APK — the README must include clear
  install instructions for that (already covered in `docs/setup/flutter.md`).
