"""
Planning Agent / Orchestrator.

Chains the 4 specialist agents into a single pipeline and returns the
completed WorkflowState. This is the "planner" that delegates to the
other agent roles, as required by the assignment brief.
"""
from app.agents.budget_scope_agent import build_scope
from app.agents.designer_matching_agent import match_designers
from app.agents.style_analysis_agent import analyze_style
from app.agents.validation_agent import validate_proposal
from app.schemas import WorkflowState


def run_workflow(state: WorkflowState) -> WorkflowState:
    """
    Runs the full pipeline synchronously, step by step, persisting each
    agent's output onto the shared state object as it goes.

    TODO (whole team): swap this for a real LangGraph graph once each
    agent's real implementation is ready. Keep the same function signature
    so the API layer doesn't need to change.
    """
    state.style_profile = analyze_style(state)
    state.designer_shortlist = match_designers(state, state.style_profile)
    state.project_scope = build_scope(state, state.style_profile)
    state.validation_result = validate_proposal(state, state.project_scope, state.designer_shortlist)

    state.approval_status = (
        "AwaitingClientApproval" if state.validation_result.is_valid else "RevisionRequested"
    )

    return state
