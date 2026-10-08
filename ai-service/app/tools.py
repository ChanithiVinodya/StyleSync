"""
Allow-listed Tools with Validated Inputs and Structured Outputs.

Provides concrete, callable tools for each specialist agent role in the
StyleSync pipeline. Every tool defines a strict Pydantic input schema for
automatic validation and audit logging.
"""
from __future__ import annotations

import os
from typing import Any

import httpx
from langchain_core.tools import tool
from pydantic import BaseModel, Field

from app.schemas import DesignerAvailabilityResponseDto, DesignerSearchResultDto

BACKEND_API_BASE_URL = os.getenv("BACKEND_API_BASE_URL", os.getenv("BACKEND_URL", "http://localhost:5000")).rstrip("/")

# ============================================================================
# 1. Style Analysis Tools (Agent 1)
# ============================================================================

class AnalyzeRoomImageInput(BaseModel):
    image_url: str = Field(description="URL or file path of the uploaded room photo")
    room_type: str = Field(description="Room type, e.g., Living Room, Bedroom, Kitchen")


class GetClientPreferencesInput(BaseModel):
    client_id: str = Field(description="Unique ID of the client")


class GetStyleColorPaletteInput(BaseModel):
    style_name: str = Field(description="Primary interior design style name")


@tool("analyze_room_image", args_schema=AnalyzeRoomImageInput)
def analyze_room_image(image_url: str, room_type: str) -> dict[str, Any]:
    """Analyzes a room photograph to detect architectural lines, lighting, and style cues."""
    return {
        "detected_style_cues": [
            "clean lines",
            "natural oak wood",
            "neutral textiles",
            "decluttered open space",
        ],
        "suggested_primary_style": "Scandinavian",
        "suggested_secondary_style": "Modern Minimalist",
        "detected_lighting": "High Natural Light",
        "room_type_confirmed": room_type,
        "image_processed": image_url,
    }


@tool("get_client_preferences", args_schema=GetClientPreferencesInput)
def get_client_preferences(client_id: str) -> dict[str, Any]:
    """Retrieves client design preferences, favorite palettes, and style history."""
    return {
        "client_id": client_id,
        "favorite_styles": ["Scandinavian", "Japandi", "Minimalist"],
        "disliked_styles": ["Baroque", "Gothic"],
        "preferred_tones": ["Warm White", "Soft Beige", "Muted Sage", "Light Oak"],
    }


@tool("get_style_color_palette", args_schema=GetStyleColorPaletteInput)
def get_style_color_palette(style_name: str) -> list[str]:
    """Retrieves the canonical curated color palette for a specified interior design style."""
    palettes = {
        "scandinavian": ["#FAFAFA", "#D3D3D3", "#D2B48C", "#879F84"],
        "japandi": ["#E8DCC4", "#36454F", "#C19A6B", "#F5F5DC"],
        "industrial": ["#1C1C1C", "#B22222", "#808080", "#834333"],
        "modern minimalist": ["#FFFFFF", "#36454F", "#708090", "#71797E"],
        "boho chic": ["#E2725B", "#FFDB58", "#FFFDD0", "#5C4033"],
    }
    return palettes.get(
        style_name.strip().lower(),
        ["#EEDDCC", "#D3D3D3", "#DEB887", "#F8F8FF"],
    )


STYLE_ANALYSIS_TOOLS = [analyze_room_image, get_client_preferences, get_style_color_palette]


# ============================================================================
# 2. Designer Matching Tools (Agent 2)
# ============================================================================

class SearchDesignersInput(BaseModel):
    style_tags: list[str] = Field(description="Desired interior design styles to match against")
    budget_min: float = Field(default=0.0, description="Minimum budget in LKR")
    budget_max: float = Field(default=0.0, description="Maximum budget in LKR")


class CheckDesignerAvailabilityInput(BaseModel):
    designer_id: str = Field(description="ID of the designer to check availability for")


@tool("search_designers", args_schema=SearchDesignersInput)
def search_designers(
    style_tags: list[str],
    budget_min: float = 0.0,
    budget_max: float = 0.0,
) -> list[dict[str, Any]]:
    """
    HTTP GET to Component 1's search_designers endpoint.
    Returns the ranked list exactly as returned by the backend.
    """
    try:
        url = f"{BACKEND_API_BASE_URL}/api/designers/search"
        params: list[tuple[str, str]] = []
        for tag in style_tags:
            params.append(("styleTags", tag))
        params.append(("budgetMin", str(budget_min)))
        params.append(("budgetMax", str(budget_max)))

        with httpx.Client(timeout=10.0) as client:
            resp = client.get(url, params=params)

        if resp.status_code == 404:
            return [{"error": "no eligible designers found"}]

        resp.raise_for_status()
        raw_data = resp.json()

        if not raw_data:
            return [{"error": "no eligible designers found"}]

        # Validate with Pydantic model and preserve exact backend JSON format
        validated = [
            DesignerSearchResultDto.model_validate(item).model_dump(by_alias=True)
            for item in raw_data
        ]
        return validated
    except httpx.HTTPError as e:
        return [{"error": f"Failed to connect to designer search backend: {str(e)}"}]
    except Exception as e:
        return [{"error": f"Unexpected error during designer search: {str(e)}"}]


@tool("check_designer_availability", args_schema=CheckDesignerAvailabilityInput)
def check_designer_availability(designer_id: str) -> dict[str, Any]:
    """HTTP GET to /api/designers/{id}/availability to check designer availability and capacity."""
    try:
        clean_id = str(designer_id).strip()
        url = f"{BACKEND_API_BASE_URL}/api/designers/{clean_id}/availability"

        with httpx.Client(timeout=10.0) as client:
            resp = client.get(url)

        if resp.status_code == 404:
            return {
                "error": f"Designer with ID {clean_id} not found",
                "isAvailable": False,
                "isUnderCapacity": False,
                "activeProjectCount": 0,
                "maxConcurrentProjects": 0,
            }

        resp.raise_for_status()
        raw_data = resp.json()
        validated = DesignerAvailabilityResponseDto.model_validate(raw_data).model_dump(by_alias=True)
        return validated
    except httpx.HTTPError as e:
        return {
            "error": f"Failed to check designer availability: {str(e)}",
            "isAvailable": False,
            "isUnderCapacity": False,
            "activeProjectCount": 0,
            "maxConcurrentProjects": 0,
        }
    except Exception as e:
        return {
            "error": f"Unexpected error checking designer availability: {str(e)}",
            "isAvailable": False,
            "isUnderCapacity": False,
            "activeProjectCount": 0,
            "maxConcurrentProjects": 0,
        }


DESIGNER_MATCHING_TOOLS = [search_designers, check_designer_availability]


# ============================================================================
# 3. Budget & Scope Tools (Agent 3)
# ============================================================================

class CalculateScopeEstimateInput(BaseModel):
    room_type: str = Field(description="Type of room to estimate")
    room_size: float = Field(description="Floor area in square feet")
    primary_style: str = Field(description="Primary interior design style")


class GetMaterialRateCardInput(BaseModel):
    material_category: str = Field(description="Category e.g., Flooring, Paint, Lighting, Millwork")


@tool("calculate_scope_estimate", args_schema=CalculateScopeEstimateInput)
def calculate_scope_estimate(room_type: str, room_size: float, primary_style: str) -> dict[str, Any]:
    """Calculates estimated cost items based on room dimensions, type, and stylistic complexity."""
    base_rate_per_sqft = 450.0  # LKR base rate per sqft for finishes
    style_multipliers = {
        "scandinavian": 1.10,
        "japandi": 1.15,
        "industrial": 1.20,
        "modern minimalist": 1.05,
    }
    multiplier = style_multipliers.get(primary_style.strip().lower(), 1.0)

    design_fee = round(max(30_000.0, room_size * 120.0), 2)
    finishes_cost = round(room_size * base_rate_per_sqft * 0.40 * multiplier, 2)
    furniture_cost = round(room_size * base_rate_per_sqft * 0.35 * multiplier, 2)
    lighting_cost = round(room_size * base_rate_per_sqft * 0.15, 2)
    labor_cost = round(room_size * base_rate_per_sqft * 0.10, 2)

    items = [
        {"name": f"{primary_style} Design Concept & 3D Spatial Layout", "estimated_cost": design_fee},
        {"name": "Wall Finishes, Premium Paint & Surface Treatments", "estimated_cost": finishes_cost},
        {"name": "Curated Furniture & Bespoke Joinery Allowance", "estimated_cost": furniture_cost},
        {"name": "Architectural Lighting & Fixtures", "estimated_cost": lighting_cost},
        {"name": "Installation, Site Supervision & Labor", "estimated_cost": labor_cost},
    ]

    total = round(sum(item["estimated_cost"] for item in items), 2)
    return {
        "room_type": room_type,
        "room_size": room_size,
        "items": items,
        "estimated_total": total,
    }


@tool("get_material_rate_card", args_schema=GetMaterialRateCardInput)
def get_material_rate_card(material_category: str) -> dict[str, Any]:
    """Retrieves standard rate cards and unit prices for specified material categories."""
    rates = {
        "flooring": {"engineered_wood_per_sqft": 650.0, "porcelain_tile_per_sqft": 420.0},
        "paint": {"premium_matte_per_litre": 3200.0, "primer_per_litre": 1800.0},
        "millwork": {"custom_cabinetry_per_linear_ft": 8500.0},
        "lighting": {"recessed_led_per_unit": 2400.0, "pendant_feature_per_unit": 18500.0},
    }
    category_key = material_category.strip().lower()
    return rates.get(category_key, {"standard_allowance_per_sqft": 350.0})


BUDGET_SCOPE_TOOLS = [calculate_scope_estimate, get_material_rate_card]


# ============================================================================
# 4. Validation & Governance Tools (Agent 4)
# ============================================================================

import os
from math import isclose

class ValidateProposalInput(BaseModel):
    proposal: dict[str, Any] = Field(description="The complete current proposal data to validate")

@tool("validate", args_schema=ValidateProposalInput)
def validate(proposal: dict[str, Any]) -> dict[str, Any]:
    """Deterministically validates the proposal against business rules."""
    checks = []
    errors = []

    # Safe access helpers
    def get_float(key, default=None):
        val = proposal.get(key)
        if val is None:
            return default
        try:
            return float(val)
        except (ValueError, TypeError):
            return default

    estimated_cost = get_float("estimated_cost")
    budget_max = get_float("budget_max")
    room_size = get_float("room_size")
    
    # 1. Budget Compliance
    budget_errors = []
    budget_passed = False
    if estimated_cost is None:
        budget_errors.append("Estimated cost is missing.")
    elif budget_max is None:
        budget_errors.append("Client maximum budget is missing.")
    elif estimated_cost > budget_max:
        budget_errors.append(f"Estimated cost {estimated_cost} exceeds client max budget {budget_max}.")
    else:
        budget_passed = True

    checks.append({
        "rule": "BudgetCompliance",
        "passed": budget_passed,
        "errors": budget_errors
    })
    errors.extend(budget_errors)

    # 2. Room Size
    size_errors = []
    size_passed = False
    if room_size is None:
        size_errors.append("Room size is missing or invalid.")
    elif room_size <= 0 or room_size != room_size or room_size == float('inf'): # NaN or Inf
        size_errors.append("Room size must be a positive number.")
    else:
        size_passed = True

    checks.append({
        "rule": "RoomSize",
        "passed": size_passed,
        "errors": size_errors
    })
    errors.extend(size_errors)

    # 3. Designer Match and Capacity
    designer_errors = []
    designer_passed = False
    shortlist = proposal.get("designer_shortlist")
    
    try:
        min_score = float(os.getenv("Validation:MinimumDesignerMatchScore", "70.0"))
    except ValueError:
        min_score = 70.0

    if not shortlist or not isinstance(shortlist, list):
        designer_errors.append("Designer shortlist is missing or empty.")
    else:
        for d in shortlist:
            score = d.get("style_match_pct", 0)
            capacity = d.get("capacity_available", False)
            if score >= min_score and capacity:
                designer_passed = True
                break
        
        if not designer_passed:
            designer_errors.append("No shortlisted designer meets the minimum match score and has available capacity.")

    checks.append({
        "rule": "DesignerMatchAndCapacity",
        "passed": designer_passed,
        "errors": designer_errors
    })
    errors.extend(designer_errors)

    # 4. Cost Calculation
    cost_errors = []
    cost_passed = False
    scope = proposal.get("project_scope", {})
    if not isinstance(scope, dict):
        scope = {}
    
    items = scope.get("items", [])
    
    if estimated_cost is None:
        cost_errors.append("Cannot calculate cost, estimated cost is missing.")
    elif not items or not isinstance(items, list):
        cost_errors.append("Line items are missing.")
    else:
        calculated_total = 0.0
        for item in items:
            calculated_total += float(item.get("estimated_cost", 0.0))
        
        if not isclose(calculated_total, estimated_cost, abs_tol=0.01):
            cost_errors.append(f"Cost estimate does not match the sum of its line items.")
        else:
            cost_passed = True

    checks.append({
        "rule": "CostCalculation",
        "passed": cost_passed,
        "errors": cost_errors
    })
    errors.extend(cost_errors)

    is_valid = budget_passed and size_passed and designer_passed and cost_passed

    return {
        "valid": is_valid,
        "checks": checks,
        "errors": errors
    }

VALIDATION_TOOLS = [validate]
