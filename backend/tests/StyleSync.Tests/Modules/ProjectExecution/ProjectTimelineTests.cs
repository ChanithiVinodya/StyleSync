using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.ProjectExecution.Models;
using StyleSync.Api.Modules.ProjectExecution.Services;
using Xunit;

namespace StyleSync.Tests.Modules.ProjectExecution;

public class ProjectTimelineTests
{
    private AppDbContext GetDbContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
        return new AppDbContext(options);
    }

    [Fact]
    public async Task GetProjectTimeline_ShouldReturnCombinedEvents_SortedChronologically()
    {
        // Arrange
        var db = GetDbContext();
        var projectId = Guid.NewGuid();

        var milestone = new ProjectMilestone
        {
            MilestoneId = Guid.NewGuid(),
            ProjectId = projectId,
            Name = "M1",
            CreatedAt = DateTime.UtcNow.AddDays(-10)
        };
        db.ProjectMilestones.Add(milestone);

        var task = new ProjectTask
        {
            TaskId = Guid.NewGuid(),
            MilestoneId = milestone.MilestoneId,
            Name = "T1",
            CreatedAt = DateTime.UtcNow.AddDays(-9)
        };
        db.ProjectTasks.Add(task);

        var material = new ProjectMaterial
        {
            MaterialId = Guid.NewGuid(),
            ProjectId = projectId,
            Name = "Mat1",
            Status = MaterialStatus.Delivered,
            OrderedDate = DateTime.UtcNow.AddDays(-8),
            DeliveredDate = DateTime.UtcNow.AddDays(-2)
        };
        db.ProjectMaterials.Add(material);

        var photo = new ProgressPhoto
        {
            ProgressPhotoId = Guid.NewGuid(),
            ProjectId = projectId,
            UploadedAt = DateTime.UtcNow.AddDays(-1)
        };
        db.ProgressPhotos.Add(photo);

        await db.SaveChangesAsync();

        var service = new ProjectTimelineService(db);

        // Act
        var timeline = await service.GetProjectTimelineAsync(projectId);

        // Assert
        Assert.NotNull(timeline);
        Assert.Equal(5, timeline.Count()); // 1 Milestone created, 1 Task created, 1 Material ordered, 1 Material delivered, 1 Photo uploaded
        
        var events = timeline.ToList();
        // Should be sorted descending (most recent first)
        Assert.Equal("ProgressPhotoUploaded", events[0].EventType);
        Assert.Equal("MaterialDelivered", events[1].EventType);
        Assert.Equal("MaterialOrdered", events[2].EventType);
        Assert.Equal("TaskCreated", events[3].EventType);
        Assert.Equal("MilestoneCreated", events[4].EventType);
    }
}
