using System;
using StyleSync.Api.Modules.ProjectExecution.Models;

namespace StyleSync.Api.Modules.ProjectExecution.DTOs;

public class MaterialDto
{
    public Guid MaterialId { get; set; }
    public Guid ProjectId { get; set; }
    public Guid? MilestoneId { get; set; }
    public Guid? TaskId { get; set; }

    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int Quantity { get; set; }
    public string Unit { get; set; } = string.Empty;

    public DateTime? RequiredDate { get; set; }
    public DateTime? OrderedDate { get; set; }
    public DateTime? DeliveredDate { get; set; }

    public MaterialStatus Status { get; set; }

    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
