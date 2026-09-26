using System;
using StyleSync.Api.Common.Identity;

namespace StyleSync.Api.Modules.ProjectExecution.Models;

public class ProgressPhoto
{
    public Guid ProgressPhotoId { get; set; }

    public Guid ProjectId { get; set; }

    // A ProgressPhoto can optionally be associated with a milestone
    public Guid? MilestoneId { get; set; }
    public ProjectMilestone? Milestone { get; set; }

    public Guid UploadedBy { get; set; }
    public AppUser Uploader { get; set; } = null!;

    public string ImageUrl { get; set; } = string.Empty;
    public string? Description { get; set; }

    public DateTime UploadedAt { get; set; }
}
