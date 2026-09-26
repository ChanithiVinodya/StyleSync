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


class MatchScoreBreakdownDto(BaseModel):
    style_tag_overlap_pct: float = Field(default=0.0, alias="styleTagOverlapPct")
    budget_range_overlap_pct: float = Field(default=0.0, alias="budgetRangeOverlapPct")
    past_rating_normalized: float = Field(default=0.0, alias="pastRatingNormalized")
    availability_bonus: float = Field(default=0.0, alias="availabilityBonus")
    match_score: float = Field(default=0.0, alias="matchScore")

    model_config = {"populate_by_name": True, "extra": "ignore"}


class DesignerSearchResultDto(BaseModel):
    designer_id: int = Field(alias="designerId")
    match_score: float = Field(alias="matchScore")
    score_breakdown: MatchScoreBreakdownDto = Field(default_factory=MatchScoreBreakdownDto, alias="scoreBreakdown")
    display_name: str = Field(alias="displayName")
    bio: str = Field(default="", alias="bio")
    style_tags: list[str] = Field(default_factory=list, alias="styleTags")
    service_categories: list[str] = Field(default_factory=list, alias="serviceCategories")
    price_range_min: float = Field(default=0.0, alias="priceRangeMin")
    price_range_max: float = Field(default=0.0, alias="priceRangeMax")
    rate_per_sq_ft: float = Field(default=0.0, alias="ratePerSqFt")
    is_available: bool = Field(default=True, alias="isAvailable")
    max_concurrent_projects: int = Field(default=3, alias="maxConcurrentProjects")
    active_project_count: int = Field(default=0, alias="activeProjectCount")
    remaining_capacity: int = Field(default=0, alias="remainingCapacity")
    is_under_capacity: bool = Field(default=True, alias="isUnderCapacity")
    average_rating: Optional[float] = Field(default=None, alias="averageRating")
    listing_status: int = Field(default=1, alias="listingStatus")
    featured_portfolio_image_url: Optional[str] = Field(default=None, alias="featuredPortfolioImageUrl")

    model_config = {"populate_by_name": True, "extra": "ignore"}


class DesignerAvailabilityResponseDto(BaseModel):
    is_available: bool = Field(alias="isAvailable")
    is_under_capacity: bool = Field(alias="isUnderCapacity")
    active_project_count: int = Field(alias="activeProjectCount")
    max_concurrent_projects: int = Field(alias="maxConcurrentProjects")

    model_config = {"populate_by_name": True, "extra": "ignore"}


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

