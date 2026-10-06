using System;

namespace StyleSync.Api.Modules.ProjectExecution.DTOs;

public class TaskDependencyDto
{
    public Guid TaskDependencyId { get; set; }
    public Guid TaskId { get; set; }
    public Guid PrerequisiteTaskId { get; set; }
    public DateTime CreatedAt { get; set; }
}
