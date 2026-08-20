"""
Agent 1 - Style Analysis Agent
OWNED BY: Student 2 (pairs with the Project Requests & Room Uploads component)

Responsibility: analyze room photos + client preferences and produce a
structured StyleProfile. Does NOT pick a designer or a budget.

Suggested tools this agent should be allow-listed to use:
  - analyze_room_image()
  - get_client_preferences()
  - get_colour_palette()

See docs/architecture.md and the project PRD for the expected input/output
shape (StyleProfile in app/schemas.py) - don't change that shape without
checking with the team, since the other 3 agents depend on it.
"""
from app.schemas import StyleProfile, WorkflowState


def analyze_style(state: WorkflowState) -> StyleProfile:
    """
    TODO (Student 2): implement real style analysis here.
    This will likely involve:
      - calling a vision-capable LLM with the room photo(s)
      - combining that with the client's stated preferences/description
      - returning a StyleProfile with a genuine confidence score
    """
    raise NotImplementedError("Style Analysis Agent has not been implemented yet")
