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
public class ProjectMaterialsController : ControllerBase
{
    private readonly IMaterialService _materialService;

    public ProjectMaterialsController(IMaterialService materialService)
    {
        _materialService = materialService;
    }

    [HttpGet("{projectId:guid}/materials")]
    [Authorize(Roles = "Admin,Designer,Client")]
    [ProducesResponseType(typeof(IEnumerable<MaterialDto>), 200)]
    public async Task<IActionResult> GetMaterialsForProject(Guid projectId)
    {
        var materials = await _materialService.GetAllAsync(projectId: projectId);
        return Ok(materials);
    }
}
