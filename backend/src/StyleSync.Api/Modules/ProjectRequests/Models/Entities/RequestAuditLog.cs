using System;

namespace StyleSync.Api.Modules.ProjectRequests.Models.Entities;

public class RequestAuditLog
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ActorId { get; set; }
    public string Action { get; set; } = string.Empty;
    public Guid EntityId { get; set; }
    public string Reason { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}
