using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StyleSync.Api.DTOs;
using StyleSync.Api.Modules.ProjectExecution.DTOs;
using StyleSync.Api.Modules.ProjectExecution.Interfaces;

namespace StyleSync.Api.Modules.ProjectExecution.Controllers;

[ApiController]
[Route("api/projects")]
public class AnalyticsController : ControllerBase
{
    private readonly IProjectAnalyticsService _analyticsService;

    public AnalyticsController(IProjectAnalyticsService analyticsService)
    {
        _analyticsService = analyticsService;
    }

    /// <summary>
    /// Retrieves aggregated execution analytics for a specific project.
    /// </summary>
    /// <param name="projectId">The unique identifier of the project.</param>
    /// <param name="from">Optional start date to filter time-based metrics (e.g. uploaded photos, completed tasks).</param>
    /// <param name="to">Optional end date to filter time-based metrics.</param>
    /// <returns>A comprehensive analytics summary object.</returns>
    [HttpGet("{projectId:guid}/analytics")]
    [Authorize(Roles = "Admin,Designer,Client")]
    [ProducesResponseType(typeof(ProjectAnalyticsDto), 200)]
    public async Task<IActionResult> GetProjectAnalytics(Guid projectId, [FromQuery] DateTime? from, [FromQuery] DateTime? to)
    {
        // TODO: Ensure proper project authorization checks using standard app mechanisms.
        
        var analytics = await _analyticsService.GetProjectAnalyticsAsync(projectId, from, to);
        return Ok(analytics);
    }
}
