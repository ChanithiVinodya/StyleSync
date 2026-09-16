import pytest
import sys
import os

# Add parent directory to path for test imports
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from agents.style_analysis_agent import StyleAnalysisInput, run_style_analysis_agent, SUPPORTED_STYLES

def test_style_analysis_agent_basic_execution():
    input_data = StyleAnalysisInput(
        project_request_id="11111111-1111-1111-1111-111111111111",
        room_type="Bedroom",
        preferred_styles=["Modern", "Minimalist"],
        description="I want a simple room. I like white and light brown colours.",
        photo_urls=["https://example.com/room1.jpg"]
    )

    output = run_style_analysis_agent(input_data)

    assert output.primary_style in SUPPORTED_STYLES
    assert output.primary_style == "Modern"
    assert output.secondary_style == "Minimalist"
    assert output.confidence_score >= 80.0
    assert len(output.recommended_colors) > 0
    assert len(output.detected_features) > 0
    assert "Modern" in output.analysis_summary
    assert output.concept_render_url.startswith("http")

def test_style_analysis_agent_description_keyword_override():
    input_data = StyleAnalysisInput(
        project_request_id="22222222-2222-2222-2222-222222222222",
        room_type="Living Room",
        preferred_styles=[],
        description="Exposed brick wall with raw timber beams and dark metal frames.",
        photo_urls=[]
    )

    output = run_style_analysis_agent(input_data)

    assert output.primary_style == "Industrial"
    assert output.confidence_score >= 80.0
    assert any("Brick" in c or "Concrete" in c or "Metal" in c or "Steel" in c for c in output.recommended_colors + output.detected_features)
    assert output.concept_render_url.startswith("http")

def test_style_analysis_agent_dynamic_outputs():
    input1 = StyleAnalysisInput(
        project_request_id="33333333-3333-3333-3333-333333333333",
        room_type="Kitchen",
        preferred_styles=["Luxury", "Traditional"],
        description="Gold fittings and marble countertops with navy cabinets",
        photo_urls=["https://example.com/k1.jpg", "https://example.com/k2.jpg"]
    )
    input2 = StyleAnalysisInput(
        project_request_id="44444444-4444-4444-4444-444444444444",
        room_type="Bedroom",
        preferred_styles=["Mid Century Modern"],
        description="Teak wood furniture",
        photo_urls=[]
    )

    out1 = run_style_analysis_agent(input1)
    out2 = run_style_analysis_agent(input2)

    assert out1.primary_style == "Luxury"
    assert out1.secondary_style == "Traditional"
    assert out2.primary_style == "Mid Century Modern"
    assert out1.concept_render_url.startswith("http")
    assert out2.concept_render_url.startswith("http")

    # Verify confidence scores are dynamic and distinct
    assert out1.confidence_score != out2.confidence_score
    assert out1.confidence_score != 89.5
    assert out2.confidence_score != 89.5
    assert out1.confidence_score != 91.0
    assert out2.confidence_score != 91.0

def test_style_analysis_agent_concept_render_url_generated_for_all_styles():
    """Node 2 (generate_concept_render_node): Verifies concept_render_url is generated
    and returned as part of the final unified JSON payload for every supported style.
    Validates the complete 3-node pipeline: analyze_features → generate_concept_render → format_output."""
    from agents.style_analysis_agent import STYLE_CONCEPT_RENDERS

    for style in SUPPORTED_STYLES:
        input_data = StyleAnalysisInput(
            project_request_id=f"66666666-6666-6666-6666-6666{style[:8].replace(' ', '0').lower()[:8]}",
            room_type="Living Room",
            preferred_styles=[style],
            description=f"I want a {style.lower()} style room.",
            photo_urls=["https://example.com/room.jpg"]
        )
        output = run_style_analysis_agent(input_data)

        # Node 2 assertion: concept_render_url must be present in unified output
        assert output.concept_render_url is not None, \
            f"concept_render_url is None for style: {style}"
        assert output.concept_render_url.startswith("http"), \
            f"concept_render_url must be a valid HTTP URL for style: {style}"
        expected_url = STYLE_CONCEPT_RENDERS.get(style, STYLE_CONCEPT_RENDERS["Modern"])
        assert output.concept_render_url == expected_url, \
            f"concept_render_url mismatch for style {style}: expected {expected_url}, got {output.concept_render_url}"
        assert len(output.concept_render_url) > 20, \
            f"concept_render_url is too short to be valid for style: {style}"

