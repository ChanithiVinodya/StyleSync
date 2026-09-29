using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StyleSync.Api.Modules.ProjectRequests.DTOs;
using StyleSync.Api.Modules.ProjectRequests.Interfaces;

namespace StyleSync.Api.Modules.ProjectRequests.Controllers;

[ApiController]
[Route("api/v1/project-requests")]
[Route("api/v1/requests")]
[Route("requests")]
[Authorize]
public class ProjectRequestsController : ControllerBase
{
    private readonly IProjectRequestService _service;

    public ProjectRequestsController(IProjectRequestService service)
    {
        _service = service;
    }

    // ─── POST /requests ───────────────────────────────────────────────────────
    /// <summary>Create a new project request (as Draft or immediately Submitted).</summary>
    [HttpPost]
    [Authorize(Roles = "Client")]
    [ProducesResponseType(typeof(ProjectRequestDetailDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Create([FromBody] CreateProjectRequestDto dto)
    {
        var clientId = GetCurrentUserId();
        var result = await _service.CreateAsync(clientId, dto);
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
    }

    // ─── GET /requests ────────────────────────────────────────────────────────
    /// <summary>Get list of requests with search, filters (status, roomType, budget, date), sorting, and pagination.</summary>
    [HttpGet]
    [ProducesResponseType(typeof(PagedResult<ProjectRequestSummaryDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll([FromQuery] ProjectRequestFilterQuery query)
    {
        var userId = GetCurrentUserId();
        var role = GetCurrentUserRole();
        var result = await _service.GetFilteredAsync(userId, role, query);
        return Ok(result);
    }

    // ─── GET /requests/analytics ──────────────────────────────────────────────
    /// <summary>Admin: get request analytics (requests by status, by room type, avg budget).</summary>
    [HttpGet("analytics")]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(typeof(RequestAnalyticsDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAnalytics()
    {
        var analytics = await _service.GetAnalyticsAsync();
        return Ok(analytics);
    }

    // ─── GET /requests/{id} ───────────────────────────────────────────────────
    /// <summary>Get request detail by ID, including photos, moodboards, extracted hex color palette, and status timeline.</summary>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ProjectRequestDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(int id)
    {
        var userId = GetCurrentUserId();
        var role = GetCurrentUserRole();
        var result = await _service.GetByIdAsync(id, userId, role);
        return Ok(result);
    }

    // ─── PUT /requests/{id} ───────────────────────────────────────────────────
    /// <summary>Edit a draft project request (Client only, own requests).</summary>
    [HttpPut("{id:int}")]
    [Authorize(Roles = "Client")]
    [ProducesResponseType(typeof(ProjectRequestDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateProjectRequestDto dto)
    {
        var clientId = GetCurrentUserId();
        var result = await _service.UpdateAsync(id, clientId, dto);
        return Ok(result);
    }

    // ─── DELETE /requests/{id} ────────────────────────────────────────────────
    /// <summary>Delete a draft request (Client only, own requests).</summary>
    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Client")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Delete(int id)
    {
        var clientId = GetCurrentUserId();
        await _service.DeleteAsync(id, clientId);
        return NoContent();
    }

    // ─── POST /requests/{id}/images ───────────────────────────────────────────
    /// <summary>Upload room photo and moodboard reference images to a request.</summary>
    [HttpPost("{id:int}/images")]
    [Authorize(Roles = "Client")]
    [ProducesResponseType(typeof(ProjectRequestDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UploadImages(int id, [FromBody] List<UploadImageDto> images)
    {
        var clientId = GetCurrentUserId();
        var result = await _service.AddImagesAsync(id, clientId, images);
        return Ok(result);
    }

    // ─── POST /requests/{id}/submit ───────────────────────────────────────────
    /// <summary>Submit a draft request for review and AI workflow. Enforces client ownership, budget > 0, room size > 0, and photo existence.</summary>
    [HttpPost("{id:int}/submit")]
    [Authorize(Roles = "Client")]
    [ProducesResponseType(typeof(ProjectRequestDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Submit(int id)
    {
        var clientId = GetCurrentUserId();
        var result = await _service.SubmitAsync(id, clientId);
        return Ok(result);
    }

    // ─── POST /requests/{id}/flag ─────────────────────────────────────────────
    /// <summary>Admin: flag or cancel an invalid request with audit trail reason recorded.</summary>
    [HttpPost("{id:int}/flag")]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(typeof(ProjectRequestDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> FlagRequest(int id, [FromBody] FlagProjectRequestDto dto)
    {
        var adminName = User.Identity?.Name ?? "Admin User";
        var result = await _service.FlagRequestAsync(id, dto.Reason, adminName);
        return Ok(result);
    }

    // ─── DELETE /requests/{id}/cancel ─────────────────────────────────────────
    /// <summary>Cancel a submitted or under-review request (Client, own requests only).</summary>
    [HttpDelete("{id:int}/cancel")]
    [Authorize(Roles = "Client")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Cancel(int id, [FromQuery] string? reason)
    {
        var clientId = GetCurrentUserId();
        await _service.CancelAsync(id, clientId, reason);
        return NoContent();
    }

    // ─── PATCH /requests/{id}/status ──────────────────────────────────────────
    /// <summary>Admin: update request status along the approval lifecycle.</summary>
    [HttpPatch("{id:int}/status")]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(typeof(ProjectRequestDetailDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpdateStatus(int id, [FromBody] RejectProjectRequestDto? dto, [FromQuery] string status)
    {
        var result = await _service.UpdateStatusAsync(id, status, dto?.RejectionReason);
        return Ok(result);
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private Guid GetCurrentUserId()
    {
        var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                    ?? User.FindFirst("sub")?.Value;

        if (string.IsNullOrEmpty(claim) || !Guid.TryParse(claim, out var id))
            throw new UnauthorizedAccessException("Invalid authentication token.");

        return id;
    }

    private string GetCurrentUserRole()
    {
        return User.FindFirst(ClaimTypes.Role)?.Value
               ?? User.FindFirst("role")?.Value
               ?? string.Empty;
    }
}
