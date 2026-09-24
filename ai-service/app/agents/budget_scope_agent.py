"""
Budget/Scope Agent — Student 3's node in the 4-agent LangGraph pipeline.

Job (per PRD section 8): given a style profile (from the Style Analysis Agent)
and the client's room details/budget, draft a scope of work and a rough cost
estimate. This agent does NOT pick a designer and does NOT approve anything —
that's the Designer-Matching Agent and the human approval gate, respectively.

Two modes:
  - LLM mode: calls Claude to draft a plausible, context-aware scope. Used
    when ANTHROPIC_API_KEY is set.
  - Fallback mode: a deterministic, rule-based estimate. Used when no API key
    is present, or if the LLM call fails/returns malformed JSON. This also
    satisfies the PRD's testability requirement (section 15) that the AI
    service needs tests that don't depend on a live LLM.

Output is intentionally shaped to match CreateQuoteDto in the .NET backend
(QuoteDtos.cs) so the backend can pass this straight through to
POST /api/quotes with isAiGenerated=true.

Style profile values come from Student 2's Style Analysis Agent and are one
of: Modern, Minimalist, Industrial, Luxury, Traditional, Mid Century Modern.
This agent doesn't validate against that list strictly (it's just a string
here), but the prompt and fallback logic are written with those 6 in mind.
"""

from __future__ import annotations

import json
import os
from typing import TYPE_CHECKING, Optional

from pydantic import BaseModel, Field

if TYPE_CHECKING:
    from app.schemas import ProjectScope, StyleProfile, WorkflowState


# ---------------------------------------------------------------------------
# System prompt — kept deliberately narrow. The PRD is explicit that renaming
# the same prompt across "agents" doesn't count as separate agents, so this
# only ever talks about scope + cost, never style, never designer choice.
# ---------------------------------------------------------------------------
SYSTEM_PROMPT = """You are the Budget/Scope Agent for StyleSync, an interior \
design marketplace. Your ONLY job is: given a room's details, a client's \
budget range, and a detected design style, draft (a) a short scope-of-work \
summary and (b) a line-item cost breakdown with a total estimate.

The detected style will be one of: Modern, Minimalist, Industrial, Luxury, \
Traditional, Mid Century Modern. It comes from a different agent — you \
never choose or change it, only design around it.

Rules you must follow:
- You do NOT choose a designer. That is a different agent's job.
- You do NOT approve or reject anything. A human always reviews your draft.
- Your estimate is a DRAFT, not a legal quote — say so implicitly by keeping
  numbers rounded and reasonable, not falsely precise.
- Categorize every line item as exactly one of: Design, Labor, Materials,
  Furniture, Other.
- Try to land your total within the client's budget range where realistic
  for the room size and style described. If it isn't realistic, still give
  your honest estimate — the Validation Agent (a different, rule-based
  component) is responsible for flagging over-budget drafts, not you.
- Output LKR amounts only (Sri Lankan Rupees), no other currency.

Respond with ONLY a JSON object, no markdown fences, no preamble, in this \
exact shape:
{
  "scope_summary": "one sentence describing the overall scope",
  "items": [
    {"description": "...", "category": "Design|Labor|Materials|Furniture|Other", "quantity": 1, "unit_cost": 12345.00}
  ],
  "notes": "one or two sentences of reasoning a designer would find useful"
}
"""


class BudgetScopeRequest(BaseModel):
    room_type: str = Field(..., examples=["Living room"])
    room_size_sqft: float = Field(..., gt=0)
    budget_min: float = Field(..., ge=0)
    budget_max: float = Field(..., ge=0)
    style_profile: str = Field(..., examples=["Mid Century Modern"])
    style_confidence: Optional[float] = Field(None, ge=0, le=1)
    preferences: Optional[str] = None


class QuoteItemDraft(BaseModel):
    description: str
    category: str
    quantity: int
    unit_cost: float


class BudgetScopeResponse(BaseModel):
    scope_summary: str
    items: list[QuoteItemDraft]
    notes: str
    estimated_total: float
    within_budget: bool
    source: str  # "llm" or "fallback" — useful for the audit trail


VALID_CATEGORIES = {"Design", "Labor", "Materials", "Furniture", "Other"}

# Student 2's Style Analysis Agent only ever outputs one of these. Not
# strictly enforced here (style_profile stays a plain string) but kept as a
# reference constant so it's easy to validate against later if needed.
KNOWN_STYLES = {"Modern", "Minimalist", "Industrial", "Luxury", "Traditional", "Mid Century Modern"}


def _fallback_estimate(req: BudgetScopeRequest) -> BudgetScopeResponse:
    """
    Deterministic, no-LLM estimate. Splits the midpoint of the client's
    budget range across four fixed categories, scaled lightly by room size.
    This is intentionally simple — it exists so the pipeline (and your demo)
    still works with zero API cost and zero network dependency, and so the
    AI service has something testable without mocking an LLM.
    """
    target_budget = (req.budget_min + req.budget_max) / 2 if req.budget_max > 0 else req.budget_min
    if target_budget <= 0:
        target_budget = req.room_size_sqft * 800  # crude LKR/sqft floor

    split = {
        "Design": 0.10,
        "Labor": 0.30,
        "Materials": 0.35,
        "Furniture": 0.25,
    }

    items = [
        QuoteItemDraft(
            description=f"{category} - {req.style_profile.lower()} {req.room_type.lower()} work",
            category=category,
            quantity=1,
            unit_cost=round(target_budget * pct, -2),  # round to nearest 100 LKR
        )
        for category, pct in split.items()
    ]

    total = sum(i.unit_cost * i.quantity for i in items)

    return BudgetScopeResponse(
        scope_summary=f"{req.style_profile} {req.room_type.lower()} refresh, {req.room_size_sqft:.0f} sq ft.",
        items=items,
        notes="Fallback estimate — generated without a live LLM call, split across standard category ratios.",
        estimated_total=total,
        within_budget=req.budget_min <= total <= req.budget_max if req.budget_max > 0 else True,
        source="fallback",
    )


def _call_llm(req: BudgetScopeRequest) -> BudgetScopeResponse:
    import anthropic

    client = anthropic.Anthropic()  # reads ANTHROPIC_API_KEY from env

    user_message = f"""Room type: {req.room_type}
Room size: {req.room_size_sqft} sq ft
Client budget: LKR {req.budget_min:,.0f} - {req.budget_max:,.0f}
Detected style: {req.style_profile} (confidence: {req.style_confidence if req.style_confidence is not None else "n/a"})
Client preferences: {req.preferences or "none given"}
"""

    response = client.messages.create(
        model="claude-sonnet-5",
        max_tokens=1000,
        system=SYSTEM_PROMPT,
        messages=[{"role": "user", "content": user_message}],
    )

    text = "".join(block.text for block in response.content if block.type == "text").strip()
    data = json.loads(text)

    items = []
    for raw in data["items"]:
        category = raw.get("category", "Other")
        if category not in VALID_CATEGORIES:
            category = "Other"
        items.append(QuoteItemDraft(
            description=raw["description"],
            category=category,
            quantity=int(raw.get("quantity", 1)),
            unit_cost=float(raw["unit_cost"]),
        ))

    total = sum(i.unit_cost * i.quantity for i in items)

    return BudgetScopeResponse(
        scope_summary=data["scope_summary"],
        items=items,
        notes=data.get("notes", ""),
        estimated_total=total,
        within_budget=req.budget_min <= total <= req.budget_max if req.budget_max > 0 else True,
        source="llm",
    )


def run_budget_scope_agent(req: BudgetScopeRequest) -> BudgetScopeResponse:
    """Entry point. Tries the LLM if a key is configured, falls back cleanly
    on any error so a flaky API call never breaks the workflow."""
    if os.environ.get("ANTHROPIC_API_KEY"):
        try:
            return _call_llm(req)
        except Exception as exc:  # noqa: BLE001 — deliberately broad: any
            # LLM/parsing failure should degrade to the fallback, not 500.
            print(f"[BudgetScopeAgent] LLM call failed, using fallback: {exc}")
            return _fallback_estimate(req)
    return _fallback_estimate(req)


def build_scope(state: WorkflowState, style_profile: StyleProfile) -> ProjectScope:
    """Bridge for the LangGraph orchestrator."""
    from app.schemas import ProjectScope, ScopeItem

    req = BudgetScopeRequest(
        room_type=state.room_type,
        room_size_sqft=state.room_size,
        budget_min=state.budget_min,
        budget_max=state.budget_max,
        style_profile=style_profile.primary_style,
        style_confidence=style_profile.confidence,
        preferences=None,
    )
    result = run_budget_scope_agent(req)
    return ProjectScope(
        items=[ScopeItem(name=i.description, estimated_cost=i.unit_cost * i.quantity) for i in result.items],
        estimated_total=result.estimated_total,
    )
