using System;
using System.Collections.Generic;

namespace StyleSync.Api.Modules.ProjectExecution.Models;

public class ProjectMilestone
{
    public Guid MilestoneId { get; set; }
    
    // Foreign key to the generic Project (entity might not exist in this repo yet)
    public Guid ProjectId { get; set; }
    
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    
    public DateTime StartDate { get; set; }
    public DateTime DueDate { get; set; }
    
    public MilestoneStatus Status { get; set; }
    
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    // Navigation properties
    public ICollection<ProjectTask> Tasks { get; set; } = new List<ProjectTask>();
    public ICollection<ProjectMaterial> Materials { get; set; } = new List<ProjectMaterial>();
    public ICollection<ProgressPhoto> ProgressPhotos { get; set; } = new List<ProgressPhoto>();
}
