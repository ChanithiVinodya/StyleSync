using System;

namespace StyleSync.Api.Modules.ProjectExecution.DTOs;

public class TaskDependencyTaskDto
{
    public Guid TaskId { get; set; }
    public string Name { get; set; } = string.Empty;
    public Models.TaskStatus Status { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime DueDate { get; set; }
}
