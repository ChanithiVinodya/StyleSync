"""
Agent 3 - Budget/Scope Agent
OWNED BY: Student 3 (pairs with the Quotes & Contracts component)

Responsibility: draft a project scope and cost estimate. Produces an
ESTIMATE, not a binding quotation.

Suggested tools this agent should be allow-listed to use:
  - get_room_details()
  - get_material_prices()
  - calculate_estimate()
  - get_design_service_rates()

See app/schemas.py for the expected ProjectScope / ScopeItem output shape.
"""
from app.schemas import ProjectScope, StyleProfile, WorkflowState


def build_scope(state: WorkflowState, style_profile: StyleProfile) -> ProjectScope:
    """
    TODO (Student 3): implement real scope/estimate drafting here.
    This will likely involve:
      - using room size, room type, requested changes, and style
      - pricing out line items (design fee, materials, labour, etc.)
      - returning a ProjectScope where estimated_total equals the sum
        of your ScopeItem costs (the Validation Agent checks this)
    """
    raise NotImplementedError("Budget/Scope Agent has not been implemented yet")
