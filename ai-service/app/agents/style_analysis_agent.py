"""
Agent 1 - Style Analysis Agent
OWNED BY: Student 2 (pairs with the Project Requests & Room Uploads component)

Responsibility: analyze room photos + client preferences and produce a
structured StyleProfile. Does NOT pick a designer or a budget.

Allow-listed tools:
  - analyze_room_image
  - get_client_preferences
  - get_style_color_palette
"""
from __future__ import annotations

import logging
from typing import Any

from app.schemas import StyleProfile, ToolCallRecord, WorkflowState
from app.tools import analyze_room_image, get_client_preferences, get_style_color_palette

logger = logging.getLogger("stylesync.agents.style_analysis")


def _record_tool_call(state: WorkflowState, tool_name: str, inputs: dict[str, Any], outputs: Any) -> None:
    """Records an executed tool invocation into the state's audit trail."""
    record = ToolCallRecord(
        tool_name=tool_name,
        inputs=inputs,
        outputs=outputs,
    )
    state.tool_calls.append(record)


def analyze_style(state: WorkflowState) -> StyleProfile:
    """
    Analyzes room photo cues, client preferences, and room characteristics
    to derive a deterministic and grounded interior design StyleProfile.
    """
    logger.info("Executing Style Analysis Agent for Request ID %s", state.project_request_id)

    # 1. Image analysis via allow-listed tool
    image_url = state.room_photo_url or f"requests/{state.project_request_id}/room.jpg"
    image_inputs = {"image_url": image_url, "room_type": state.room_type}
    try:
        image_result = analyze_room_image.invoke(image_inputs)
    except Exception:
        # Fallback if invoked directly
        image_result = analyze_room_image(image_url, state.room_type)
    _record_tool_call(state, "analyze_room_image", image_inputs, image_result)

    # 2. Client preferences via allow-listed tool
    client_inputs = {"client_id": state.client_id}
    try:
        client_prefs = get_client_preferences.invoke(client_inputs)
    except Exception:
        client_prefs = get_client_preferences(state.client_id)
    _record_tool_call(state, "get_client_preferences", client_inputs, client_prefs)

    # 3. Style synthesis
    suggested_primary = image_result.get("suggested_primary_style", "Scandinavian")
    suggested_secondary = image_result.get("suggested_secondary_style", "Modern Minimalist")
    favorite_styles = [s.lower() for s in client_prefs.get("favorite_styles", [])]
    disliked_styles = [s.lower() for s in client_prefs.get("disliked_styles", [])]

    # Description keyword matching if provided
    desc_lower = (state.description or "").lower()
    keywords_to_style = {
        "scandinavian": "Scandinavian",
        "japandi": "Japandi",
        "industrial": "Industrial",
        "minimalist": "Modern Minimalist",
        "modern": "Modern Minimalist",
        "boho": "Boho Chic",
        "bohemian": "Boho Chic",
    }
    desc_detected_style = None
    for kw, style_name in keywords_to_style.items():
        if kw in desc_lower:
            desc_detected_style = style_name
            break

    # Determine primary style
    primary_style = suggested_primary
    confidence = 0.85

    if desc_detected_style and desc_detected_style.lower() not in disliked_styles:
        primary_style = desc_detected_style
        confidence += 0.05

    if primary_style.lower() in favorite_styles:
        confidence += 0.05
    elif primary_style.lower() in disliked_styles:
        # Conflict: client dislikes detected style -> fallback to top favorite or secondary
        primary_style = next(
            (s.title() for s in client_prefs.get("favorite_styles", []) if s.lower() not in disliked_styles),
            suggested_secondary,
        )
        confidence = 0.72

    confidence = min(0.98, max(0.50, round(confidence, 2)))

    # Determine secondary style
    secondary_style = suggested_secondary
    if secondary_style.lower() == primary_style.lower() or secondary_style.lower() in disliked_styles:
        secondary_style = next(
            (s.title() for s in client_prefs.get("favorite_styles", []) if s.lower() != primary_style.lower()),
            None,
        )

    # 4. Color palette retrieval via allow-listed tool
    palette_inputs = {"style_name": primary_style}
    try:
        palette_result = get_style_color_palette.invoke(palette_inputs)
    except Exception:
        palette_result = get_style_color_palette(primary_style)
    _record_tool_call(state, "get_style_color_palette", palette_inputs, palette_result)

    profile = StyleProfile(
        primary_style=primary_style,
        secondary_style=secondary_style,
        preferred_colours=palette_result,
        confidence=confidence,
    )

    logger.info("Style Profile derived: %s (Confidence: %.2f)", profile.primary_style, profile.confidence)
    return profile
