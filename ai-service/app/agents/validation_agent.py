"""
Agent 4 - Validation Agent
OWNED BY: Student 4 (pairs with the Project Execution & Progress Tracking component)

Responsibility: run FIXED, DETERMINISTIC business-rule checks against the
proposal. The LLM acts strictly as a relay to the deterministic `validate` tool.

See app/schemas.py for the expected ValidationResult output shape.
"""
import os
import json
try:
    from langchain_google_genai import ChatGoogleGenerativeAI
except ImportError:
    ChatGoogleGenerativeAI = None
from langchain_core.messages import SystemMessage, HumanMessage

from app.schemas import DesignerMatch, ProjectScope, ValidationResult, RuleCheck, WorkflowState
from app.tools import validate

def validate_proposal(
    state: WorkflowState,
    scope: ProjectScope,
    shortlist: list[DesignerMatch],
) -> ValidationResult:
    """
    Implements the Validation Agent using a strictly constrained LLM.
    The LLM has only one tool (validate) and is instructed to just relay the result.
    """
    # Construct the proposal dictionary for the tool
    proposal_data = {
        "budget_min": state.budget_min,
        "budget_max": state.budget_max,
        "room_type": state.room_type,
        "room_size": state.room_size,
        "estimated_cost": scope.estimated_total if scope else None,
        "project_scope": scope.model_dump() if scope else {},
        "designer_shortlist": [d.model_dump() for d in shortlist] if shortlist else [],
    }

    system_prompt = """You are the StyleSync Validation Agent.

Your only responsibility is to validate the current proposal by calling the validate() tool.

You MUST call validate() exactly once using the complete current proposal provided to you.

You MUST NOT perform validation yourself.

You MUST NOT calculate, interpret, infer, modify, approve, reject, repair, or explain validation results independently.

You MUST NOT call any tool other than validate().

After calling validate(), return exactly the result produced by validate() as a JSON string.

Do not add commentary.
Do not add recommendations.
Do not alter the result.
Do not omit fields.
Do not create additional validation rules.

The validate() tool is the sole authority for determining whether each validation rule passes or fails.
"""

    if ChatGoogleGenerativeAI is not None:
        try:
            llm = ChatGoogleGenerativeAI(
                model="gemini-1.5-pro",
                temperature=0.0,
                api_key=os.getenv("GOOGLE_API_KEY") or os.getenv("GEMINI_API_KEY")
            ).bind_tools([validate], tool_choice="validate")

            messages = [
                SystemMessage(content=system_prompt),
                HumanMessage(content=f"Please validate this proposal: {json.dumps(proposal_data)}")
            ]

            response = llm.invoke(messages)
            tool_call = response.tool_calls[0]
            tool_args = tool_call["args"]
            raw_result = validate.invoke(tool_args)
        except Exception as e:
            raw_result = validate.invoke({"proposal": proposal_data})
    else:
        raw_result = validate.invoke({"proposal": proposal_data})

    # Map raw_result back to our ValidationResult schema
    checks = []
    for c in raw_result.get("checks", []):
        checks.append(RuleCheck(
            rule=c.get("rule", "Unknown"),
            passed=c.get("passed", False),
            errors=c.get("errors", [])
        ))

    return ValidationResult(
        is_valid=raw_result.get("valid", False),
        checks=checks,
        errors=raw_result.get("errors", [])
    )
