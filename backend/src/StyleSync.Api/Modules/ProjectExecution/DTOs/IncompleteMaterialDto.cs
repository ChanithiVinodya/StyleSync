using System;

namespace StyleSync.Api.Modules.ProjectExecution.DTOs;

public class IncompleteMaterialDto
{
    public Guid MaterialId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
}
