using System;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StyleSync.Api.DTOs;
using StyleSync.Api.Modules.ProjectExecution.DTOs;
using StyleSync.Api.Modules.ProjectExecution.Interfaces;

namespace StyleSync.Api.Modules.ProjectExecution.Controllers;

[ApiController]
[Route("api/progress-photos")]
public class ProgressPhotosController : ControllerBase
{
    private readonly IProgressPhotoService _progressPhotoService;

    public ProgressPhotosController(IProgressPhotoService progressPhotoService)
    {
        _progressPhotoService = progressPhotoService;
    }

    [HttpPost]
    [Authorize(Roles = "Admin,Designer")]
    [ProducesResponseType(typeof(ProgressPhotoDto), 201)]
    [ProducesResponseType(typeof(ErrorResponse), 400)]
    public async Task<IActionResult> UploadPhoto([FromForm] CreateProgressPhotoDto request)
    {
        try
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!Guid.TryParse(userIdStr, out var userId))
                return Unauthorized();

            var photo = await _progressPhotoService.CreateAsync(request, userId);
            return CreatedAtAction(nameof(GetPhotoById), new { id = photo.PhotoId }, photo);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new ErrorResponse(400, ex.Message));
        }
    }

    [HttpGet]
    [Authorize(Roles = "Admin,Designer,Client")]
    [ProducesResponseType(typeof(IEnumerable<ProgressPhotoDto>), 200)]
    public async Task<IActionResult> GetPhotos([FromQuery] Guid projectId, [FromQuery] Guid? milestoneId = null, [FromQuery] Guid? taskId = null)
    {
        var photos = await _progressPhotoService.GetProjectPhotosAsync(projectId, milestoneId, taskId);
        return Ok(photos);
    }

    [HttpGet("{id:guid}")]
    [Authorize(Roles = "Admin,Designer,Client")]
    [ProducesResponseType(typeof(ProgressPhotoDto), 200)]
    [ProducesResponseType(typeof(ErrorResponse), 404)]
    public async Task<IActionResult> GetPhotoById(Guid id)
    {
        var photo = await _progressPhotoService.GetByIdAsync(id);
        if (photo == null)
            return NotFound(new ErrorResponse(404, "Progress photo not found."));

        return Ok(photo);
    }

    [HttpPut("{id:guid}")]
    [Authorize(Roles = "Admin,Designer")]
    [ProducesResponseType(typeof(ProgressPhotoDto), 200)]
    [ProducesResponseType(typeof(ErrorResponse), 400)]
    [ProducesResponseType(typeof(ErrorResponse), 404)]
    public async Task<IActionResult> UpdatePhoto(Guid id, [FromBody] UpdateProgressPhotoDto request)
    {
        try
        {
            var photo = await _progressPhotoService.UpdateAsync(id, request);
            if (photo == null)
                return NotFound(new ErrorResponse(404, "Progress photo not found."));

            return Ok(photo);
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
    public async Task<IActionResult> DeletePhoto(Guid id)
    {
        var deleted = await _progressPhotoService.DeleteAsync(id);
        if (!deleted)
            return NotFound(new ErrorResponse(404, "Progress photo not found."));

        return NoContent();
    }
}
