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


def test_orchestrator_raises_until_agents_are_implemented():
    """
    Each agent currently raises NotImplementedError - this is expected.
    Once your agent is done, add a real test for YOUR agent in a new file,
    e.g. tests/test_style_analysis_agent.py, rather than editing this one.
    """
    from app.orchestrator import run_workflow

    try:
        run_workflow(_sample_state())
        assert False, "Expected NotImplementedError - has an agent been implemented?"
    except NotImplementedError:
        pass
