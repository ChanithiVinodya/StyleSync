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
    style_tags: list[str] = Field(default_factory=list, alias="styleTags")

    model_config = {"populate_by_name": True, "extra": "ignore"}


class MatchScoreBreakdownDto(BaseModel):
    style_tag_overlap_pct: float = Field(default=0.0, alias="styleTagOverlapPct")
    budget_range_overlap_pct: float = Field(default=0.0, alias="budgetRangeOverlapPct")
    past_rating_normalized: float = Field(default=0.0, alias="pastRatingNormalized")
    availability_bonus: float = Field(default=0.0, alias="availabilityBonus")
    match_score: float = Field(default=0.0, alias="matchScore")

    model_config = {"populate_by_name": True, "extra": "ignore"}


class DesignerSearchResultDto(BaseModel):
    designer_id: int | str = Field(alias="designerId")
    match_score: float = Field(alias="matchScore")
    score_breakdown: MatchScoreBreakdownDto = Field(
        default_factory=MatchScoreBreakdownDto, alias="scoreBreakdown"
    )
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
    listing_status: int | str = Field(default=1, alias="listingStatus")
    featured_portfolio_image_url: Optional[str] = Field(default=None, alias="featuredPortfolioImageUrl")

    model_config = {"populate_by_name": True, "extra": "ignore"}


class DesignerAvailabilityResponseDto(BaseModel):
    is_available: bool = Field(alias="isAvailable", default=True)
    is_under_capacity: bool = Field(alias="isUnderCapacity", default=True)
    active_project_count: int = Field(alias="activeProjectCount", default=0)
    max_concurrent_projects: int = Field(alias="maxConcurrentProjects", default=3)

    model_config = {"populate_by_name": True, "extra": "ignore"}


class DesignerMatch(BaseModel):
    designer_id: str | int = Field(alias="designerId", default="")
    designer_name: str = Field(alias="designerName", default="")
    style_match_pct: float = Field(alias="styleMatchPct", default=0.0)
    budget_match: str = Field(alias="budgetMatch", default="Medium")  # "High" | "Medium" | "Low"
    match_score: float = Field(alias="matchScore", default=0.0)
    explanation: str = Field(alias="explanation", default="")
    capacity_available: bool = Field(alias="capacityAvailable", default=True)

    model_config = {"populate_by_name": True, "extra": "ignore"}


class ScopeItem(BaseModel):
    name: Optional[str] = None
    description: str = ""
    category: str = "Other"
    quantity: int = 1
    unit_cost: float = 0.0
    estimated_cost: Optional[float] = None

    def model_post_init(self, __context: Any) -> None:
        if not self.description and self.name:
            self.description = self.name
        if not self.name and self.description:
            self.name = self.description
        if self.estimated_cost is not None and self.unit_cost == 0.0:
            self.unit_cost = self.estimated_cost / (self.quantity if self.quantity > 0 else 1)
        elif self.estimated_cost is None:
            self.estimated_cost = self.unit_cost * self.quantity

    model_config = {"populate_by_name": True, "extra": "ignore"}


class ProjectScope(BaseModel):
    items: list[ScopeItem] = Field(default_factory=list)
    estimated_total: float = 0.0
    scope_summary: Optional[str] = None
    notes: Optional[str] = None


class RuleCheck(BaseModel):
    rule: str
    passed: bool
    errors: list[str] = Field(default_factory=list)


class ValidationResult(BaseModel):
    budget_status: str = "PENDING"     # PASS | FAIL | PENDING
    scope_status: str = "PENDING"
    designer_match_status: str = "PENDING"
    required_data_status: str = "PENDING"
    is_valid: bool = False
    checks: list[RuleCheck] = Field(default_factory=list)
    errors: list[str] = Field(default_factory=list)


class WorkflowState(BaseModel):
    """Mirrors the JSON persisted in PostgreSQL by the ASP.NET Core backend."""

    project_request_id: str | int
    client_id: str | int
    room_type: str
    room_size: float
    budget_min: float
    budget_max: float
    room_photo_url: Optional[str] = None
    description: Optional[str] = None

    # Structured multi-step execution plan
    plan: list[PlanStep] = Field(default_factory=list)

    # Domain outputs from specialist agents
    style_profile: Optional[StyleProfile] = None
    designer_shortlist: list[DesignerMatch] = Field(default_factory=list, alias="designerMatches")
    # "pending" | "success" | "no_eligible_designers"
    matching_status: str = Field(default="pending", alias="matchingStatus")
    project_scope: Optional[ProjectScope] = None
    validation_result: Optional[ValidationResult] = None
    approval_status: str = "Pending"

    # Execution logs & observability
    tool_calls: list[ToolCallRecord] = Field(default_factory=list)
    errors: list[str] = Field(default_factory=list)
    retries: int = 0

    model_config = {"populate_by_name": True, "extra": "ignore"}


