from fastapi import APIRouter, HTTPException, status
from agents.style_analysis_agent import StyleAnalysisInput, StyleAnalysisOutput, run_style_analysis_agent

router = APIRouter(prefix="/api/v1/ai", tags=["AI Style Analysis Agent"])

@router.post("/analyze-style", response_model=StyleAnalysisOutput, status_code=status.HTTP_200_OK)
async def analyze_style_endpoint(payload: StyleAnalysisInput):
    """
    Endpoint for Agent 1: Style Analysis Agent.
    Invokes the LangGraph StateGraph pipeline to analyze room photos, dimensions, and text description.
    """
    try:
        result = run_style_analysis_agent(payload)
        return result
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"An error occurred during AI Style Analysis: {str(e)}"
        )
