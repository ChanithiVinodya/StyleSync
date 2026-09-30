"""
Golden test cases for Designer-Matching Agent (Node 2 of 4) in isolation.

Test Coverage (per assignment brief):
1. Happy path: 3+ eligible designers returned -> node shortlists top 2-3, each
   with explanation grounded in real score components.
2. No eligible designers: zero style overlap / at-capacity excluded -> node sets
   matchingStatus = "no_eligible_designers" and never hallucinates candidates.
3. Tool failure: backend HTTP error/timeout -> fails gracefully, does not crash graph.
4. Schema validation: output state strictly matches Pydantic schema contracts for
   downstream consumption by Node 3 (Budget/Scope).
"""
import httpx
import pytest

from app.agents.designer_matching_agent import (
    DESIGNER_MATCHING_SYSTEM_PROMPT,
    match_designers,
    run_designer_matching_node,
)
from app.schemas import (
    DesignerMatch,
    PlanStep,
    StyleProfile,
    WorkflowState,
)


def _create_sample_state(**overrides) -> WorkflowState:
    defaults = {
        "project_request_id": 101,
        "client_id": 42,
        "room_type": "Living Room",
        "room_size": 350.0,
        "budget_min": 150000.0,
        "budget_max": 450000.0,
        "style_profile": StyleProfile(
            primary_style="Scandinavian",
            secondary_style="Modern Minimalist",
            preferred_colours=["Soft White", "Light Oak"],
            confidence=0.92,
            style_tags=["Scandinavian", "Minimalist"],
        ),
        "plan": [
            PlanStep(step_name="StyleAnalysis", assigned_agent="Agent 1", status="COMPLETED"),
            PlanStep(step_name="DesignerMatching", assigned_agent="Agent 2", status="PENDING"),
        ],
    }
    defaults.update(overrides)
    return WorkflowState(**defaults)


def _mock_designer_search_fixtures():
    """
    Mock dataset reflecting Component 1 backend outputs:
    - High-overlap candidate (Elena Rostova)
    - Moderate-overlap candidate (Marcus Vance)
    - Low/borderline candidate (Aria Chen)
    - Fourth candidate (David Silva) to test narrowing to top 3
    Note: Designers at-capacity or unpublished are already excluded upstream by Component 1.
    """
    return [
        {
            "designerId": 101,
            "matchScore": 0.94,
            "scoreBreakdown": {
                "styleTagOverlapPct": 1.0,
                "budgetRangeOverlapPct": 0.90,
                "pastRatingNormalized": 0.98,
                "availabilityBonus": 1.0,
                "matchScore": 0.94,
            },
            "displayName": "Elena Rostova",
            "bio": "Specialist in Scandinavian serenity",
            "styleTags": ["Scandinavian", "Minimalist"],
            "serviceCategories": ["Full Concept"],
            "priceRangeMin": 120000.0,
            "priceRangeMax": 400000.0,
            "ratePerSqFt": 350.0,
            "isAvailable": True,
            "maxConcurrentProjects": 4,
            "activeProjectCount": 1,
            "remainingCapacity": 3,
            "isUnderCapacity": True,
            "averageRating": 4.9,
            "listingStatus": 1,
            "featuredPortfolioImageUrl": None,
        },
        {
            "designerId": 102,
            "matchScore": 0.88,
            "scoreBreakdown": {
                "styleTagOverlapPct": 0.80,
                "budgetRangeOverlapPct": 0.85,
                "pastRatingNormalized": 0.94,
                "availabilityBonus": 1.0,
                "matchScore": 0.88,
            },
            "displayName": "Marcus Vance",
            "bio": "Minimalist spatial design",
            "styleTags": ["Minimalist", "Modern"],
            "serviceCategories": ["Spatial Planning"],
            "priceRangeMin": 150000.0,
            "priceRangeMax": 450000.0,
            "ratePerSqFt": 400.0,
            "isAvailable": True,
            "maxConcurrentProjects": 3,
            "activeProjectCount": 2,
            "remainingCapacity": 1,
            "isUnderCapacity": True,
            "averageRating": 4.7,
            "listingStatus": 1,
            "featuredPortfolioImageUrl": None,
        },
        {
            "designerId": 103,
            "matchScore": 0.82,
            "scoreBreakdown": {
                "styleTagOverlapPct": 0.70,
                "budgetRangeOverlapPct": 0.75,
                "pastRatingNormalized": 0.92,
                "availabilityBonus": 1.0,
                "matchScore": 0.82,
            },
            "displayName": "Aria Chen",
            "bio": "Contemporary and Nordic textures",
            "styleTags": ["Scandinavian", "Contemporary"],
            "serviceCategories": ["Consultation"],
            "priceRangeMin": 100000.0,
            "priceRangeMax": 350000.0,
            "ratePerSqFt": 300.0,
            "isAvailable": True,
            "maxConcurrentProjects": 3,
            "activeProjectCount": 1,
            "remainingCapacity": 2,
            "isUnderCapacity": True,
            "averageRating": 4.6,
            "listingStatus": 1,
            "featuredPortfolioImageUrl": None,
        },
        {
            "designerId": 104,
            "matchScore": 0.75,
            "scoreBreakdown": {
                "styleTagOverlapPct": 0.50,
                "budgetRangeOverlapPct": 0.70,
                "pastRatingNormalized": 0.88,
                "availabilityBonus": 1.0,
                "matchScore": 0.75,
            },
            "displayName": "David Silva",
            "bio": "Urban modern spaces",
            "styleTags": ["Modern"],
            "serviceCategories": ["Renovation"],
            "priceRangeMin": 140000.0,
            "priceRangeMax": 500000.0,
            "ratePerSqFt": 320.0,
            "isAvailable": True,
            "maxConcurrentProjects": 3,
            "activeProjectCount": 0,
            "remainingCapacity": 3,
            "isUnderCapacity": True,
            "averageRating": 4.4,
            "listingStatus": 1,
            "featuredPortfolioImageUrl": None,
        },
    ]


# ============================================================================
# System Prompt & Role Guardrail Tests
# ============================================================================

def test_system_prompt_distinct_and_compliant():
    """Verifies that the agent prompt enforces non-recalculation, tool usage, and shortlist constraints."""
    assert "Designer-Matching agent" in DESIGNER_MATCHING_SYSTEM_PROMPT
    assert "search_designers()" in DESIGNER_MATCHING_SYSTEM_PROMPT
    assert "check_designer_availability()" in DESIGNER_MATCHING_SYSTEM_PROMPT
    assert "no_eligible_designers" in DESIGNER_MATCHING_SYSTEM_PROMPT
    assert "Never auto-assign" in DESIGNER_MATCHING_SYSTEM_PROMPT


# ============================================================================
# Golden Test 1: Happy Path
# ============================================================================

def test_golden_happy_path_shortlists_top_2_to_3_with_grounded_explanations(monkeypatch):
    """
    Golden Test 1:
    - 4 eligible candidates returned from search_designers().
    - Node confirms availability for each candidate.
    - Node narrows candidate list to top 2-3 (exactly 3).
    - Each explanation is grounded in real score components (style overlap, budget, rating, bandwidth).
    """
    search_fixtures = _mock_designer_search_fixtures()

    def mock_get(self, url, params=None, **kwargs):
        req = httpx.Request("GET", url)
        if "/api/designers/search" in url:
            return httpx.Response(200, json=search_fixtures, request=req)
        elif "/availability" in url:
            return httpx.Response(
                200,
                json={
                    "isAvailable": True,
                    "isUnderCapacity": True,
                    "activeProjectCount": 1,
                    "maxConcurrentProjects": 3,
                },
                request=req,
            )
        return httpx.Response(404, request=req)

    monkeypatch.setattr(httpx.Client, "get", mock_get)

    initial_state = _create_sample_state()
    output_state = run_designer_matching_node(initial_state)

    # 1. Matching status and shortlist length
    assert output_state.matching_status == "success"
    assert len(output_state.designer_shortlist) == 3

    # 2. Ranking order matches backend without local re-ranking
    first_match = output_state.designer_shortlist[0]
    assert first_match.designer_id == 101
    assert first_match.designer_name == "Elena Rostova"
    assert first_match.match_score == 0.94
    assert first_match.style_match_pct == 100.0
    assert first_match.budget_match == "High"

    second_match = output_state.designer_shortlist[1]
    assert second_match.designer_id == 102
    assert second_match.match_score == 0.88

    third_match = output_state.designer_shortlist[2]
    assert third_match.designer_id == 103
    assert third_match.match_score == 0.82

    # 3. Grounded explanations trace directly to score breakdown components
    for match in output_state.designer_shortlist:
        assert match.explanation != ""
        assert f"{match.designer_name} is a {round(match.match_score * 100)}% overall match" in match.explanation
        assert "style alignment" in match.explanation
        assert "confirmed active bandwidth" in match.explanation

    # 4. Tool call audit logs populated
    assert len(output_state.tool_calls) >= 2
    tool_names = [tc.tool_name for tc in output_state.tool_calls]
    assert "search_designers" in tool_names
    assert "check_designer_availability" in tool_names


# ============================================================================
# Golden Test 2: No Eligible Designers (Hard Filters: Published & Capacity)
# ============================================================================

def test_golden_no_eligible_designers_when_none_published_or_under_capacity(monkeypatch):
    """
    Golden Test 2:
    - Hard filters only: when no designer in the system is BOTH ListingStatus = Published
      AND IsUnderCapacity = True, search_designers() returns an empty list [].
    - Node sets matching_status = "no_eligible_designers" and designer_shortlist = [].
    - Does NOT fabricate or hallucinate any candidate matches.
    """
    def mock_get(self, url, params=None, **kwargs):
        req = httpx.Request("GET", url)
        return httpx.Response(200, json=[], request=req)

    monkeypatch.setattr(httpx.Client, "get", mock_get)

    initial_state = _create_sample_state()
    output_state = run_designer_matching_node(initial_state)

    assert output_state.matching_status == "no_eligible_designers"
    assert output_state.designer_shortlist == []
    assert len(output_state.designer_shortlist) == 0

    # Plan step reflects failure status
    plan_step = next(s for s in output_state.plan if s.step_name == "DesignerMatching")
    assert plan_step.status == "FAILED"


def test_golden_all_candidates_over_capacity_filtered_out(monkeypatch):
    """
    Golden Test 2 (Variant):
    - Search returns candidates, but availability check reveals all are at maximum capacity.
    - Node filters them and sets matching_status = "no_eligible_designers".
    """
    search_fixtures = _mock_designer_search_fixtures()[:2]

    def mock_get(self, url, params=None, **kwargs):
        req = httpx.Request("GET", url)
        if "/api/designers/search" in url:
            return httpx.Response(200, json=search_fixtures, request=req)
        elif "/availability" in url:
            # Over capacity! (3 of 3 projects active)
            return httpx.Response(
                200,
                json={
                    "isAvailable": True,
                    "isUnderCapacity": False,
                    "activeProjectCount": 3,
                    "maxConcurrentProjects": 3,
                },
                request=req,
            )
        return httpx.Response(404, request=req)

    monkeypatch.setattr(httpx.Client, "get", mock_get)

    initial_state = _create_sample_state()
    output_state = run_designer_matching_node(initial_state)

    assert output_state.matching_status == "no_eligible_designers"
    assert output_state.designer_shortlist == []


# ============================================================================
# Golden Test 2b: Zero Style Overlap (Soft Component: Not a Hard Exclusion)
# ============================================================================

def test_golden_zero_style_overlap_designer_still_returned_with_honest_explanation(monkeypatch):
    """
    Golden Test 2b:
    - Style overlap is only 40% of the weighted match score, NOT a hard exclusion filter.
    - A designer with 0% style tag overlap who IS Published and under capacity is still
      returned by search_designers() with a lower matchScore (from budget, rating, availability).
    - Assert that:
      1. matchingStatus is "success" (NOT "no_eligible_designers").
      2. The low-overlap designer is present in the shortlist.
      3. The node's generated explanation honestly reflects the 0% style fit without positive spin.
    """
    zero_overlap_designer = {
        "designerId": 205,
        "matchScore": 0.55,  # 0% style (0.00) + 90% budget (0.27) + 4.5 rating (0.18) + avail (0.10)
        "scoreBreakdown": {
            "styleTagOverlapPct": 0.0,
            "budgetRangeOverlapPct": 0.90,
            "pastRatingNormalized": 0.90,
            "availabilityBonus": 1.0,
            "matchScore": 0.55,
        },
        "displayName": "Vikram Seth",
        "bio": "Gothic and Baroque architectural specialist",
        "styleTags": ["Gothic", "Baroque"],
        "serviceCategories": ["Architecture"],
        "priceRangeMin": 150000.0,
        "priceRangeMax": 450000.0,
        "ratePerSqFt": 350.0,
        "isAvailable": True,
        "maxConcurrentProjects": 3,
        "activeProjectCount": 1,
        "remainingCapacity": 2,
        "isUnderCapacity": True,
        "averageRating": 4.5,
        "listingStatus": 1,
        "featuredPortfolioImageUrl": None,
    }

    def mock_get(self, url, params=None, **kwargs):
        req = httpx.Request("GET", url)
        if "/api/designers/search" in url:
            return httpx.Response(200, json=[zero_overlap_designer], request=req)
        elif "/availability" in url:
            return httpx.Response(
                200,
                json={
                    "isAvailable": True,
                    "isUnderCapacity": True,
                    "activeProjectCount": 1,
                    "maxConcurrentProjects": 3,
                },
                request=req,
            )
        return httpx.Response(404, request=req)

    monkeypatch.setattr(httpx.Client, "get", mock_get)

    # Client requested Scandinavian, designer has Gothic/Baroque
    initial_state = _create_sample_state(
        style_profile=StyleProfile(
            primary_style="Scandinavian",
            style_tags=["Scandinavian"],
        )
    )
    output_state = run_designer_matching_node(initial_state)

    # 1. Matching status must be success because the candidate is published & under capacity
    assert output_state.matching_status == "success"
    assert len(output_state.designer_shortlist) == 1

    # 2. Candidate is present with accurate score & 0% style match
    candidate_match = output_state.designer_shortlist[0]
    assert candidate_match.designer_id == 205
    assert candidate_match.designer_name == "Vikram Seth"
    assert candidate_match.match_score == 0.55
    assert candidate_match.style_match_pct == 0.0

    # 3. Explanation honestly states the 0% style alignment without fabricating fit
    assert "0% direct style alignment" in candidate_match.explanation
    assert "Vikram Seth is a 55% overall match" in candidate_match.explanation
    assert "4.5/5.0" in candidate_match.explanation
    assert "confirmed active bandwidth" in candidate_match.explanation


# ============================================================================
# Golden Test 3: Tool Failure (Graceful Degradation)
# ============================================================================

def test_golden_tool_http_error_fails_gracefully(monkeypatch):
    """
    Golden Test 3:
    - Backend endpoint returns 500 or raises network error / timeout.
    - Node handles failure gracefully without unhandled exceptions crashing the graph.
    - State is returned with matching_status = "no_eligible_designers".
    """
    def mock_get(self, url, params=None, **kwargs):
        raise httpx.ConnectTimeout("Backend gateway connection timed out")

    monkeypatch.setattr(httpx.Client, "get", mock_get)

    initial_state = _create_sample_state()

    # Must NOT raise unhandled exception
    output_state = run_designer_matching_node(initial_state)

    assert output_state.matching_status == "no_eligible_designers"
    assert output_state.designer_shortlist == []
    assert len(output_state.tool_calls) >= 1
    assert "error" in str(output_state.tool_calls[0].outputs)


# ============================================================================
# Golden Test 4: Schema Validation Contract
# ============================================================================

def test_golden_schema_validation_and_downstream_compatibility(monkeypatch):
    """
    Golden Test 4:
    - Validates that the node output state conforms strictly to WorkflowState Pydantic schema.
    - Asserts exact field types for designer shortlist items and alias compatibility
      (designerMatches, matchingStatus) for downstream nodes (Budget/Scope, Validation).
    """
    search_fixtures = _mock_designer_search_fixtures()[:2]

    def mock_get(self, url, params=None, **kwargs):
        req = httpx.Request("GET", url)
        if "/api/designers/search" in url:
            return httpx.Response(200, json=search_fixtures, request=req)
        elif "/availability" in url:
            return httpx.Response(
                200,
                json={
                    "isAvailable": True,
                    "isUnderCapacity": True,
                    "activeProjectCount": 1,
                    "maxConcurrentProjects": 4,
                },
                request=req,
            )
        return httpx.Response(404, request=req)

    monkeypatch.setattr(httpx.Client, "get", mock_get)

    initial_state = _create_sample_state()
    output_state = run_designer_matching_node(initial_state)

    # 1. Strict Pydantic roundtrip validation
    state_dict = output_state.model_dump()
    reloaded_state = WorkflowState.model_validate(state_dict)

    assert reloaded_state.project_request_id == initial_state.project_request_id
    assert reloaded_state.matching_status == "success"
    assert len(reloaded_state.designer_shortlist) == 2

    # 2. Field-level type assertions for downstream consumption
    for match in reloaded_state.designer_shortlist:
        assert isinstance(match, DesignerMatch)
        assert isinstance(match.designer_id, int)
        assert isinstance(match.designer_name, str)
        assert isinstance(match.style_match_pct, float)
        assert match.budget_match in ("High", "Medium", "Low")
        assert isinstance(match.match_score, float)
        assert isinstance(match.explanation, str)
        assert len(match.explanation) > 10

    # 3. Direct function contract compatibility for orchestrator
    direct_shortlist = match_designers(initial_state, initial_state.style_profile)
    assert len(direct_shortlist) == 2
    assert all(isinstance(dm, DesignerMatch) for dm in direct_shortlist)
