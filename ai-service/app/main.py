"""
AI Service entry point (FastAPI).

IMPORTANT: this service is internal-only. React and Flutter must never call
it directly - all requests go through ASP.NET Core, which is the single
source of truth for auth and business rules.
"""
from fastapi import FastAPI

from app.orchestrator import run_workflow
from app.schemas import WorkflowState

app = FastAPI(
    title="StyleSync - Agentic AI Service",
    version="0.1.0",
)


@app.get("/health")
def health() -> dict:
    return {"status": "healthy"}


@app.post("/workflow/run", response_model=WorkflowState)
def run(state: WorkflowState) -> WorkflowState:
    """
    Runs the full 4-agent pipeline against the given workflow state and
    returns the enriched state (style profile, shortlist, scope, validation,
    approval status). ASP.NET Core is responsible for persisting the result.
    """
    return run_workflow(state)
