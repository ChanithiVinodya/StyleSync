using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StyleSync.Api.DTOs;
using StyleSync.Api.Modules.ProjectExecution.DTOs;
using StyleSync.Api.Modules.ProjectExecution.Interfaces;
using StyleSync.Api.Modules.ProjectExecution.Models;

namespace StyleSync.Api.Modules.ProjectExecution.Controllers;

[ApiController]
[Route("api/[controller]")]
public class MilestonesController : ControllerBase
{
    private readonly IMilestoneService _milestoneService;
    private readonly ITaskService _taskService;
    private readonly IMaterialService _materialService;

    public MilestonesController(IMilestoneService milestoneService, ITaskService taskService, IMaterialService materialService)
    {
        _milestoneService = milestoneService;
        _taskService = taskService;
        _materialService = materialService;
    }

    [HttpPost]
    [Authorize(Roles = "Admin,Designer")]
    [ProducesResponseType(typeof(MilestoneDto), 201)]
    [ProducesResponseType(typeof(ErrorResponse), 400)]
    public async Task<IActionResult> CreateMilestone([FromBody] CreateMilestoneDto request)
    {
        try
        {
            var milestone = await _milestoneService.CreateAsync(request);
            return CreatedAtAction(nameof(GetMilestoneById), new { id = milestone.MilestoneId }, milestone);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new ErrorResponse(400, ex.Message));
        }
    }

    [HttpGet]
    [Authorize(Roles = "Admin,Designer,Client")]
    [ProducesResponseType(typeof(IEnumerable<MilestoneDto>), 200)]
    public async Task<IActionResult> GetAllMilestones([FromQuery] Guid? projectId, [FromQuery] MilestoneStatus? status)
    {
        var milestones = await _milestoneService.GetAllAsync(projectId, status);
        return Ok(milestones);
    }

    [HttpGet("{id:guid}")]
    [Authorize(Roles = "Admin,Designer,Client")]
    [ProducesResponseType(typeof(MilestoneDto), 200)]
    [ProducesResponseType(typeof(ErrorResponse), 404)]
    public async Task<IActionResult> GetMilestoneById(Guid id)
    {
        var milestone = await _milestoneService.GetByIdAsync(id);
        if (milestone == null)
        {
            return NotFound(new ErrorResponse(404, "Milestone not found."));
        }

        return Ok(milestone);
    }

    [HttpGet("{id:guid}/tasks")]
    [Authorize(Roles = "Admin,Designer,Client")]
    [ProducesResponseType(typeof(IEnumerable<TaskDto>), 200)]
    [ProducesResponseType(typeof(ErrorResponse), 404)]
    public async Task<IActionResult> GetTasksForMilestone(Guid id)
    {
        var milestone = await _milestoneService.GetByIdAsync(id);
        if (milestone == null)
        {
            return NotFound(new ErrorResponse(404, "Milestone not found."));
        }

        var tasks = await _taskService.GetAllAsync(id, null);
        return Ok(tasks);
    }

    [HttpGet("{id:guid}/materials")]
    [Authorize(Roles = "Admin,Designer,Client")]
    [ProducesResponseType(typeof(IEnumerable<MaterialDto>), 200)]
    [ProducesResponseType(typeof(ErrorResponse), 404)]
    public async Task<IActionResult> GetMaterialsForMilestone(Guid id)
    {
        var milestone = await _milestoneService.GetByIdAsync(id);
        if (milestone == null)
        {
            return NotFound(new ErrorResponse(404, "Milestone not found."));
        }

        var materials = await _materialService.GetAllAsync(milestoneId: id);
        return Ok(materials);
    }

    [HttpPut("{id:guid}")]
    [Authorize(Roles = "Admin,Designer")]
    [ProducesResponseType(typeof(MilestoneDto), 200)]
    [ProducesResponseType(typeof(ErrorResponse), 400)]
    [ProducesResponseType(typeof(ErrorResponse), 404)]
    public async Task<IActionResult> UpdateMilestone(Guid id, [FromBody] UpdateMilestoneDto request)
    {
        try
        {
            var milestone = await _milestoneService.UpdateAsync(id, request);
            if (milestone == null)
            {
                return NotFound(new ErrorResponse(404, "Milestone not found."));
            }

            return Ok(milestone);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new ErrorResponse(400, ex.Message));
        }
        catch (StyleSync.Api.Modules.ProjectExecution.Exceptions.MaterialCompletionGuardException ex)
        {
            return BadRequest(new
            {
                message = ex.Message,
                milestoneId = ex.MilestoneId,
                incompleteMaterials = ex.IncompleteMaterials
            });
        }
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = "Admin,Designer")]
    [ProducesResponseType(204)]
    [ProducesResponseType(typeof(ErrorResponse), 404)]
    [ProducesResponseType(typeof(ErrorResponse), 409)]
    public async Task<IActionResult> DeleteMilestone(Guid id)
    {
        try
        {
            var deleted = await _milestoneService.DeleteAsync(id);
            if (!deleted)
            {
                return NotFound(new ErrorResponse(404, "Milestone not found."));
            }

            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new ErrorResponse(409, ex.Message));
        }
    }
}
