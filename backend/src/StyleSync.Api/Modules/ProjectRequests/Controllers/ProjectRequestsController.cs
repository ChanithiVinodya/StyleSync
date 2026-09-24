using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StyleSync.Api.Modules.ProjectRequests.DTOs;
using StyleSync.Api.Modules.ProjectRequests.Interfaces;

namespace StyleSync.Api.Modules.ProjectRequests.Controllers;

[ApiController]
[Route("api/v1/project-requests")]
[Authorize]
public class ProjectRequestsController : ControllerBase
{
    private readonly IProjectRequestService _service;

    public ProjectRequestsController(IProjectRequestService service)
    {
        _service = service;
    }

    // ─── POST api/v1/project-requests ─────────────────────────────────────────
    /// <summary>Submit a new interior design project request (Client only).</summary>
    [HttpPost]
    [Authorize(Roles = "Client")]
    [ProducesResponseType(typeof(ProjectRequestDetailDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> Create([FromBody] CreateProjectRequestDto dto)
    {
        var clientId = GetCurrentUserId();
        var result = await _service.CreateAsync(clientId, dto);
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
    }

    // ─── GET api/v1/project-requests ──────────────────────────────────────────
    /// <summary>Get project requests. Clients see only their own; Admin/Designer see all.</summary>
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<ProjectRequestSummaryDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll()
    {
        var role = GetCurrentUserRole();
        if (role == "Client")
        {
            var clientId = GetCurrentUserId();
            return Ok(await _service.GetByClientAsync(clientId));
        }
        return Ok(await _service.GetAllAsync());
    }

    // ─── GET api/v1/project-requests/{id} ─────────────────────────────────────
    /// <summary>Get a project request by ID. Clients can only see their own.</summary>
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

    // ─── PUT api/v1/project-requests/{id} ─────────────────────────────────────
    /// <summary>Update a submitted project request (Client, own requests only).</summary>
    [HttpPut("{id:int}")]
    [Authorize(Roles = "Client")]
    [ProducesResponseType(typeof(ProjectRequestDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateProjectRequestDto dto)
    {
        var clientId = GetCurrentUserId();
        var result = await _service.UpdateAsync(id, clientId, dto);
        return Ok(result);
    }

    // ─── DELETE api/v1/project-requests/{id}/cancel ───────────────────────────
    /// <summary>Cancel a submitted or under-review request (Client, own requests only).</summary>
    [HttpDelete("{id:int}/cancel")]
    [Authorize(Roles = "Client")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Cancel(int id)
    {
        var clientId = GetCurrentUserId();
        await _service.CancelAsync(id, clientId);
        return NoContent();
    }

    // ─── PATCH api/v1/project-requests/{id}/status ────────────────────────────
    /// <summary>Admin: update request status along the approval lifecycle.</summary>
    [HttpPatch("{id:int}/status")]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(typeof(ProjectRequestDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
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
