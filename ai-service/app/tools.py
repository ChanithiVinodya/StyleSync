"""
Allow-listed Tools with Validated Inputs and Structured Outputs.

Provides concrete, callable tools for each specialist agent role in the
StyleSync pipeline. Every tool defines a strict Pydantic input schema for
automatic validation and audit logging.
"""
from __future__ import annotations

from typing import Any

from langchain_core.tools import tool
from pydantic import BaseModel, Field

# ============================================================================
# 1. Style Analysis Tools (Agent 1)
# ============================================================================

class AnalyzeRoomImageInput(BaseModel):
    image_url: str = Field(description="URL or file path of the uploaded room photo")
    room_type: str = Field(description="Room type, e.g., Living Room, Bedroom, Kitchen")


class GetClientPreferencesInput(BaseModel):
    client_id: int = Field(description="Unique ID of the client")


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
def get_client_preferences(client_id: int) -> dict[str, Any]:
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
        "scandinavian": ["Warm White", "Soft Grey", "Light Oak", "Muted Sage"],
        "japandi": ["Sand Beige", "Charcoal", "Natural Cedar", "Off-White"],
        "industrial": ["Matte Black", "Exposed Brick Red", "Concrete Grey", "Cognac Leather"],
        "modern minimalist": ["Pure White", "Charcoal", "Monochrome Slate", "Brushed Steel"],
        "boho chic": ["Terracotta", "Mustard Yellow", "Warm Cream", "Rattan Brown"],
    }
    return palettes.get(
        style_name.strip().lower(),
        ["Warm Neutral", "Soft Grey", "Natural Wood", "Off-White"],
    )


STYLE_ANALYSIS_TOOLS = [analyze_room_image, get_client_preferences, get_style_color_palette]


# ============================================================================
# 2. Designer Matching Tools (Agent 2)
# ============================================================================

class SearchDesignersInput(BaseModel):
    primary_style: str = Field(description="Target interior design style to match")
    budget_max: float = Field(description="Maximum project budget from client")
    min_rating: float = Field(default=4.0, description="Minimum acceptable designer rating (out of 5.0)")


class CheckDesignerAvailabilityInput(BaseModel):
    designer_id: int = Field(description="ID of the designer to check availability for")


class GetDesignerPortfolioInput(BaseModel):
    designer_id: int = Field(description="ID of the designer to inspect portfolio for")


@tool("search_designers", args_schema=SearchDesignersInput)
def search_designers(
    primary_style: str,
    budget_max: float,
    min_rating: float = 4.0,
) -> list[dict[str, Any]]:
    """Searches and scores available designers against style specialty, rating, and budget."""
    catalogue = [
        {
            "designer_id": 101,
            "designer_name": "Elena Rostova",
            "specialties": ["Scandinavian", "Minimalist", "Japandi"],
            "rating": 4.9,
            "min_budget": 120_000.0,
            "max_budget": 300_000.0,
        },
        {
            "designer_id": 102,
            "designer_name": "Marcus Vance",
            "specialties": ["Industrial", "Modern Minimalist", "Loft"],
            "rating": 4.7,
            "min_budget": 150_000.0,
            "max_budget": 450_000.0,
        },
        {
            "designer_id": 103,
            "designer_name": "Aria Chen",
            "specialties": ["Scandinavian", "Boho Chic", "Contemporary"],
            "rating": 4.8,
            "min_budget": 100_000.0,
            "max_budget": 280_000.0,
        },
    ]

    target_style = primary_style.strip().lower()
    matches = []

    for d in catalogue:
        if d["rating"] < min_rating:
            continue

        style_match = 95.0 if any(target_style in s.lower() for s in d["specialties"]) else 70.0
        if d["min_budget"] <= budget_max <= d["max_budget"]:
            budget_match = "High"
        elif budget_max >= d["min_budget"]:
            budget_match = "Medium"
        else:
            budget_match = "Low"

        matches.append({
            "designer_id": d["designer_id"],
            "designer_name": d["designer_name"],
            "style_match_pct": style_match,
            "budget_match": budget_match,
            "rating": d["rating"],
        })

    matches.sort(key=lambda x: (x["style_match_pct"], x["rating"]), reverse=True)
    return matches


@tool("check_designer_availability", args_schema=CheckDesignerAvailabilityInput)
def check_designer_availability(designer_id: int) -> dict[str, Any]:
    """Checks whether a designer currently has bandwidth to accept a new project."""
    return {
        "designer_id": designer_id,
        "is_available": True,
        "current_active_projects": 2,
        "max_concurrent_projects": 4,
        "earliest_start_date": "Immediately",
    }


@tool("get_designer_portfolio", args_schema=GetDesignerPortfolioInput)
def get_designer_portfolio(designer_id: int) -> dict[str, Any]:
    """Retrieves verified portfolio project highlights and client feedback scores."""
    return {
        "designer_id": designer_id,
        "featured_rooms": ["Living Room Makeover - Colombo 07", "Minimalist Master Suite - Kandy"],
        "completed_projects_count": 28,
        "client_satisfaction_score": 98.4,
    }


DESIGNER_MATCHING_TOOLS = [search_designers, check_designer_availability, get_designer_portfolio]


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
