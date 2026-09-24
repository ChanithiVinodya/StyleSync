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
public class TasksController : ControllerBase
{
    private readonly ITaskService _taskService;

    public TasksController(ITaskService taskService)
    {
        _taskService = taskService;
    }

    [HttpPost]
    [Authorize(Roles = "Admin,Designer")]
    [ProducesResponseType(typeof(TaskDto), 201)]
    [ProducesResponseType(typeof(ErrorResponse), 400)]
    [ProducesResponseType(typeof(ErrorResponse), 404)]
    public async Task<IActionResult> CreateTask([FromBody] CreateTaskDto request)
    {
        try
        {
            var task = await _taskService.CreateAsync(request);
            return CreatedAtAction(nameof(GetTaskById), new { id = task.TaskId }, task);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new ErrorResponse(400, ex.Message));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new ErrorResponse(404, ex.Message));
        }
    }

    [HttpGet]
    [Authorize(Roles = "Admin,Designer,Client")]
    [ProducesResponseType(typeof(IEnumerable<TaskDto>), 200)]
    public async Task<IActionResult> GetAllTasks([FromQuery] Guid? milestoneId, [FromQuery] Models.TaskStatus? status)
    {
        var tasks = await _taskService.GetAllAsync(milestoneId, status);
        return Ok(tasks);
    }

    [HttpGet("{id:guid}")]
    [Authorize(Roles = "Admin,Designer,Client")]
    [ProducesResponseType(typeof(TaskDto), 200)]
    [ProducesResponseType(typeof(ErrorResponse), 404)]
    public async Task<IActionResult> GetTaskById(Guid id)
    {
        var task = await _taskService.GetByIdAsync(id);
        if (task == null)
        {
            return NotFound(new ErrorResponse(404, "Task not found."));
        }

        return Ok(task);
    }

    [HttpPut("{id:guid}")]
    [Authorize(Roles = "Admin,Designer")]
    [ProducesResponseType(typeof(TaskDto), 200)]
    [ProducesResponseType(typeof(ErrorResponse), 400)]
    [ProducesResponseType(typeof(ErrorResponse), 404)]
    public async Task<IActionResult> UpdateTask(Guid id, [FromBody] UpdateTaskDto request)
    {
        try
        {
            var task = await _taskService.UpdateAsync(id, request);
            if (task == null)
            {
                return NotFound(new ErrorResponse(404, "Task not found."));
            }

            return Ok(task);
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
    public async Task<IActionResult> DeleteTask(Guid id)
    {
        try
        {
            var deleted = await _taskService.DeleteAsync(id);
            if (!deleted)
            {
                return NotFound(new ErrorResponse(404, "Task not found."));
            }

            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new ErrorResponse(409, ex.Message));
        }
    }
}
