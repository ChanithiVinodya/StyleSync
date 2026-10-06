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
[Route("api/projects")]
public class ProjectTimelineController : ControllerBase
{
    private readonly IProjectTimelineService _timelineService;
    private readonly IProgressPhotoService _progressPhotoService;

    public ProjectTimelineController(IProjectTimelineService timelineService, IProgressPhotoService progressPhotoService)
    {
        _timelineService = timelineService;
        _progressPhotoService = progressPhotoService;
    }

    [HttpGet("{projectId:guid}/timeline")]
    [Authorize(Roles = "Admin,Designer,Client")]
    [ProducesResponseType(typeof(IEnumerable<ProjectTimelineEventDto>), 200)]
    public async Task<IActionResult> GetProjectTimeline(Guid projectId, [FromQuery] string? eventType, [FromQuery] DateTime? from, [FromQuery] DateTime? to)
    {
        // TODO: Validate user access to the project using existing mechanism
        
        var timeline = await _timelineService.GetProjectTimelineAsync(projectId, eventType, from, to);
        return Ok(timeline);
    }

    [HttpGet("{projectId:guid}/progress-photos")]
    [Authorize(Roles = "Admin,Designer,Client")]
    [ProducesResponseType(typeof(IEnumerable<ProgressPhotoDto>), 200)]
    public async Task<IActionResult> GetProjectPhotos(Guid projectId, [FromQuery] Guid? milestoneId, [FromQuery] Guid? taskId, [FromQuery] DateTime? from, [FromQuery] DateTime? to, [FromQuery] string sort = "desc")
    {
        // TODO: Validate user access to the project using existing mechanism
        
        var photos = await _progressPhotoService.GetProjectPhotosAsync(projectId, milestoneId, taskId, from, to, sort);
        return Ok(photos);
    }

    [HttpPost("{projectId:guid}/timeline")]
    [Authorize(Roles = "Admin,Designer")]
    [ProducesResponseType(typeof(ProjectTimelineEventDto), 201)]
    public async Task<IActionResult> CreateTimelineEvent(Guid projectId, [FromBody] CreateTimelineEventDto dto)
    {
        // TODO: Get user id from claims
        var ev = await _timelineService.CreateTimelineEventAsync(projectId, dto, null);
        return Created("", ev);
    }

    [HttpPut("{projectId:guid}/timeline/{eventId:guid}")]
    [Authorize(Roles = "Admin,Designer")]
    [ProducesResponseType(typeof(ProjectTimelineEventDto), 200)]
    [ProducesResponseType(404)]
    public async Task<IActionResult> UpdateTimelineEvent(Guid projectId, Guid eventId, [FromBody] UpdateTimelineEventDto dto)
    {
        var ev = await _timelineService.UpdateTimelineEventAsync(eventId, dto);
        if (ev == null) return NotFound(new ErrorResponse(404, "Event not found"));
        return Ok(ev);
    }

    [HttpDelete("{projectId:guid}/timeline/{eventId:guid}")]
    [Authorize(Roles = "Admin,Designer")]
    [ProducesResponseType(204)]
    [ProducesResponseType(404)]
    public async Task<IActionResult> DeleteTimelineEvent(Guid projectId, Guid eventId)
    {
        var success = await _timelineService.DeleteTimelineEventAsync(eventId);
        if (!success) return NotFound(new ErrorResponse(404, "Event not found"));
        return NoContent();
    }
}
