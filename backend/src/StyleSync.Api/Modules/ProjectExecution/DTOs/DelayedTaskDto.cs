using System;

namespace StyleSync.Api.Modules.ProjectExecution.DTOs;

public class DelayedTaskDto
{
    public Guid TaskId { get; set; }
    public string Name { get; set; } = string.Empty;
    public DateTime DueDate { get; set; }
    public Models.TaskStatus Status { get; set; }
    public int DaysDelayed { get; set; }
}
