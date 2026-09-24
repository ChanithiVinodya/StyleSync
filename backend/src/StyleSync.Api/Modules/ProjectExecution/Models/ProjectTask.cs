using System;
using System.Collections.Generic;

namespace StyleSync.Api.Modules.ProjectExecution.Models;

public class ProjectTask
{
    public Guid TaskId { get; set; }
    
    public Guid MilestoneId { get; set; }
    public ProjectMilestone Milestone { get; set; } = null!;
    
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    
    public DateTime StartDate { get; set; }
    public DateTime DueDate { get; set; }
    
    public Models.TaskStatus Status { get; set; }
    
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    // Navigation properties for Dependencies
    public ICollection<TaskDependency> Prerequisites { get; set; } = new List<TaskDependency>();
    public ICollection<TaskDependency> Dependents { get; set; } = new List<TaskDependency>();
}
