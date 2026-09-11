using Microsoft.AspNetCore.Mvc;
using StyleSync.Backend.DTOs;
using StyleSync.Backend.Services;

namespace StyleSync.Backend.Controllers;

[ApiController]
[Route("api/v1/project-requests")]
public class ProjectRequestsController : ControllerBase
{
    private readonly IProjectRequestService _service;
    private readonly ILogger<ProjectRequestsController> _logger;

    public ProjectRequestsController(IProjectRequestService service, ILogger<ProjectRequestsController> logger)
    {
        _service = service;
        _logger = logger;
    }

    /// <summary>
    /// Create a new project room makeover request (Draft or Submitted)
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<ProjectRequestResponseDto>> CreateRequest([FromBody] CreateProjectRequestDto dto, [FromHeader(Name = "X-Client-Id")] string? clientId = null)
    {
        try
        {
            var result = await _service.CreateRequestAsync(dto, clientId ?? "client-default");
            return CreatedAtAction(nameof(GetRequestById), new { id = result.Id }, result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating project request");
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Search and filter project requests by status, roomType, or clientId
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<List<ProjectRequestResponseDto>>> GetAllRequests(
        [FromQuery] string? status = null,
        [FromQuery] string? roomType = null,
        [FromQuery] string? clientId = null)
    {
        var requests = await _service.GetAllRequestsAsync(status, roomType, clientId);
        return Ok(requests);
    }

    /// <summary>
    /// Get project request details by ID
    /// </summary>
    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ProjectRequestResponseDto>> GetRequestById(Guid id)
    {
        var request = await _service.GetRequestByIdAsync(id);
        if (request == null) return NotFound(new { message = $"Project request with ID '{id}' was not found." });
        return Ok(request);
    }

    /// <summary>
    /// Update a Draft project request
    /// </summary>
    [HttpPut("{id:guid}")]
    public async Task<ActionResult<ProjectRequestResponseDto>> UpdateRequest(Guid id, [FromBody] UpdateProjectRequestDto dto, [FromHeader(Name = "X-Client-Id")] string? clientId = null)
    {
        try
        {
            var updated = await _service.UpdateRequestAsync(id, dto, clientId ?? "client-default");
            if (updated == null) return NotFound(new { message = $"Project request with ID '{id}' was not found." });
            return Ok(updated);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating project request {Id}", id);
            return StatusCode(500, new { message = "An error occurred while updating the request." });
        }
    }

    /// <summary>
    /// Delete a Draft project request
    /// </summary>
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteRequest(Guid id, [FromHeader(Name = "X-Client-Id")] string? clientId = null)
    {
        try
        {
            var success = await _service.DeleteRequestAsync(id, clientId ?? "client-default");
            if (!success) return NotFound(new { message = $"Project request with ID '{id}' was not found." });
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Upload a room photo for a project request
    /// </summary>
    [HttpPost("{id:guid}/photos")]
    public async Task<ActionResult<ProjectRequestResponseDto>> UploadPhoto(Guid id, IFormFile photo)
    {
        if (photo == null || photo.Length == 0)
        {
            return BadRequest(new { message = "No image file was provided." });
        }

        var result = await _service.UploadPhotoAsync(id, photo);
        if (result == null) return NotFound(new { message = $"Project request with ID '{id}' was not found." });
        return Ok(result);
    }

    /// <summary>
    /// Submit project request to trigger AI Style Analysis
    /// </summary>
    [HttpPost("{id:guid}/submit")]
    public async Task<ActionResult<ProjectRequestResponseDto>> SubmitRequest(Guid id)
    {
        var result = await _service.SubmitRequestForAIAnalysisAsync(id);
        if (result == null) return NotFound(new { message = $"Project request with ID '{id}' was not found." });
        return Ok(result);
    }

    /// <summary>
    /// Get AI Style Analysis Result for a project request
    /// </summary>
    [HttpGet("{id:guid}/style-analysis")]
    public async Task<ActionResult<StyleAnalysisResultDto>> GetStyleAnalysis(Guid id)
    {
        var request = await _service.GetRequestByIdAsync(id);
        if (request == null) return NotFound(new { message = $"Project request with ID '{id}' was not found." });
        if (request.StyleAnalysis == null) return NotFound(new { message = $"Style analysis has not yet been processed for project request '{id}'." });
        return Ok(request.StyleAnalysis);
    }
}
