import httpx
import pytest
from app.agents.designer_matching_agent import (
    DESIGNER_MATCHING_SYSTEM_PROMPT,
    match_designers,
    run_designer_matching_node,
)
from app.schemas import PlanStep, StyleProfile, WorkflowState


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


def _mock_designer_search_results():
    return [
        {
            "designerId": 101,
            "matchScore": 0.94,
            "scoreBreakdown": {
                "styleTagOverlapPct": 1.0,
                "budgetRangeOverlapPct": 0.9,
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
                "styleTagOverlapPct": 0.8,
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
                "styleTagOverlapPct": 0.7,
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
                "styleTagOverlapPct": 0.5,
                "budgetRangeOverlapPct": 0.7,
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


def test_system_prompt_distinct_and_compliant():
    assert "Designer-Matching agent" in DESIGNER_MATCHING_SYSTEM_PROMPT
    assert "search_designers()" in DESIGNER_MATCHING_SYSTEM_PROMPT
    assert "check_designer_availability()" in DESIGNER_MATCHING_SYSTEM_PROMPT
    assert "no_eligible_designers" in DESIGNER_MATCHING_SYSTEM_PROMPT
    assert "Never auto-assign" in DESIGNER_MATCHING_SYSTEM_PROMPT


def test_run_designer_matching_node_success_shortlists_top_3(monkeypatch):
    search_data = _mock_designer_search_results()

    def mock_get(self, url, params=None, **kwargs):
        req = httpx.Request("GET", url)
        if "/api/designers/search" in url:
            return httpx.Response(200, json=search_data, request=req)
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

    assert output_state.matching_status == "success"
    assert len(output_state.designer_shortlist) == 3
    assert output_state.designer_shortlist[0].designer_id == 101
    assert output_state.designer_shortlist[0].designer_name == "Elena Rostova"
    assert output_state.designer_shortlist[0].match_score == 0.94
    assert output_state.designer_shortlist[0].style_match_pct == 100.0
    assert output_state.designer_shortlist[0].budget_match == "High"

    # Verify explanation text is grounded in actual score components
    explanation = output_state.designer_shortlist[0].explanation
    assert "Elena Rostova is a 94% overall match" in explanation
    assert "100% style alignment with Scandinavian, Minimalist" in explanation
    assert "4.9/5.0" in explanation
    assert "confirmed active bandwidth" in explanation

    # Verify tool call logging
    assert len(output_state.tool_calls) >= 2
    tool_names = [tc.tool_name for tc in output_state.tool_calls]
    assert "search_designers" in tool_names
    assert "check_designer_availability" in tool_names


def test_run_designer_matching_node_no_eligible_designers(monkeypatch):
    def mock_get(self, url, params=None, **kwargs):
        req = httpx.Request("GET", url)
        return httpx.Response(200, json=[], request=req)

    monkeypatch.setattr(httpx.Client, "get", mock_get)

    initial_state = _create_sample_state()
    output_state = run_designer_matching_node(initial_state)

    assert output_state.matching_status == "no_eligible_designers"
    assert output_state.designer_shortlist == []
    matching_plan_step = next(s for s in output_state.plan if s.step_name == "DesignerMatching")
    assert matching_plan_step.status == "FAILED"


def test_run_designer_matching_node_filters_at_capacity_designer(monkeypatch):
    search_data = _mock_designer_search_results()[:2]

    def mock_get(self, url, params=None, **kwargs):
        req = httpx.Request("GET", url)
        if "/api/designers/search" in url:
            return httpx.Response(200, json=search_data, request=req)
        elif "/101/availability" in url:
            # Designer 101 is at capacity!
            return httpx.Response(
                200,
                json={
                    "isAvailable": True,
                    "isUnderCapacity": False,
                    "activeProjectCount": 4,
                    "maxConcurrentProjects": 4,
                },
                request=req,
            )
        elif "/102/availability" in url:
            # Designer 102 has capacity
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

    assert output_state.matching_status == "success"
    assert len(output_state.designer_shortlist) == 1
    assert output_state.designer_shortlist[0].designer_id == 102


def test_match_designers_direct_call_compatibility(monkeypatch):
    search_data = _mock_designer_search_results()[:2]

    def mock_get(self, url, params=None, **kwargs):
        req = httpx.Request("GET", url)
        if "/api/designers/search" in url:
            return httpx.Response(200, json=search_data, request=req)
        elif "/availability" in url:
            return httpx.Response(
                200,
                json={
                    "isAvailable": True,
                    "isUnderCapacity": True,
                    "activeProjectCount": 0,
                    "maxConcurrentProjects": 3,
                },
                request=req,
            )
        return httpx.Response(404, request=req)

    monkeypatch.setattr(httpx.Client, "get", mock_get)

    state = _create_sample_state()
    shortlist = match_designers(state, state.style_profile)

    assert isinstance(shortlist, list)
    assert len(shortlist) == 2
    assert shortlist[0].designer_id == 101
    assert shortlist[1].designer_id == 102
