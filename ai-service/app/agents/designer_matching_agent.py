"""
Agent 2 - Designer-Matching Agent (Node 2 of 4)
OWNED BY: Student 1 (pairs with the Designer Portfolios & Listings component)

Responsibility:
  - Shortlist 2-3 candidate designers using style profile and client budget.
  - Calls allow-listed tools: search_designers() and check_designer_availability().
  - Never recalculates or invents match scores; relies strictly on Component 1 backend scoring.
  - Synthesizes grounded, plain-language explanations for non-technical clients.
  - Never auto-assigns designers.
"""
from __future__ import annotations

import logging
from typing import Any, Optional

from app.schemas import DesignerMatch, StyleProfile, ToolCallRecord, WorkflowState
from app.tools import check_designer_availability, search_designers

logger = logging.getLogger("stylesync.designer_matching_agent")

DESIGNER_MATCHING_SYSTEM_PROMPT = """You are the Designer-Matching agent. You never calculate
match scores yourself. Call search_designers() to get a ranked, scored list of eligible designers,
then call check_designer_availability() to confirm the top candidates. Select the top 2-3 and write
a short, plain-language explanation of why each is a good fit, referencing their actual score and its
components (style/budget/rating/availability) — do not restate the raw JSON, translate it into a sentence
a non-technical client would understand.

Rules:
- If search_designers() returns an empty list, set matchingStatus = "no_eligible_designers" and do not
  fabricate a designer or lower standards to find a match.
- Never auto-assign a designer — this node only proposes a shortlist; assignment happens only after
  the client approves later in the workflow.
- The explanation text must be traceable back to the real score components returned by the tool —
  no invented reasons ("great communicator", "highly rated" without a rating value) that aren't
  grounded in the actual tool output.
"""


def _extract_style_tags(state: WorkflowState, style_profile: Optional[StyleProfile] = None) -> list[str]:
    """Extracts style tags from the style profile or falls back to stub/request context."""
    profile = style_profile or state.style_profile
    tags: list[str] = []

    if profile:
        if profile.style_tags:
            tags.extend(profile.style_tags)
        if profile.primary_style and profile.primary_style not in tags:
            tags.append(profile.primary_style)
        if profile.secondary_style and profile.secondary_style not in tags:
            tags.append(profile.secondary_style)

    if not tags:
        # Fallback/stub context if Node 1 hasn't executed
        if state.room_type:
            tags.append(state.room_type)
        else:
            tags.append("Modern")

    return tags


def _generate_explanation(candidate: dict[str, Any], availability: dict[str, Any]) -> str:
    """
    Generates a plain-language explanation strictly grounded in the real tool response values.
    No ungrounded or invented claims.
    """
    name = candidate.get("displayName") or f"Designer #{candidate.get('designerId')}"
    score_pct = round(float(candidate.get("matchScore", 0.0)) * 100)
    score_breakdown = candidate.get("scoreBreakdown", {})

    style_overlap = round(float(score_breakdown.get("styleTagOverlapPct", 0.0)) * 100)
    budget_overlap = round(float(score_breakdown.get("budgetRangeOverlapPct", 0.0)) * 100)
    avg_rating = candidate.get("averageRating")

    clauses = [f"{name} is a {score_pct}% overall match for your project"]

    # Grounded style match explanation
    style_tags = candidate.get("styleTags", [])
    if style_overlap > 0:
        if style_tags:
            clauses.append(f"{style_overlap}% style alignment with {', '.join(style_tags)}")
        else:
            clauses.append(f"{style_overlap}% style alignment")
    else:
        clauses.append("0% direct style alignment with requested styles")

    # Grounded budget match explanation
    price_min = candidate.get("priceRangeMin", 0.0)
    price_max = candidate.get("priceRangeMax", 0.0)
    if budget_overlap > 0 and (price_min > 0 or price_max > 0):
        clauses.append(
            f"strong budget alignment covering the LKR {price_min:,.0f} - {price_max:,.0f} price range"
        )
    elif budget_overlap > 0:
        clauses.append("strong alignment with your requested budget parameters")
    else:
        clauses.append("low budget alignment with requested price range")

    # Grounded rating explanation
    if avg_rating is not None and float(avg_rating) > 0:
        clauses.append(f"a verified client rating of {float(avg_rating):.1f}/5.0")

    # Grounded availability & capacity confirmation
    active_count = availability.get("activeProjectCount", candidate.get("activeProjectCount", 0))
    max_projects = availability.get("maxConcurrentProjects", candidate.get("maxConcurrentProjects", 3))
    clauses.append(f"confirmed active bandwidth ({active_count} of {max_projects} project slots in use)")

    return f"{clauses[0]}, featuring {', '.join(clauses[1:])}."


def run_designer_matching_node(state: WorkflowState) -> WorkflowState:
    """
    Designer-Matching LangGraph Node (Node 2 of 4).
    Takes a shared WorkflowState and returns the updated WorkflowState.
    """
    updated_state = state.model_copy(deep=True)

    style_tags = _extract_style_tags(updated_state)
    budget_min = float(updated_state.budget_min)
    budget_max = float(updated_state.budget_max)

    # 1. Call search_designers allow-listed tool
    search_inputs = {
        "style_tags": style_tags,
        "budget_min": budget_min,
        "budget_max": budget_max,
    }
    raw_candidates = search_designers.invoke(search_inputs)

    updated_state.tool_calls.append(
        ToolCallRecord(
            tool_name="search_designers",
            inputs=search_inputs,
            outputs=raw_candidates,
        )
    )

    # Filter out any structured errors
    valid_candidates = [
        c for c in raw_candidates
        if isinstance(c, dict) and "error" not in c and "designerId" in c
    ]

    if not valid_candidates:
        updated_state.matching_status = "no_eligible_designers"
        updated_state.designer_shortlist = []
        _update_plan_step(
            updated_state, "no_eligible_designers", "No eligible designers found matching criteria."
        )
        return updated_state

    # 2. Confirm availability for candidate designers using check_designer_availability tool
    shortlisted_matches: list[DesignerMatch] = []

    for candidate in valid_candidates:
        designer_id = str(candidate["designerId"])
        avail_inputs = {"designer_id": designer_id}
        availability = check_designer_availability.invoke(avail_inputs)

        updated_state.tool_calls.append(
            ToolCallRecord(
                tool_name="check_designer_availability",
                inputs=avail_inputs,
                outputs=availability,
            )
        )

        is_avail = availability.get("isAvailable", False)
        is_under_cap = availability.get("isUnderCapacity", False)

        # Confirm eligibility: must be available and under capacity
        if is_avail and is_under_cap:
            explanation = _generate_explanation(candidate, availability)
            score_breakdown = candidate.get("scoreBreakdown", {})
            style_pct = round(float(score_breakdown.get("styleTagOverlapPct", 0.0)) * 100, 1)
            budget_overlap_pct = float(score_breakdown.get("budgetRangeOverlapPct", 0.0))

            if budget_overlap_pct >= 0.7:
                budget_match = "High"
            elif budget_overlap_pct >= 0.3:
                budget_match = "Medium"
            else:
                budget_match = "Low"

            shortlisted_matches.append(
                DesignerMatch(
                    designer_id=int(candidate["designerId"]),
                    designer_name=candidate.get("displayName", f"Designer #{candidate['designerId']}"),
                    style_match_pct=style_pct,
                    budget_match=budget_match,
                    match_score=round(float(candidate.get("matchScore", 0.0)), 3),
                    explanation=explanation,
                    capacity_available=is_under_cap,
                )
            )

        # Narrow to top 2-3 candidates
        if len(shortlisted_matches) >= 3:
            break

    if not shortlisted_matches:
        updated_state.matching_status = "no_eligible_designers"
        updated_state.designer_shortlist = []
        _update_plan_step(
            updated_state, "no_eligible_designers", "No available designers with active capacity found."
        )
        return updated_state

    # Successfully shortlisted 2-3 designers
    updated_state.matching_status = "success"
    updated_state.designer_shortlist = shortlisted_matches
    _update_plan_step(
        updated_state,
        "success",
        f"Shortlisted {len(shortlisted_matches)} top eligible designer(s) with explanations.",
    )

    return updated_state


def _update_plan_step(state: WorkflowState, status: str, result_msg: str) -> None:
    """Helper to update the DesignerMatching step in the state's plan if plan exists."""
    if not state.plan:
        return

    updated_plan = []
    for step in state.plan:
        if step.step_name == "DesignerMatching":
            step_status = "COMPLETED" if status == "success" else "FAILED"
            updated_plan.append(
                step.model_copy(update={"status": step_status, "result": result_msg})
            )
        else:
            updated_plan.append(step)
    state.plan = updated_plan


def match_designers(
    state: WorkflowState, style_profile: Optional[StyleProfile] = None
) -> list[DesignerMatch]:
    """
    Direct function interface for designer matching.
    Returns the shortlisted DesignerMatch items.
    """
    temp_state = state.model_copy(deep=True)
    if style_profile:
        temp_state.style_profile = style_profile

    result_state = run_designer_matching_node(temp_state)
    return result_state.designer_shortlist
