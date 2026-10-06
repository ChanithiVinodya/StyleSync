"""
Tests for Student 3's Budget/Scope Agent.
Covers deterministic fallback mode, schema validation, and edge cases.
"""
import pytest
from app.agents.budget_scope_agent import (
    BudgetScopeRequest,
    BudgetScopeResponse,
    QuoteItemDraft,
    VALID_CATEGORIES,
    _fallback_estimate,
    run_budget_scope_agent,
)


def test_fallback_estimate_standard_budget():
    """Verify standard midpoint budget split into 4 standard categories."""
    req = BudgetScopeRequest(
        room_type="Living Room",
        room_size_sqft=250.0,
        budget_min=150_000.0,
        budget_max=250_000.0,
        style_profile="Modern",
        style_confidence=0.9,
    )
    result = _fallback_estimate(req)

    assert isinstance(result, BudgetScopeResponse)
    assert result.source == "fallback"
    assert result.within_budget is True
    assert len(result.items) == 4

    categories = {i.category for i in result.items}
    assert categories.issubset(VALID_CATEGORIES)
    assert categories == {"Design", "Labor", "Materials", "Furniture"}

    expected_total = sum(i.unit_cost * i.quantity for i in result.items)
    assert result.estimated_total == expected_total
    # Midpoint of 150k and 250k is 200k
    assert result.estimated_total == pytest.approx(200_000.0, rel=1e-2)


def test_fallback_estimate_zero_budget():
    """When budget is zero, falls back to room size sqft floor rate."""
    req = BudgetScopeRequest(
        room_type="Bedroom",
        room_size_sqft=200.0,
        budget_min=0.0,
        budget_max=0.0,
        style_profile="Minimalist",
    )
    result = _fallback_estimate(req)

    assert result.source == "fallback"
    assert result.estimated_total > 0
    # 200 sqft * 800 = 160,000 floor
    assert result.estimated_total == pytest.approx(160_000.0, rel=1e-2)


def test_run_budget_scope_agent_without_api_key(monkeypatch):
    """Ensure run_budget_scope_agent degrades gracefully to fallback when no API key."""
    monkeypatch.delenv("ANTHROPIC_API_KEY", raising=False)

    req = BudgetScopeRequest(
        room_type="Master Suite",
        room_size_sqft=350.0,
        budget_min=300_000.0,
        budget_max=500_000.0,
        style_profile="Luxury",
    )
    result = run_budget_scope_agent(req)

    assert result.source == "fallback"
    assert "Luxury" in result.scope_summary
    assert result.estimated_total > 0
    assert result.within_budget is True


def test_run_budget_scope_agent_handles_llm_failure(monkeypatch):
    """Ensure that if ANTHROPIC_API_KEY is present but the call throws, fallback is used."""
    monkeypatch.setenv("ANTHROPIC_API_KEY", "dummy-key-for-test")

    def mock_call_llm(req):
        raise RuntimeError("API timeout simulation")

    monkeypatch.setattr("app.agents.budget_scope_agent._call_llm", mock_call_llm)

    req = BudgetScopeRequest(
        room_type="Dining Room",
        room_size_sqft=180.0,
        budget_min=100_000.0,
        budget_max=200_000.0,
        style_profile="Traditional",
    )
    result = run_budget_scope_agent(req)

    assert result.source == "fallback"
    assert result.within_budget is True


def test_budget_scope_fastapi_endpoint():
    """Verify that FastAPI /agents/budget-scope endpoint accepts JSON and returns the draft response."""
    from fastapi.testclient import TestClient
    from app.main import app

    client = TestClient(app)
    payload = {
        "room_type": "Living room",
        "room_size_sqft": 220.0,
        "budget_min": 150000.0,
        "budget_max": 250000.0,
        "style_profile": "Mid Century Modern",
        "style_confidence": 0.85,
        "preferences": "Walnut wood and mustard accents",
    }
    response = client.post("/agents/budget-scope", json=payload)
    assert response.status_code == 200
    data = response.json()

    assert "scope_summary" in data
    assert "items" in data
    assert len(data["items"]) > 0
    assert "estimated_total" in data
    assert "within_budget" in data
    assert "source" in data
    assert data["estimated_total"] == sum(item["unit_cost"] * item["quantity"] for item in data["items"])
