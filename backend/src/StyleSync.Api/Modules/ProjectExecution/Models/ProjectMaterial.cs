using System;

namespace StyleSync.Api.Modules.ProjectExecution.Models;

public class ProjectMaterial
{
    public Guid MaterialId { get; set; }

    public Guid ProjectId { get; set; }

    // A Material can optionally be associated with a milestone or task
    public Guid? MilestoneId { get; set; }
    public ProjectMilestone? Milestone { get; set; }

    public Guid? TaskId { get; set; }
    public ProjectTask? Task { get; set; }

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
