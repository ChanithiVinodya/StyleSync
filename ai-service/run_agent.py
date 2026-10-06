"""
Direct CLI runner for Agent 1 - Style Analysis Agent (Student 2).
Run with:
    python run_agent.py
"""
import json
from app.agents.style_analysis_agent import analyze_style
from app.schemas import WorkflowState


def main():
    print("=" * 60)
    print(" StyleSync - Agent 1: Style Analysis Agent (Student 2)")
    print("=" * 60)

    # Sample input request
    sample_state = WorkflowState(
        project_request_id=101,
        client_id=1,
        room_type="Kitchen",
        room_size=340.0,
        budget_min=200_000.0,
        budget_max=300_000.0,
        room_photo_url="requests/101/room.jpg",
        description="Looking for modern minimalist or Scandinavian style with light oak wood",
    )

    print("\n[1] Input State:")
    print(f"  - Request ID: {sample_state.project_request_id}")
    print(f"  - Room Type:  {sample_state.room_type} ({sample_state.room_size} sq ft)")
    print(f"  - Budget:     LKR {sample_state.budget_min:,.0f} - {sample_state.budget_max:,.0f}")
    print(f"  - Description:{sample_state.description}")

    print("\n[2] Executing Style Analysis Agent...")
    profile = analyze_style(sample_state)

    print("\n[3] Agent 1 Output (StyleProfile):")
    print(f"  - Primary Style:     {profile.primary_style}")
    print(f"  - Secondary Style:   {profile.secondary_style}")
    print(f"  - Preferred Colours: {', '.join(profile.preferred_colours)}")
    print(f"  - Confidence Score:  {profile.confidence * 100:.1f}%")

    print("\n[4] Tool Call Audit Trail:")
    for i, call in enumerate(sample_state.tool_calls, 1):
        print(f"  {i}. Tool: {call.tool_name}")
        print(f"     Inputs:  {json.dumps(call.inputs)}")
        print(f"     Outputs: {json.dumps(call.outputs)}")

    print("\n" + "=" * 60)
    print(" Agent 1 Execution Complete!")
    print("=" * 60)


if __name__ == "__main__":
    main()
