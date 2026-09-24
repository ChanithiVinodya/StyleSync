using System;
using StyleSync.Api.Modules.ProjectExecution.Models;

namespace StyleSync.Api.Modules.ProjectExecution.DTOs;

public class MilestoneDto
{
    public Guid MilestoneId { get; set; }
    public Guid ProjectId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime DueDate { get; set; }
    public MilestoneStatus Status { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
