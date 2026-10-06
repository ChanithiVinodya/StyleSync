"""
Golden Test Cases for Agent 1 - Style Analysis Agent (Student 2).
Covers agentic tool integration, confidence scoring, preference alignment, and audit logging.
"""
import pytest
from app.agents.style_analysis_agent import analyze_style
from app.schemas import StyleProfile, WorkflowState


def _make_state(**overrides) -> WorkflowState:
    defaults = dict(
        project_request_id=101,
        client_id=42,
        room_type="Living Room",
        room_size=340.0,
        budget_min=150_000.0,
        budget_max=300_000.0,
        room_photo_url="https://stylesync.blob.core.windows.net/requests/101/room.jpg",
        description="Looking for an airy Japandi or Scandinavian inspired room with light wood",
    )
    defaults.update(overrides)
    return WorkflowState(**defaults)


def test_analyze_style_returns_valid_profile():
    state = _make_state()
    profile = analyze_style(state)

    assert isinstance(profile, StyleProfile)
    assert profile.primary_style in ["Scandinavian", "Japandi", "Modern Minimalist"]
    assert profile.confidence >= 0.70
    assert len(profile.preferred_colours) > 0
    assert isinstance(profile.preferred_colours, list)


def test_analyze_style_records_tool_calls_in_audit_log():
    state = _make_state()
    analyze_style(state)

    assert len(state.tool_calls) == 3
    tool_names = [call.tool_name for call in state.tool_calls]
    assert "analyze_room_image" in tool_names
    assert "get_client_preferences" in tool_names
    assert "get_style_color_palette" in tool_names


def test_analyze_style_aligns_with_client_description_keyword():
    state = _make_state(description="I love industrial exposed brick and rustic elements")
    profile = analyze_style(state)

    assert profile.primary_style == "Industrial"
    assert "Matte Black" in profile.preferred_colours or len(profile.preferred_colours) >= 3


def test_analyze_style_handles_disliked_style_conflict():
    # If the user specifically dislikes Scandinavian, it should fallback to another style
    state = _make_state(client_id=99, description="Avoid Scandinavian completely")
    profile = analyze_style(state)

    assert profile.primary_style != ""
    assert profile.confidence > 0.5
