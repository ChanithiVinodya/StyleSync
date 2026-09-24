"""
Planning Agent / Orchestrator using LangGraph StateGraph.

Coordinates the 4 specialist agents into a structured multi-step execution graph
with least-privilege tool bindings, durable Postgres checkpointing, and a
Human-in-the-Loop approval gate (via interrupt).
"""
from __future__ import annotations

import logging
import os
from typing import Any, Optional

from langgraph.checkpoint.memory import MemorySaver
from langgraph.checkpoint.postgres import PostgresSaver
from langgraph.graph import END, START, StateGraph
from langgraph.types import Command, interrupt

from app.agents.budget_scope_agent import build_scope
from app.agents.designer_matching_agent import match_designers
from app.agents.style_analysis_agent import analyze_style
from app.agents.validation_agent import validate_proposal
from app.schemas import PlanStep, WorkflowState
from app.tools import (
    BUDGET_SCOPE_TOOLS,
    DESIGNER_MATCHING_TOOLS,
    STYLE_ANALYSIS_TOOLS,
    VALIDATION_TOOLS,
)

logger = logging.getLogger("stylesync.orchestrator")

# Explicit least-privilege tool access mapping per agent role
NODE_TOOL_REGISTRY = {
    "style_analysis": STYLE_ANALYSIS_TOOLS,
    "designer_matching": DESIGNER_MATCHING_TOOLS,
    "budget_scope": BUDGET_SCOPE_TOOLS,
    "validation_approval": VALIDATION_TOOLS,
}


# ============================================================================
# Initial Plan Generator
# ============================================================================

def create_default_plan() -> list[PlanStep]:
    """Generates the structured multi-step execution plan."""
    return [
        PlanStep(
            step_name="StyleAnalysis",
            assigned_agent="Style Analysis Agent (Student 2)",
            status="PENDING",
        ),
        PlanStep(
            step_name="DesignerMatching",
            assigned_agent="Designer-Matching Agent (Student 1)",
            status="PENDING",
        ),
        PlanStep(
            step_name="BudgetScope",
            assigned_agent="Budget/Scope Agent (Student 3)",
            status="PENDING",
        ),
        PlanStep(
            step_name="ValidationAndApproval",
            assigned_agent="Validation Agent (Student 4)",
            status="PENDING",
        ),
    ]


def _update_plan_status(
    plan: list[PlanStep],
    step_name: str,
    status: str,
    result: Optional[str] = None,
) -> list[PlanStep]:
    """Helper to immutably update a specific plan step's status."""
    updated = []
    for step in plan:
        if step.step_name == step_name:
            updated.append(
                PlanStep(
                    step_name=step.step_name,
                    assigned_agent=step.assigned_agent,
                    status=status,
                    result=result or step.result,
                )
            )
        else:
            updated.append(step)
    return updated


# ============================================================================
# Graph Nodes (Least-Privilege Agent Delegation)
# ============================================================================

def style_analysis_node(state: WorkflowState) -> dict[str, Any]:
    """
    Node 1: Style Analysis Agent (Student 2)
    Allowed tools: NODE_TOOL_REGISTRY["style_analysis"]
    """
    plan = state.plan if state.plan else create_default_plan()
    plan = _update_plan_status(plan, "StyleAnalysis", "IN_PROGRESS")

    # Delegate to Style Analysis Agent
    profile = analyze_style(state)

    plan = _update_plan_status(
        plan,
        "StyleAnalysis",
        "COMPLETED",
        result=f"Detected style: {profile.primary_style} (confidence: {profile.confidence:.2f})",
    )

    return {
        "style_profile": profile,
        "plan": plan,
    }


def designer_matching_node(state: WorkflowState) -> dict[str, Any]:
    """
    Node 2: Designer-Matching Agent (Student 1)
    Allowed tools: NODE_TOOL_REGISTRY["designer_matching"]
    """
    plan = _update_plan_status(state.plan, "DesignerMatching", "IN_PROGRESS")

    if not state.style_profile:
        raise ValueError("Cannot match designers: style_profile is missing.")

    # Delegate to Designer-Matching Agent
    shortlist = match_designers(state, state.style_profile)

    plan = _update_plan_status(
        plan,
        "DesignerMatching",
        "COMPLETED",
        result=f"Shortlisted {len(shortlist)} candidate designer(s)",
    )

    return {
        "designer_shortlist": shortlist,
        "plan": plan,
    }


def budget_scope_node(state: WorkflowState) -> dict[str, Any]:
    """
    Node 3: Budget & Scope Estimation Agent (Student 3)
    Allowed tools: NODE_TOOL_REGISTRY["budget_scope"]
    """
    plan = _update_plan_status(state.plan, "BudgetScope", "IN_PROGRESS")

    if not state.style_profile:
        raise ValueError("Cannot build scope: style_profile is missing.")

    # Delegate to Budget & Scope Agent
    scope = build_scope(state, state.style_profile)

    plan = _update_plan_status(
        plan,
        "BudgetScope",
        "COMPLETED",
        result=f"Estimated total: LKR {scope.estimated_total:,.2f} ({len(scope.items)} scope items)",
    )

    return {
        "project_scope": scope,
        "plan": plan,
    }


def validation_approval_node(state: WorkflowState) -> dict[str, Any]:
    """
    Node 4: Validation & Governance Agent with Human-in-the-Loop Gate (Student 4)
    Allowed tools: NODE_TOOL_REGISTRY["validation_approval"]
    """
    plan = _update_plan_status(state.plan, "ValidationAndApproval", "IN_PROGRESS")

    if not state.project_scope:
        raise ValueError("Cannot validate proposal: project_scope is missing.")

    # Delegate to Validation Agent
    validation = validate_proposal(state, state.project_scope, state.designer_shortlist)

    if validation.is_valid:
        plan = _update_plan_status(
            plan,
            "ValidationAndApproval",
            "COMPLETED",
            result="Proposal passed deterministic business rules.",
        )

        # Human-in-the-Loop Approval Gate (pauses graph execution for client approval)
        decision = interrupt({
            "action": "client_approval_required",
            "message": "Proposal passed validation rules. Pausing graph execution for client approval.",
            "project_request_id": state.project_request_id,
            "estimated_total": state.project_scope.estimated_total,
        })

        if decision and str(decision).strip().lower() in ("approved", "true", "yes", "accept"):
            approval_status = "Approved"
        else:
            approval_status = "AwaitingClientApproval"
    else:
        plan = _update_plan_status(
            plan,
            "ValidationAndApproval",
            "FAILED",
            result=f"Validation failed: {', '.join(validation.errors)}",
        )
        approval_status = "RevisionRequested"

    return {
        "validation_result": validation,
        "approval_status": approval_status,
        "plan": plan,
    }


# ============================================================================
# Checkpointer & Graph Compilation
# ============================================================================

def get_checkpointer() -> Any:
    """
    Returns a durable PostgresSaver if DATABASE_URL is reachable,
    otherwise gracefully falls back to MemorySaver for testing/offline environments.
    """
    if os.getenv("USE_MEMORY_CHECKPOINTER", "").lower() in ("1", "true", "yes"):
        return MemorySaver()

    conn_string = os.getenv(
        "DATABASE_URL",
        os.getenv(
            "POSTGRES_CONNECTION_STRING",
            "postgresql://postgres:postgres@localhost:5432/stylesync_db",
        ),
    )

    try:
        checkpointer = PostgresSaver.from_conn_string(conn_string)
        checkpointer.setup()
        return checkpointer
    except Exception as ex:
        logger.warning(
            "PostgreSQL checkpointer unavailable (%s). Falling back to in-memory checkpointer.",
            ex,
        )
        return MemorySaver()


def build_workflow_graph() -> StateGraph:
    """Constructs the 4-agent LangGraph StateGraph with explicit execution edges."""
    builder = StateGraph(WorkflowState)

    # 1. Add agent nodes
    builder.add_node("style_analysis", style_analysis_node)
    builder.add_node("designer_matching", designer_matching_node)
    builder.add_node("budget_scope", budget_scope_node)
    builder.add_node("validation_approval", validation_approval_node)

    # 2. Add sequential delegation edges
    builder.add_edge(START, "style_analysis")
    builder.add_edge("style_analysis", "designer_matching")
    builder.add_edge("designer_matching", "budget_scope")
    builder.add_edge("budget_scope", "validation_approval")
    builder.add_edge("validation_approval", END)

    return builder


_cached_graph = None


def get_compiled_graph(checkpointer: Optional[Any] = None) -> Any:
    """Returns the compiled LangGraph workflow graph."""
    global _cached_graph
    if _cached_graph is None or checkpointer is not None:
        builder = build_workflow_graph()
        cp = checkpointer or get_checkpointer()
        _cached_graph = builder.compile(checkpointer=cp)
    return _cached_graph


# ============================================================================
# Entry Point
# ============================================================================

def run_workflow(
    state: WorkflowState,
    thread_id: Optional[str] = None,
    resume_decision: Optional[Any] = None,
) -> WorkflowState:
    """
    Runs or resumes the LangGraph agent workflow against the given WorkflowState.
    """
    graph = get_compiled_graph()
    tid = thread_id or f"project-request-{state.project_request_id}"
    config = {"configurable": {"thread_id": tid}}

    if resume_decision is not None:
        raw_result = graph.invoke(Command(resume=resume_decision), config=config)
    else:
        if not state.plan:
            state.plan = create_default_plan()
        raw_result = graph.invoke(state, config=config)

    # Handle interrupt outputs and return typed WorkflowState
    if isinstance(raw_result, dict):
        raw_result.pop("__interrupt__", None)
        return WorkflowState(**raw_result)
    return raw_result
