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
    [ProducesResponseType(typeof(IEnumerable<DesignerProfileDto>), 200)]
    public async Task<IActionResult> GetAll()
    {
        var profiles = await _service.GetAllAsync();
        return Ok(profiles);
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(DesignerProfileDto), 200)]
    [ProducesResponseType(404)]
    public async Task<IActionResult> GetById(Guid id)
    {
        var profile = await _service.GetByIdAsync(id);
        if (profile == null) return NotFound();
        return Ok(profile);
    }

    [HttpPost]
    [Authorize(Roles = "Admin,Designer")]
    [ProducesResponseType(typeof(DesignerProfileDto), 201)]
    public async Task<IActionResult> Create([FromBody] CreateDesignerProfileDto dto)
    {
        var profile = await _service.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = profile.Id }, profile);
    }

    [HttpPut("{id:guid}")]
    [Authorize(Roles = "Admin,Designer")]
    [ProducesResponseType(typeof(DesignerProfileDto), 200)]
    [ProducesResponseType(404)]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateDesignerProfileDto dto)
    {
        var profile = await _service.UpdateAsync(id, dto);
        if (profile == null) return NotFound();
        return Ok(profile);
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(204)]
    [ProducesResponseType(404)]
    public async Task<IActionResult> Delete(Guid id)
    {
        var success = await _service.DeleteAsync(id);
        if (!success) return NotFound();
        return NoContent();
    }
}
