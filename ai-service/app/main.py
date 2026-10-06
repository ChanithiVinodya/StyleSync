"""
AI Service entry point (FastAPI).

IMPORTANT: this service is internal-only. React and Flutter must never call
it directly - all requests go through ASP.NET Core, which is the single
source of truth for auth and business rules.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.agents.budget_scope_agent import (
    BudgetScopeRequest,
    BudgetScopeResponse,
    run_budget_scope_agent,
)
from app.agents.designer_matching_agent import run_designer_matching_node
from app.agents.style_analysis_agent import analyze_style
from app.agents.validation_agent import validate_proposal
from app.orchestrator import run_workflow
from app.schemas import StyleProfile, ValidationResult, WorkflowState

app = FastAPI(
    title="StyleSync - Agentic AI Service",
    description="Multi-agent interior design workflow and individual agent execution endpoints.",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", tags=["Health"])
def health() -> dict:
    return {"status": "healthy"}


@app.post("/agents/style-analysis", response_model=StyleProfile, tags=["AI Agents"])
def run_style_analysis(state: WorkflowState) -> StyleProfile:
    """
    Runs Agent 1 (Style Analysis Agent) to analyze room visual cues, client
    preferences, and room characteristics to generate a StyleProfile.
    """
    return analyze_style(state)


@app.post("/agents/designer-matching", response_model=WorkflowState, tags=["AI Agents"])
def run_designer_matching(state: WorkflowState) -> WorkflowState:
    """
    Runs Agent 2 (Designer-Matching Agent) to search candidate designers,
    verify capacity/availability, and generate ranked match scores with explanations.
    """
    return run_designer_matching_node(state)


@app.post("/agents/budget-scope", response_model=BudgetScopeResponse, tags=["AI Agents"])
def budget_scope_endpoint(req: BudgetScopeRequest) -> BudgetScopeResponse:
    """
    Runs Agent 3 (Budget/Scope Agent) to generate an itemized scope of work
    and cost estimates (Design, Labor, Materials) tailored to the room type and budget.
    """
    return run_budget_scope_agent(req)


@app.post("/agents/validation", response_model=ValidationResult, tags=["AI Agents"])
def run_validation(state: WorkflowState) -> ValidationResult:
    """
    Runs Agent 4 (Validation Agent) to execute deterministic business rules
    (BudgetCompliance, RoomSize, DesignerMatchAndCapacity, CostCalculation) on the proposal.
    """
    scope = state.project_scope
    shortlist = state.designer_shortlist
    return validate_proposal(state, scope, shortlist)


@app.post("/workflow/run", response_model=WorkflowState, tags=["Workflow Pipeline"])
def run(state: WorkflowState) -> WorkflowState:
    """
    Runs the complete 4-agent LangGraph pipeline sequentially against the given
    workflow state and returns the enriched state (style profile, shortlisted
    designers, project scope, validation result, approval status).
    """
    return run_workflow(state)

