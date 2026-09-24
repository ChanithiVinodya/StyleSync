using System;
using StyleSync.Api.Modules.ProjectExecution.Models;

namespace StyleSync.Api.Modules.ProjectExecution.DTOs;

public class MaterialDto
{
    public Guid MaterialId { get; set; }
    public Guid ProjectId { get; set; }
    public Guid? MilestoneId { get; set; }
    public string Name { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public DateTime? ExpectedDeliveryDate { get; set; }
    public MaterialStatus Status { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
