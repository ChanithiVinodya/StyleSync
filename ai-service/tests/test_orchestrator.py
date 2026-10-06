"""
Placeholder tests for the AI service.

Once your agent is implemented, replace/extend these with real tests for
your agent specifically (see docs/setup/ai-service.md - "golden test
cases" are required by the assignment brief). This file currently only
proves the schemas and orchestrator wiring import correctly.
"""
from app.schemas import WorkflowState


def _sample_state(**overrides) -> WorkflowState:
    defaults = dict(
        project_request_id=102,
        client_id=25,
        room_type="Living Room",
        room_size=250,
        budget_min=150_000,
        budget_max=250_000,
    )
    defaults.update(overrides)
    return WorkflowState(**defaults)


def test_workflow_state_can_be_constructed():
    """Sanity check that the shared schema is valid and importable."""
    state = _sample_state()
    assert state.room_type == "Living Room"
    assert state.approval_status == "Pending"


def test_orchestrator_runs_full_workflow(monkeypatch):
    """
    Tests that the orchestrator coordinates all 4 agents into an enriched WorkflowState.
    """
    import httpx
    from app.orchestrator import run_workflow

    search_fixtures = [
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
        }
    ]

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

    state = _sample_state(
        room_type="Living Room",
        room_size=200,
        budget_min=100_000,
        budget_max=600_000,
    )
    result = run_workflow(state)
    assert result.style_profile is not None
    assert result.style_profile.primary_style is not None
    assert result.designer_shortlist is not None
    assert len(result.designer_shortlist) > 0
    assert result.project_scope is not None
    assert result.validation_result is not None
    assert len(result.plan) == 4
