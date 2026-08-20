# Setup Instructions: From Zip to GitHub

Follow this once, as a team, to get the repo live on GitHub with working
CI before anyone starts building features.

## 1. Create the GitHub repository

1. On GitHub, create a **new empty repository** (no README, no
   `.gitignore`, no license — this scaffold already has those).
2. Add all 4 team members as collaborators (or create a GitHub
   Organization/Team for the group).

## 2. Push this scaffold as the initial commit

```bash
# Unzip, then cd into the extracted folder
cd stylesync-skeleton

git init
git add .
git commit -m "Initial project scaffold: backend, React, Flutter, AI service, CI/CD"
git branch -M main
git remote add origin <your-repo-url>
git push -u origin main
```

## 3. Set up branch protection (do this before anyone opens a PR)

GitHub repo → **Settings → Branches → Add branch protection rule**,
branch name pattern `main`:

- ✅ Require a pull request before merging (require 1 approval)
- ✅ Require status checks to pass before merging
  - After your first PR triggers CI once, come back here and select:
    `Backend CI / Build & Test (.NET)` and
    `Frontend CI / Lint, Build & Test (React)`
- ✅ Do not allow bypassing the above settings

> You can only select status checks that have run at least once, so do
> steps 4–6 below first, open one throwaway PR to trigger the workflows,
> *then* come back and lock these in.

## 4. Update CODEOWNERS with real usernames

Edit `.github/CODEOWNERS` and replace every `@studentN-github-username`
placeholder with your teammates' actual GitHub usernames. Commit this on
a branch and open a PR (see step 6) rather than pushing straight to
`main`, so you get used to the workflow immediately.

## 5. Each member: local setup

Run the prereqs check first:

- **macOS/Linux/Git Bash:** `./scripts/check-prereqs.sh`
- **Windows (PowerShell):** `.\scripts\check-prereqs.ps1`
  (if it's blocked, run once: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`)

Then follow, in order:

1. `docs/setup/backend.md` — start Postgres via Docker, run the API
2. `docs/setup/frontend-react.md` — run the React app
3. `docs/setup/flutter.md` — generate native folders, run the mobile app
4. `docs/setup/ai-service.md` — run the Python AI service

## 6. Make your first branch + PR (validates the whole pipeline)

```bash
git checkout -b feature/setup-verify-ci
# make a trivial change, e.g. add your name to README.md under a "Team" section
git add .
git commit -m "Verify CI pipeline on a real PR"
git push -u origin feature/setup-verify-ci
```

Open a PR on GitHub into `main`. Confirm:

- ✅ `Backend CI` and `Frontend CI` run and pass
- ✅ `Flutter CI (non-blocking)` and `AI Service CI (non-blocking)` run
  (they may show a warning icon even on success/failure — that's expected,
  they're advisory)
- ✅ CODEOWNERS suggested the right reviewer

Merge it. Then go back and finish step 3 (lock in the required status
checks now that they've run once).

## 7. Ongoing workflow

From here on, follow `docs/CONTRIBUTING.md` for branching and PR
conventions. Each student works inside their own module folder
(`docs/architecture.md` has the full folder map), opens small PRs
frequently, and keeps their AI usage log (`docs/ai-usage-log-template.md`)
updated weekly — not retroactively in week 9.
