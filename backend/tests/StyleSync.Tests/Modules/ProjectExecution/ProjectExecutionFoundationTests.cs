using System;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.ProjectExecution.Models;
using Xunit;

namespace StyleSync.Tests.Modules.ProjectExecution;

public class ProjectExecutionFoundationTests
{
    [Fact]
    public void Can_Instantiate_Entities()
    {
        var milestone = new ProjectMilestone { Name = "Foundation Phase" };
        var task = new ProjectTask { Name = "Pour Concrete" };
        var dependency = new TaskDependency();
        var material = new ProjectMaterial { Name = "Cement" };
        var photo = new ProgressPhoto { ImageUrl = "http://example.com/photo.jpg" };

        Assert.NotNull(milestone);
        Assert.NotNull(task);
        Assert.NotNull(dependency);
        Assert.NotNull(material);
        Assert.NotNull(photo);

        Assert.Equal("Foundation Phase", milestone.Name);
    }

    [Fact]
    public void Enum_Values_Are_Valid()
    {
        // Assert some default/expected enum values exist
        Assert.Equal(0, (int)MilestoneStatus.NotStarted);
        Assert.Equal(1, (int)MilestoneStatus.InProgress);

        Assert.Equal(0, (int)StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.NotStarted);

        Assert.Equal(0, (int)MaterialStatus.Required);
        Assert.Equal(1, (int)MaterialStatus.Ordered);
        Assert.Equal(2, (int)MaterialStatus.Delivered);
    }

    [Fact]
    public void DbContext_Recognizes_DbSets()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: "Test_StyleSync_DbSets")
            .Options;

        using var context = new AppDbContext(options);

        // Verify that DbSets are accessible and not null
        Assert.NotNull(context.ProjectMilestones);
        Assert.NotNull(context.ProjectTasks);
        Assert.NotNull(context.TaskDependencies);
        Assert.NotNull(context.ProjectMaterials);
        Assert.NotNull(context.ProgressPhotos);
    }

    [Fact]
    public void EFCore_Relationships_Are_Configured_Correctly()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: "Test_StyleSync_Relationships")
            .Options;

        using var context = new AppDbContext(options);

        var model = context.Model;

        var milestoneType = model.FindEntityType(typeof(ProjectMilestone));
        Assert.NotNull(milestoneType);

        var taskType = model.FindEntityType(typeof(ProjectTask));
        Assert.NotNull(taskType);

        // Verify relationship: Milestone -> Tasks
        var milestoneToTasks = taskType.GetForeignKeys()
            .FirstOrDefault(fk => fk.PrincipalEntityType.ClrType == typeof(ProjectMilestone));

        Assert.NotNull(milestoneToTasks);
        Assert.Equal(DeleteBehavior.Cascade, milestoneToTasks.DeleteBehavior);

        // Verify TaskDependency relationships
        var dependencyType = model.FindEntityType(typeof(TaskDependency));
        Assert.NotNull(dependencyType);

        var fks = dependencyType.GetForeignKeys().ToList();
        Assert.Equal(2, fks.Count); // Should have FKs to Task and PrerequisiteTask
    }
}
