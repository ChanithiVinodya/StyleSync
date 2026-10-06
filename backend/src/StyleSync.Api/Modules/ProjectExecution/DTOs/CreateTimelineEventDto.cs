using System;

namespace StyleSync.Api.Modules.ProjectExecution.DTOs;

public class CreateTimelineEventDto
{
    public string EventType { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
}

public class UpdateTimelineEventDto
{
    public string EventType { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
}
