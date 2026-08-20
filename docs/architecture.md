# Architecture

## System Overview

```
        Flutter (client)              React (designer/PM/admin)
               │                                │
               └───────────────┬────────────────┘
                                ▼
                    ASP.NET Core Web API
                    (single source of truth:
                     auth, business rules, data)
                                │
                  ┌─────────────┼─────────────┐
                  ▼             ▼             ▼
             PostgreSQL   Cloud Storage   Python AI Service
             (EF Core)    (room photos)   (FastAPI, internal-only)
```

Flutter and React **only ever talk to ASP.NET Core** — never directly to
PostgreSQL, cloud storage, or the AI service. This keeps auth, validation,
and business rules in one place, per the assignment's "golden rule."

## The Four Business Components

| Component | Owner | Backend module | React module | Flutter module |
|---|---|---|---|---|
| Designer Portfolios & Listings | Student 1 | `Modules/Designers` | `modules/designers` | `modules/designers` |
| Project Requests & Room Uploads | Student 2 | `Modules/ProjectRequests` | `modules/project-requests` | `modules/project_requests` |
| Quotes & Contracts | Student 3 | `Modules/QuotesContracts` | `modules/quotes-contracts` | `modules/quotes_contracts` |
| Project Execution & Progress Tracking | Student 4 | `Modules/ProjectExecution` | `modules/project-execution` | `modules/project_execution` |

## Agent Pipeline

```
Client submits room request (Flutter)
              │
              ▼
     ASP.NET Core validates & persists
              │
              ▼
     POST /workflow/run  →  Python AI Service
              │
              ▼
     Style Analysis Agent  ──▶  StyleProfile
              │
              ▼
     Designer-Matching Agent  ──▶  Ranked shortlist (recommend only)
              │
              ▼
     Budget/Scope Agent  ──▶  Draft scope + cost estimate
              │
              ▼
     Validation Agent  ──▶  Deterministic rule checks (not LLM opinion)
              │
        ┌─────┴─────┐
     Invalid       Valid
        │             │
   Request         Pending Client Approval
   revision             │
                         ▼
                  Client reviews (Flutter)
                         │
                Approve / Reject / Request changes
                         │
                         ▼
              ASP.NET Core re-validates
                         │
                         ▼
                  Contract created
                         │
                         ▼
         Designer works project → Photo timeline
                         │
                         ▼
              Client tracks progress (Flutter)
```

Each agent lives in `ai-service/app/agents/`, is chained by
`ai-service/app/orchestrator.py`, and reads/writes a shared
`WorkflowState` (`ai-service/app/schemas.py`) that mirrors what gets
persisted in PostgreSQL — this is what makes the workflow auditable and
recoverable if a step fails.

## Suggested Database Entities

Each module's `Models/` folder is currently empty — build your entities there
from scratch. A starting list of suggested entities per module (to help you
design your own) is in `docs/erd/README.md`.
