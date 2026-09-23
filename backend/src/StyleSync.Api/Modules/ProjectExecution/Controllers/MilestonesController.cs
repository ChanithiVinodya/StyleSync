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

    public MilestonesController(IMilestoneService milestoneService)
    {
        _milestoneService = milestoneService;
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
