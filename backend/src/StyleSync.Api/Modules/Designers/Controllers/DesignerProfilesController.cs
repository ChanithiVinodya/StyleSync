using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StyleSync.Api.Modules.Designers.DTOs;
using StyleSync.Api.Modules.Designers.Services;

namespace StyleSync.Api.Modules.Designers.Controllers;

[ApiController]
[Route("api/[controller]")]
public class DesignerProfilesController : ControllerBase
{
    private readonly IDesignerProfileService _service;

    public DesignerProfilesController(IDesignerProfileService service)
    {
        _service = service;
    }

    [HttpGet]
    [ProducesResponseType(typeof(IEnumerable<DesignerProfileResponse>), 200)]
    public async Task<IActionResult> GetAll()
    {
        var profiles = await _service.GetAllAsync();
        return Ok(profiles);
    }

    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(DesignerProfileResponse), 200)]
    [ProducesResponseType(404)]
    public async Task<IActionResult> GetById(int id)
    {
        var profile = await _service.GetByIdAsync(id);
        if (profile == null) return NotFound();
        return Ok(profile);
    }

    [HttpGet("me")]
    [Authorize(Roles = "Admin,Designer")]
    [ProducesResponseType(typeof(DesignerProfileResponse), 200)]
    [ProducesResponseType(404)]
    [ProducesResponseType(401)]
    public async Task<IActionResult> GetMyProfile()
    {
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
                          ?? User.FindFirst("sub")?.Value;

        if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
        {
            return Unauthorized();
        }

        var profile = await _service.GetByUserIdAsync(userId);
        if (profile == null) return NotFound();
        return Ok(profile);
    }

    [HttpPost]
    [Authorize(Roles = "Admin,Designer")]
    [ProducesResponseType(typeof(DesignerProfileResponse), 201)]
    public async Task<IActionResult> Create([FromBody] CreateDesignerProfileRequest dto)
    {
        var profile = await _service.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = profile.Id }, profile);
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = "Admin,Designer")]
    [ProducesResponseType(typeof(DesignerProfileResponse), 200)]
    [ProducesResponseType(404)]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateDesignerProfileRequest dto)
    {
        var profile = await _service.UpdateAsync(id, dto);
        if (profile == null) return NotFound();
        return Ok(profile);
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(204)]
    [ProducesResponseType(404)]
    public async Task<IActionResult> Delete(int id)
    {
        var success = await _service.DeleteAsync(id);
        if (!success) return NotFound();
        return NoContent();
    }
}
