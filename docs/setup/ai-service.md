# AI Service Setup — Python (FastAPI)

## Prerequisites

- Python 3.11 or 3.12
- pip

## First-time setup

**macOS/Linux:**
```bash
cd ai-service
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env             # fill in real keys locally, never commit .env
```

**Windows (PowerShell):**
```powershell
cd ai-service
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env      # fill in real keys locally, never commit .env
```

> If `Activate.ps1` fails with an execution-policy error, run once:
> `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`, then
> try activating again.
>
> On Windows the command is `python`, not `python3` — if `python`
> resolves to nothing, you may need to check "Add python.exe to PATH"
> when (re-)installing Python.

## Run the service

```bash
uvicorn app.main:app --reload --port 8000
```

- Health check: `http://localhost:8000/health`
- Interactive docs: `http://localhost:8000/docs` — the easiest way to try
  the endpoint on any OS: click **POST /workflow/run → Try it out**, edit
  the sample JSON, and click **Execute**.
- Or from the command line (this will currently return a 500 error with
  `NotImplementedError`, until at least one agent is implemented — that's
  expected):

  **macOS/Linux:**
  ```bash
  curl -X POST http://localhost:8000/workflow/run \
    -H "Content-Type: application/json" \
    -d '{
      "project_request_id": 1,
      "client_id": 1,
      "room_type": "Living Room",
      "room_size": 250,
      "budget_min": 150000,
      "budget_max": 250000
    }'
  ```

  **Windows (PowerShell):** PowerShell's built-in `curl` is actually an
  alias for `Invoke-WebRequest`, which uses different syntax — call
  `curl.exe` directly instead to use real curl syntax:
  ```powershell
  curl.exe -X POST http://localhost:8000/workflow/run `
    -H "Content-Type: application/json" `
    -d '{\"project_request_id\": 1, \"client_id\": 1, \"room_type\": \"Living Room\", \"room_size\": 250, \"budget_min\": 150000, \"budget_max\": 250000}'
  ```

## Run tests

```bash
pytest -v
```

## Lint

```bash
ruff check .
```

## Architecture

- `app/schemas.py` — shared data contracts every agent reads/writes (`WorkflowState`)
- `app/agents/` — one file per agent (Style Analysis, Designer-Matching, Budget/Scope, Validation)
- `app/orchestrator.py` — the "planner": chains all 4 agents in order
- `app/main.py` — FastAPI entry point; **internal only**, called exclusively by the ASP.NET Core backend

## Implementing your agent

Each agent function currently raises `NotImplementedError` — this is a
skeleton, not a working stub. Implement your agent's function body in
`app/agents/<your_agent>.py` (real logic: LLM calls, tool use, etc.)
without changing its function signature — the orchestrator and the other
agents' code don't need to change when you do this.

Add your agent's test cases (golden cases) to `tests/` — this is required
for the assignment's "Agentic AI evaluation" testing component. Don't
edit `tests/test_orchestrator.py`'s existing checks; add a new file per
agent instead (e.g. `tests/test_style_analysis_agent.py`).
