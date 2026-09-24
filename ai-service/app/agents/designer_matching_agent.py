"""
Agent 2 - Designer-Matching Agent
OWNED BY: Student 1 (pairs with the Designer Portfolios & Listings component)

Responsibility: shortlist designers using the style profile, budget,
expertise, and availability. Only recommends - never auto-assigns.

Suggested tools this agent should be allow-listed to use:
  - search_designers()
  - search_portfolios()
  - get_designer_rating()
  - check_designer_budget_range()
  - check_designer_availability()

See app/schemas.py for the expected DesignerMatch output shape.
"""
from app.schemas import DesignerMatch, StyleProfile, WorkflowState


def match_designers(state: WorkflowState, style_profile: StyleProfile) -> list[DesignerMatch]:
    """
    TODO (Student 1): implement real designer matching here.
    This will likely involve:
      - querying your Designers module's data (via an internal API call
        back to ASP.NET Core, or a shared read model)
      - scoring designers on style fit, budget fit, availability, ratings
      - returning a ranked list of DesignerMatch objects
    """
    raise NotImplementedError("Designer-Matching Agent has not been implemented yet")
