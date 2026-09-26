using System;

namespace StyleSync.Api.Modules.ProjectExecution.DTOs;

public class ProjectTimelineEventDto
{
    public string EventId { get; set; } = string.Empty;
    public Guid ProjectId { get; set; }
    public string EventType { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string EntityType { get; set; } = string.Empty;
    public string EntityId { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; }
    public Guid? CreatedBy { get; set; }
}
