# CI/CD Pipelines

Four independent GitHub Actions workflows live in `.github/workflows/`.
Each only runs when files in its own app folder change (via `paths:`
filters), so touching the React app doesn't trigger the Flutter pipeline,
etc.

| Workflow | Triggers on changes to | Status | What it checks |
|---|---|---|---|
| `backend-ci.yml` | `backend/**` | **Required** | `dotnet restore`, `dotnet build` (Release), `dotnet test` |
| `frontend-ci.yml` | `frontend-react/**` | **Required** | `npm ci`, `npm run lint`, `npm run test`, `npm run build` |
| `flutter-ci.yml` | `flutter-app/**` | Advisory (`continue-on-error: true`) | `flutter analyze`, `flutter test` |
| `ai-service-ci.yml` | `ai-service/**` | Advisory (`continue-on-error: true`) | `ruff check`, `pytest` |

## Why Backend + React are required but Flutter/AI service aren't (yet)

The assignment brief's minimum CI requirement is a workflow that builds
and tests the backend on every push/PR — that's our floor. React is cheap
and fast to lint/build/test in CI, and a broken React build would be
embarrassing to discover mid-demo, so it's also gated.

Flutter and the Python AI service are marked **advisory** for now because:

- Flutter's CI (SDK download, native build steps) is slower and more prone
  to transient failures on free-tier runners than the backend/React jobs.
  A flaky Flutter job blocking everyone's merges would hurt more than help.
- The AI service's agent implementations are expected to change shape a
  lot early on (swapping stub logic for real LLM calls). Gating merges on
  it too early would slow the team down for no real safety benefit yet.

**Once your Flutter widget tests and agent tests stabilize (recommend:
after Week 4–5), remove `continue-on-error: true` from those two
workflows** and add them as required status checks in branch protection
(see below) — this is a good ADR candidate.

## Branch Protection (set this up once, in GitHub repo settings)

`Settings → Branches → Add branch protection rule` for `main`:

- ✅ Require a pull request before merging
- ✅ Require approvals (at least 1)
- ✅ Require status checks to pass before merging → select:
  - `Backend CI / Build & Test (.NET)`
  - `Frontend CI / Lint, Build & Test (React)`
- ✅ Do not allow bypassing the above settings (even for admins, if your
  GitHub plan supports it)

Don't add the Flutter/AI service jobs as *required* checks until you've
removed their `continue-on-error` flag, or you'll block merges on jobs
that are allowed to fail.

## Deployment

CI here only builds/tests — it does not deploy. Add deployment steps
(e.g. to Render/Railway/Azure free tier for the API, Vercel/Netlify for
React) once you've chosen a host; document the choice as an ADR.
