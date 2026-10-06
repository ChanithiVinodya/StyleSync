using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.ProjectExecution.Models;
using StyleSync.Api.Modules.ProjectExecution.Services;
using Xunit;
using TaskStatus = StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus;

namespace StyleSync.Tests.Modules.ProjectExecution;

public class ProjectAnalyticsTests
{
    private AppDbContext GetDbContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
        return new AppDbContext(options);
    }

    [Fact]
    public async Task GetProjectAnalytics_ZeroData_ShouldReturnZeroValues()
    {
        // Arrange
        var db = GetDbContext();
        var service = new ProjectAnalyticsService(db);
        var projectId = Guid.NewGuid();

        // Act
        var result = await service.GetProjectAnalyticsAsync(projectId);

        // Assert
        Assert.Equal(0, result.OverallProgress);
        Assert.Equal(0, result.Tasks.Total);
        Assert.Equal(0, result.Tasks.CompletionPercentage);
        Assert.Equal(0, result.Milestones.Total);
        Assert.Equal(0, result.Materials.Total);
        Assert.Equal(0, result.Delays.DelayedTasks);
        Assert.Equal(0, result.MaterialGated.BlockedMilestones);
        Assert.Equal(0, result.ProgressPhotos.Total);
        Assert.Equal(0, result.Activity.TotalEvents);
    }

    [Fact]
    public async Task GetProjectAnalytics_TaskAnalytics_ShouldCalculateCorrectlyAndIsolateProject()
    {
        // Arrange
        var db = GetDbContext();
        var projectId1 = Guid.NewGuid();
        var projectId2 = Guid.NewGuid();

        var milestone1 = new ProjectMilestone { MilestoneId = Guid.NewGuid(), ProjectId = projectId1, Status = MilestoneStatus.NotStarted };
        var milestone2 = new ProjectMilestone { MilestoneId = Guid.NewGuid(), ProjectId = projectId2, Status = MilestoneStatus.NotStarted };
        db.ProjectMilestones.AddRange(milestone1, milestone2);

        // Project 1 Tasks
        db.ProjectTasks.Add(new ProjectTask { TaskId = Guid.NewGuid(), MilestoneId = milestone1.MilestoneId, Status = TaskStatus.Completed });
        db.ProjectTasks.Add(new ProjectTask { TaskId = Guid.NewGuid(), MilestoneId = milestone1.MilestoneId, Status = TaskStatus.Completed });
        db.ProjectTasks.Add(new ProjectTask { TaskId = Guid.NewGuid(), MilestoneId = milestone1.MilestoneId, Status = TaskStatus.Completed });
        db.ProjectTasks.Add(new ProjectTask { TaskId = Guid.NewGuid(), MilestoneId = milestone1.MilestoneId, Status = TaskStatus.InProgress });
        db.ProjectTasks.Add(new ProjectTask { TaskId = Guid.NewGuid(), MilestoneId = milestone1.MilestoneId, Status = TaskStatus.NotStarted });

        // Project 2 Tasks (should not affect P1)
        db.ProjectTasks.Add(new ProjectTask { TaskId = Guid.NewGuid(), MilestoneId = milestone2.MilestoneId, Status = TaskStatus.Completed });
        
        await db.SaveChangesAsync();

        var service = new ProjectAnalyticsService(db);

        // Act
        var result = await service.GetProjectAnalyticsAsync(projectId1);

        // Assert
        Assert.Equal(5, result.Tasks.Total);
        Assert.Equal(3, result.Tasks.Completed);
        Assert.Equal(1, result.Tasks.InProgress);
        Assert.Equal(1, result.Tasks.NotStarted);
        Assert.Equal(0, result.Tasks.Delayed);
        Assert.Equal(60.0, result.Tasks.CompletionPercentage);
        Assert.Equal(60.0, result.OverallProgress);
    }

    [Fact]
    public async Task GetProjectAnalytics_DelayAnalytics_ShouldCalculateDelaysCorrectly()
    {
        // Arrange
        var db = GetDbContext();
        var projectId = Guid.NewGuid();
        var milestone = new ProjectMilestone { MilestoneId = Guid.NewGuid(), ProjectId = projectId, Status = MilestoneStatus.InProgress };
        db.ProjectMilestones.Add(milestone);

        var currentDate = DateTime.UtcNow.Date;

        // Task delayed by 2 days
        db.ProjectTasks.Add(new ProjectTask { TaskId = Guid.NewGuid(), MilestoneId = milestone.MilestoneId, Status = TaskStatus.InProgress, DueDate = currentDate.AddDays(-2) });
        // Task delayed by 4 days
        db.ProjectTasks.Add(new ProjectTask { TaskId = Guid.NewGuid(), MilestoneId = milestone.MilestoneId, Status = TaskStatus.Delayed, DueDate = currentDate.AddDays(-4) });
        // Task delayed by 5 days
        db.ProjectTasks.Add(new ProjectTask { TaskId = Guid.NewGuid(), MilestoneId = milestone.MilestoneId, Status = TaskStatus.NotStarted, DueDate = currentDate.AddDays(-5) });
        
        // Not delayed
        db.ProjectTasks.Add(new ProjectTask { TaskId = Guid.NewGuid(), MilestoneId = milestone.MilestoneId, Status = TaskStatus.InProgress, DueDate = currentDate.AddDays(1) });
        // Completed but was delayed previously (should not count)
        db.ProjectTasks.Add(new ProjectTask { TaskId = Guid.NewGuid(), MilestoneId = milestone.MilestoneId, Status = TaskStatus.Completed, DueDate = currentDate.AddDays(-10) });

        await db.SaveChangesAsync();

        var service = new ProjectAnalyticsService(db);

        // Act
        var result = await service.GetProjectAnalyticsAsync(projectId);

        // Assert
        Assert.Equal(3, result.Delays.DelayedTasks); // 2 + 4 + 5 = 11 days
        Assert.Equal(11, result.Delays.TotalDelayDays);
        Assert.Equal(3.67, result.Delays.AverageDelayDays);
        Assert.Equal(5, result.Delays.MaximumDelayDays);
    }

    [Fact]
    public async Task GetProjectAnalytics_MaterialGatedAnalytics_ShouldDetectBlockedMilestones()
    {
        // Arrange
        var db = GetDbContext();
        var projectId = Guid.NewGuid();

        // Milestone A
        var milestoneA = new ProjectMilestone { MilestoneId = Guid.NewGuid(), ProjectId = projectId, Status = MilestoneStatus.InProgress };
        db.ProjectMilestones.Add(milestoneA);
        
        // Material 1 (Delivered)
        db.ProjectMaterials.Add(new ProjectMaterial { MaterialId = Guid.NewGuid(), ProjectId = projectId, MilestoneId = milestoneA.MilestoneId, Status = MaterialStatus.Delivered });
        // Material 2 (Delivered)
        db.ProjectMaterials.Add(new ProjectMaterial { MaterialId = Guid.NewGuid(), ProjectId = projectId, MilestoneId = milestoneA.MilestoneId, Status = MaterialStatus.Delivered });

        // Milestone B
        var milestoneB = new ProjectMilestone { MilestoneId = Guid.NewGuid(), ProjectId = projectId, Status = MilestoneStatus.InProgress };
        db.ProjectMilestones.Add(milestoneB);

        // Material 3 (Required - Not delivered yet) -> Blocks Milestone B
        db.ProjectMaterials.Add(new ProjectMaterial { MaterialId = Guid.NewGuid(), ProjectId = projectId, MilestoneId = milestoneB.MilestoneId, Status = MaterialStatus.Required });

        await db.SaveChangesAsync();

        var service = new ProjectAnalyticsService(db);

        // Act
        var result = await service.GetProjectAnalyticsAsync(projectId);

        // Assert
        Assert.Equal(1, result.MaterialGated.BlockedMilestones);
    }

    [Fact]
    public async Task GetProjectAnalytics_DateFiltering_ShouldOnlyFilterTimeBasedMetrics()
    {
        // Arrange
        var db = GetDbContext();
        var projectId = Guid.NewGuid();
        
        // Setup base data that will not be filtered
        var milestone = new ProjectMilestone { MilestoneId = Guid.NewGuid(), ProjectId = projectId, Status = MilestoneStatus.InProgress };
        db.ProjectMilestones.Add(milestone);
        db.ProjectTasks.Add(new ProjectTask { TaskId = Guid.NewGuid(), MilestoneId = milestone.MilestoneId, Status = TaskStatus.NotStarted });

        var from = DateTime.UtcNow.AddDays(-10);
        var to = DateTime.UtcNow.AddDays(10);

        // Before range
        db.ProgressPhotos.Add(new ProgressPhoto { ProgressPhotoId = Guid.NewGuid(), ProjectId = projectId, UploadedAt = DateTime.UtcNow.AddDays(-20) });
        // Inside range
        db.ProgressPhotos.Add(new ProgressPhoto { ProgressPhotoId = Guid.NewGuid(), ProjectId = projectId, UploadedAt = DateTime.UtcNow });
        // After range
        db.ProgressPhotos.Add(new ProgressPhoto { ProgressPhotoId = Guid.NewGuid(), ProjectId = projectId, UploadedAt = DateTime.UtcNow.AddDays(20) });

        await db.SaveChangesAsync();

        var service = new ProjectAnalyticsService(db);

        // Act
        var result = await service.GetProjectAnalyticsAsync(projectId, from, to);

        // Assert
        // Static metrics should remain unfiltered
        Assert.Equal(1, result.Tasks.Total);
        Assert.Equal(1, result.Milestones.Total);

        // Time-based metrics should be filtered
        Assert.Equal(1, result.ProgressPhotos.Total);
        Assert.Equal(1, result.Activity.TotalEvents);
    }
}
