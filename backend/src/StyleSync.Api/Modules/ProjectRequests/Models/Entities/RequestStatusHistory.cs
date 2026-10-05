using System;
using StyleSync.Api.Common.Identity;
using StyleSync.Api.Modules.ProjectRequests.Models.Enums;

namespace StyleSync.Api.Modules.ProjectRequests.Models.Entities;

public class RequestStatusHistory
{
    public Guid Id { get; set; } = Guid.NewGuid();
    
    public Guid ProjectRequestId { get; set; }
    public ProjectRequest ProjectRequest { get; set; } = null!;
    
    public RequestStatus? FromStatus { get; set; }
    public RequestStatus ToStatus { get; set; }
    
    public DateTime ChangedAt { get; set; } = DateTime.UtcNow;
    
    public Guid? ChangedByUserId { get; set; }
    public AppUser? ChangedByUser { get; set; }
    
    public string? Note { get; set; }
}
