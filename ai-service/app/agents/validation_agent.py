"""
Agent 4 - Validation Agent
OWNED BY: Student 4 (pairs with the Project Execution & Progress Tracking component)

Responsibility: run FIXED, DETERMINISTIC business-rule checks against the
proposal. This is intentionally NOT another LLM call - the assignment brief
requires validation that isn't "the LLM says it's fine".

See app/schemas.py for the expected ValidationResult output shape.
"""
from app.schemas import DesignerMatch, ProjectScope, ValidationResult, WorkflowState


def validate_proposal(
    state: WorkflowState,
    scope: ProjectScope,
    shortlist: list[DesignerMatch],
) -> ValidationResult:
    """
    TODO (Student 4): implement real deterministic validation here.
    Suggested checks (plain code, no LLM calls):
      - estimated cost must not exceed the client's max budget
      - room size must be > 0
      - at least one shortlisted designer must clear a minimum match score
      - required fields must be present (e.g. style_profile is not None)
      - the cost estimate must actually equal the sum of scope items
    Return a ValidationResult with is_valid=True only if every check passes.
    """
    raise NotImplementedError("Validation Agent has not been implemented yet")
