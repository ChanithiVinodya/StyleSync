# StyleSync

### Interior Design & Room Makeover Marketplace

SE3090 – Assignment 1: Integrated Full-Stack and Agentic AI Application

## Architecture

Monorepo containing four apps that together form one integrated system:

```
backend/           ASP.NET Core Web API + PostgreSQL (EF Core) - the ONLY
                    backend both clients talk to
frontend-react/    React web app - staff/admin/designer side
flutter-app/       Flutter mobile app - client side
ai-service/        Python (FastAPI) Agentic AI service - internal only,
                    called exclusively by the backend
```

Each of the 4 business components (Designers, Project Requests, Quotes &
Contracts, Project Execution) has a matching folder inside every app, so
each student's work stays physically separated:

```
backend/src/StyleSync.Api/Modules/<Component>/
frontend-react/src/modules/<component>/
flutter-app/lib/modules/<component>/
ai-service/app/agents/<agent>.py
```

See `docs/architecture.md` for the full request flow and agent pipeline diagram.

## Quick Start

1. **Clone and start the database**
   ```bash
   git clone <your-repo-url>
   cd <repo-name>
   docker compose up -d
   ```

2. **Backend** — see `docs/setup/backend.md`
3. **React** — see `docs/setup/frontend-react.md`
4. **Flutter** — see `docs/setup/flutter.md`
5. **AI Service** — see `docs/setup/ai-service.md`

Run all four in parallel (separate terminals) for full end-to-end local development.

## A Note for Windows Users

Everything in this repo works on Windows. A few small differences from the
macOS/Linux instructions in the docs:

- **Docker:** install [Docker Desktop](https://www.docker.com/products/docker-desktop/)
  with the WSL2 backend — this gives you the same `docker` CLI commands
  used throughout the docs.
- **Shell scripts (`.sh`):** don't run natively in PowerShell/cmd. Either
  use the `.ps1` equivalent where one exists (e.g.
  `scripts\check-prereqs.ps1`), or run `.sh` files through **Git Bash**
  (installed alongside Git for Windows) or **WSL**.
- **`cp`, `curl` behave differently in PowerShell** — see the Windows-specific
  commands called out directly in `docs/setup/*.md`.
- **Flutter:** Windows can build/run the **Android** target fully — it
  cannot build the iOS target at all (that's an Apple restriction on any
  non-Mac OS, not a Flutter limitation). Also enable Windows' long path
  support once — see `docs/setup/flutter.md`.
- **Line endings:** this repo ships a `.gitattributes` file that keeps
  `.sh` files as LF and `.ps1`/`.bat` files as CRLF automatically, so Git
  won't corrupt scripts regardless of who committed them from which OS.
  You shouldn't need to configure `core.autocrlf` yourself.

## Repo & Team Workflow

- **Branching model:** trunk-based — see `docs/CONTRIBUTING.md`
- **CODEOWNERS:** `.github/CODEOWNERS` auto-suggests the right reviewer per folder
- **CI/CD:** see `docs/CI-CD.md` for what's required vs. advisory
- **ADRs:** `docs/adr/` — one file per key architectural decision

## Project Documentation

| Doc | Purpose |
|---|---|
| `docs/architecture.md` | System diagram, agent pipeline, data flow |
| `docs/CONTRIBUTING.md` | Branching, commit conventions, PR process |
| `docs/CI-CD.md` | What each pipeline checks, required vs. advisory |
| `docs/setup/*.md` | Per-app run instructions |
| `docs/adr/` | Architecture Decision Records |
| `docs/ai-usage-log-template.md` | Required AI usage disclosure template |
