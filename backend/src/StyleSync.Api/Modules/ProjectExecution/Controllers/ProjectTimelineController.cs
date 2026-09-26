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
}
