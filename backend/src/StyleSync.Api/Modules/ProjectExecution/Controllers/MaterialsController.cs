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
[Route("api/[controller]")]
public class MaterialsController : ControllerBase
{
    private readonly IMaterialService _materialService;

    public MaterialsController(IMaterialService materialService)
    {
        _materialService = materialService;
    }

    [HttpPost]
    [Authorize(Roles = "Admin,Designer")]
    [ProducesResponseType(typeof(MaterialDto), 201)]
    [ProducesResponseType(typeof(ErrorResponse), 400)]
    public async Task<IActionResult> CreateMaterial([FromBody] CreateMaterialDto request)
    {
        try
        {
            var result = await _materialService.CreateAsync(request);
            return CreatedAtAction(nameof(GetMaterial), new { id = result.MaterialId }, result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new ErrorResponse(400, ex.Message));
        }
    }

    [HttpGet]
    [Authorize(Roles = "Admin,Designer,Client")]
    [ProducesResponseType(typeof(IEnumerable<MaterialDto>), 200)]
    public async Task<IActionResult> GetMaterials(
        [FromQuery] Guid? projectId, 
        [FromQuery] Guid? milestoneId, 
        [FromQuery] Guid? taskId, 
        [FromQuery] string? status)
    {
        var result = await _materialService.GetAllAsync(projectId, milestoneId, taskId, status);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    [Authorize(Roles = "Admin,Designer,Client")]
    [ProducesResponseType(typeof(MaterialDto), 200)]
    [ProducesResponseType(typeof(ErrorResponse), 404)]
    public async Task<IActionResult> GetMaterial(Guid id)
    {
        var result = await _materialService.GetByIdAsync(id);
        if (result == null)
        {
            return NotFound(new ErrorResponse(404, "Material not found."));
        }
        return Ok(result);
    }

    [HttpPut("{id:guid}")]
    [Authorize(Roles = "Admin,Designer")]
    [ProducesResponseType(typeof(MaterialDto), 200)]
    [ProducesResponseType(typeof(ErrorResponse), 400)]
    [ProducesResponseType(typeof(ErrorResponse), 404)]
    public async Task<IActionResult> UpdateMaterial(Guid id, [FromBody] UpdateMaterialDto request)
    {
        try
        {
            var result = await _materialService.UpdateAsync(id, request);
            if (result == null)
            {
                return NotFound(new ErrorResponse(404, "Material not found."));
            }
            return Ok(result);
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
    public async Task<IActionResult> DeleteMaterial(Guid id)
    {
        var deleted = await _materialService.DeleteAsync(id);
        if (!deleted)
        {
            return NotFound(new ErrorResponse(404, "Material not found."));
        }
        return NoContent();
    }

    [HttpPatch("{id:guid}/status")]
    [Authorize(Roles = "Admin,Designer")]
    [ProducesResponseType(typeof(MaterialDto), 200)]
    [ProducesResponseType(typeof(ErrorResponse), 404)]
    public async Task<IActionResult> UpdateMaterialStatus(Guid id, [FromBody] UpdateMaterialStatusDto request)
    {
        var result = await _materialService.UpdateStatusAsync(id, request);
        if (result == null)
        {
            return NotFound(new ErrorResponse(404, "Material not found."));
        }
        return Ok(result);
    }
}
