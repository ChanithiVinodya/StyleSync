"""
Shared data contracts for the agent pipeline.

This is a SHARED FILE. Extend it carefully - it's the "handshake" every
agent reads from and writes to. If you need a field that's specific to
your agent, add it here with a sensible default so other agents/tests
don't break.
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Optional

from pydantic import BaseModel, Field


class PlanStep(BaseModel):
    step_name: str
    assigned_agent: str
    status: str = "PENDING"  # PENDING | IN_PROGRESS | COMPLETED | FAILED
    result: Optional[str] = None


class ToolCallRecord(BaseModel):
    tool_name: str
    inputs: dict[str, Any] = Field(default_factory=dict)
    outputs: Optional[Any] = None
    timestamp: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())


class StyleProfile(BaseModel):
    primary_style: str
    secondary_style: Optional[str] = None
    preferred_colours: list[str] = Field(default_factory=list)
    confidence: float = 0.0


class DesignerMatch(BaseModel):
    designer_id: int
    designer_name: str
    style_match_pct: float
    budget_match: str  # "High" | "Medium" | "Low"


class ScopeItem(BaseModel):
    name: str
    estimated_cost: float


class ProjectScope(BaseModel):
    items: list[ScopeItem] = Field(default_factory=list)
    estimated_total: float = 0.0


class ValidationResult(BaseModel):
    budget_status: str = "PENDING"     # PASS | FAIL | PENDING
    scope_status: str = "PENDING"
    designer_match_status: str = "PENDING"
    required_data_status: str = "PENDING"
    is_valid: bool = False
    errors: list[str] = Field(default_factory=list)


class WorkflowState(BaseModel):
    """Mirrors the JSON persisted in PostgreSQL by the ASP.NET Core backend."""

    project_request_id: int
    client_id: int
    room_type: str
    room_size: float
    budget_min: float
    budget_max: float

    # Structured multi-step execution plan
    plan: list[PlanStep] = Field(default_factory=list)

    # Domain outputs from specialist agents
    style_profile: Optional[StyleProfile] = None
    designer_shortlist: list[DesignerMatch] = Field(default_factory=list)
    project_scope: Optional[ProjectScope] = None
    validation_result: Optional[ValidationResult] = None
    approval_status: str = "Pending"

    # Execution logs & observability
    tool_calls: list[ToolCallRecord] = Field(default_factory=list)
    errors: list[str] = Field(default_factory=list)
    retries: int = 0

