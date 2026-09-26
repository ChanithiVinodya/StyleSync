using System;

namespace StyleSync.Api.Modules.ProjectExecution.DTOs;

public class ProjectAnalyticsDto
{
    public Guid ProjectId { get; set; }
    public string ProjectName { get; set; } = string.Empty;
    public double OverallProgress { get; set; }

    public MilestoneAnalyticsDto Milestones { get; set; } = new();
    public TaskAnalyticsDto Tasks { get; set; } = new();
    public MaterialAnalyticsDto Materials { get; set; } = new();
    public MaterialGatedAnalyticsDto MaterialGated { get; set; } = new();
    public DelayAnalyticsDto Delays { get; set; } = new();
    public ProgressPhotoAnalyticsDto ProgressPhotos { get; set; } = new();
    public ActivityAnalyticsDto Activity { get; set; } = new();
}

public class MilestoneAnalyticsDto
{
    public int Total { get; set; }
    public int Completed { get; set; }
    public int InProgress { get; set; }
    public int NotStarted { get; set; }
    public int Delayed { get; set; }
    public double CompletionPercentage { get; set; }
}

public class TaskAnalyticsDto
{
    public int Total { get; set; }
    public int Completed { get; set; }
    public int InProgress { get; set; }
    public int NotStarted { get; set; }
    public int Delayed { get; set; }
    public double CompletionPercentage { get; set; }
}

public class MaterialAnalyticsDto
{
    public int Total { get; set; }
    public int Required { get; set; }
    public int Ordered { get; set; }
    public int Delivered { get; set; }
    public double CompletionPercentage { get; set; }
}

public class MaterialGatedAnalyticsDto
{
    public int BlockedMilestones { get; set; }
}

public class DelayAnalyticsDto
{
    public int DelayedTasks { get; set; }
    public int TotalDelayDays { get; set; }
    public double AverageDelayDays { get; set; }
    public int MaximumDelayDays { get; set; }
}

public class ProgressPhotoAnalyticsDto
{
    public int Total { get; set; }
}

public class ActivityAnalyticsDto
{
    public int TotalEvents { get; set; }
    public int PhotosUploaded { get; set; }
    public int MaterialsDelivered { get; set; }
    public int TasksCompleted { get; set; }
    public int MilestonesCompleted { get; set; }
}
