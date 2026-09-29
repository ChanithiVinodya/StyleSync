using StyleSync.Api.Common.Shared;

namespace StyleSync.Api.Modules.ProjectRequests.Models;

public class ProjectRequestStatusHistory : BaseEntity
{
    public int ProjectRequestId { get; set; }
    public ProjectRequest ProjectRequest { get; set; } = null!;

    public string Status { get; set; } = string.Empty;
    public string? Reason { get; set; }
    public string? ChangedBy { get; set; }
}
