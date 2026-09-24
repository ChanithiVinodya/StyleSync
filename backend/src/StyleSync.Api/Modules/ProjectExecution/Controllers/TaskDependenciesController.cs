using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StyleSync.Api.DTOs;
using StyleSync.Api.Modules.ProjectExecution.DTOs;
using StyleSync.Api.Modules.ProjectExecution.Interfaces;

namespace StyleSync.Api.Modules.ProjectExecution.Controllers;

[ApiController]
[Route("api/tasks/{taskId:guid}")]
public class TaskDependenciesController : ControllerBase
{
    private readonly ITaskDependencyService _taskDependencyService;

    public TaskDependenciesController(ITaskDependencyService taskDependencyService)
    {
        _taskDependencyService = taskDependencyService;
    }

    [HttpPost("dependencies")]
    [Authorize(Roles = "Admin,Designer")]
    [ProducesResponseType(typeof(TaskDependencyDto), 201)]
    [ProducesResponseType(typeof(ErrorResponse), 400)]
    [ProducesResponseType(typeof(ErrorResponse), 404)]
    [ProducesResponseType(typeof(ErrorResponse), 409)]
    public async Task<IActionResult> CreateDependency(Guid taskId, [FromBody] CreateTaskDependencyDto request)
    {
        try
        {
            var dependency = await _taskDependencyService.CreateDependencyAsync(taskId, request);
            return StatusCode(201, dependency);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new ErrorResponse(400, ex.Message));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new ErrorResponse(404, ex.Message));
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new ErrorResponse(409, ex.Message));
        }
    }

    [HttpGet("dependencies")]
    [Authorize(Roles = "Admin,Designer,Client")]
    [ProducesResponseType(typeof(IEnumerable<TaskDependencyTaskDto>), 200)]
    public async Task<IActionResult> GetPrerequisites(Guid taskId)
    {
        var prerequisites = await _taskDependencyService.GetPrerequisitesAsync(taskId);
        return Ok(prerequisites);
    }

    [HttpGet("dependents")]
    [Authorize(Roles = "Admin,Designer,Client")]
    [ProducesResponseType(typeof(IEnumerable<TaskDependencyTaskDto>), 200)]
    public async Task<IActionResult> GetDependents(Guid taskId)
    {
        var dependents = await _taskDependencyService.GetDependentsAsync(taskId);
        return Ok(dependents);
    }

    [HttpDelete("dependencies/{prerequisiteTaskId:guid}")]
    [Authorize(Roles = "Admin,Designer")]
    [ProducesResponseType(204)]
    [ProducesResponseType(typeof(ErrorResponse), 404)]
    public async Task<IActionResult> DeleteDependency(Guid taskId, Guid prerequisiteTaskId)
    {
        var deleted = await _taskDependencyService.DeleteDependencyAsync(taskId, prerequisiteTaskId);
        if (!deleted)
        {
            return NotFound(new ErrorResponse(404, "Task dependency not found."));
        }

        return NoContent();
    }
}
