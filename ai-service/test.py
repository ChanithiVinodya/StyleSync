import traceback
from app.orchestrator import run_workflow
from app.schemas import WorkflowState

try:
    state = WorkflowState(
        project_request_id='00000000-0000-0000-0000-000000000000',
        client_id='00000000-0000-0000-0000-000000000000',
        room_type='LivingRoom',
        room_size=250,
        budget_min=5000,
        budget_max=5000,
        description='Test',
        room_photo_url='http://example.com/photo.jpg'
    )
    run_workflow(state)
except Exception as e:
    traceback.print_exc()
