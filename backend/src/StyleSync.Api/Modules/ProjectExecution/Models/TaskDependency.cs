using System;

namespace StyleSync.Api.Modules.ProjectExecution.Models;

public class TaskDependency
{
    public Guid TaskDependencyId { get; set; }
    
    // The task that depends on the prerequisite
    public Guid TaskId { get; set; }
    public ProjectTask Task { get; set; } = null!;
    
    // The task that must be completed first
    public Guid PrerequisiteTaskId { get; set; }
    public ProjectTask PrerequisiteTask { get; set; } = null!;
    
    public DateTime CreatedAt { get; set; }
}
