import pytest
import httpx
from app.orchestrator import run_workflow
from app.schemas import WorkflowState

def _sample_state(**overrides) -> WorkflowState:
    defaults = dict(
        project_request_id=102,
        client_id=25,
        room_type="Living Room",
        room_size=200,
        budget_min=100_000,
        budget_max=600_000,
    )
    defaults.update(overrides)
    return WorkflowState(**defaults)

def test_tc_ai_12_valid_request_drives_graph_to_awaiting_approval(monkeypatch):
    """
    Category: Task completion
    Test case: TC-AI-12
    What is verified: A valid request drives the graph to the awaiting-approval state with a proposal
    """
    # 1. Mock the Designer Matching backend endpoints to ensure predictable valid data
    search_fixtures = [{
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
    }]

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

    # Disable LLM calls to force fast, deterministic fallback execution 
    monkeypatch.delenv("OPENAI_API_KEY", raising=False)
    monkeypatch.delenv("ANTHROPIC_API_KEY", raising=False)

    # 2. Provide a valid input state
    state = _sample_state(
        room_type="Living Room",
        room_size=200,
        budget_min=150_000,
        budget_max=600_000,
    )
    
    # 3. Run orchestrator
    result = run_workflow(state)

    # 4. Assert TC-AI-12 Conditions: 
    # Because it is valid, the graph hits the Human-in-the-Loop interrupt and pauses!
    from app.orchestrator import get_compiled_graph
    graph = get_compiled_graph()
    config = {"configurable": {"thread_id": f"project-request-{state.project_request_id}"}}
    
    graph_state = graph.get_state(config)
    
    # Verify it is paused waiting for approval
    assert len(graph_state.tasks) > 0
    assert len(graph_state.tasks[0].interrupts) > 0
    interrupt_data = graph_state.tasks[0].interrupts[0].value
    assert interrupt_data["action"] == "client_approval_required"
    
    # Now let's resume it by giving an approval decision
    final_state = run_workflow(state, resume_decision="approved")
    
    # NOW the validation_result is returned and applied to the state
    assert final_state.validation_result is not None
    assert final_state.validation_result.is_valid is True
    assert final_state.approval_status == "Approved"
