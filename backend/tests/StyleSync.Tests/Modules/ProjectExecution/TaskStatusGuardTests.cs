using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.DTOs;
using StyleSync.Api.Modules.ProjectExecution.Controllers;
using StyleSync.Api.Modules.ProjectExecution.DTOs;
using StyleSync.Api.Modules.ProjectExecution.Models;
using StyleSync.Api.Modules.ProjectExecution.Services;
using Xunit;

namespace StyleSync.Tests.Modules.ProjectExecution;

public class TaskStatusGuardTests : IDisposable
{
    private readonly AppDbContext _context;
    private readonly TaskService _taskService;
    private readonly TaskDependencyService _dependencyService;
    private readonly TasksController _controller;

    public TaskStatusGuardTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        _context = new AppDbContext(options);
        _dependencyService = new TaskDependencyService(_context);
        _taskService = new TaskService(_context, _dependencyService);
        
        _controller = new TasksController(_taskService);
        _controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext()
        };
    }

    public void Dispose()
    {
        _context.Database.EnsureDeleted();
        _context.Dispose();
    }

    private async Task<(Guid pId, Guid mId)> SeedProjectAsync()
    {
        var pId = Guid.NewGuid();
        var mId = Guid.NewGuid();
        _context.ProjectMilestones.Add(new ProjectMilestone { MilestoneId = mId, ProjectId = pId, Name = "M1" });
        await _context.SaveChangesAsync();
        return (pId, mId);
    }

    private async Task<ProjectTask> CreateTaskAsync(Guid mId, string name, StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus status)
    {
        var t = new ProjectTask
        {
            TaskId = Guid.NewGuid(),
            MilestoneId = mId,
            Name = name,
            StartDate = DateTime.UtcNow,
            DueDate = DateTime.UtcNow.AddDays(1),
            Status = status
        };
        _context.ProjectTasks.Add(t);
        await _context.SaveChangesAsync();
        return t;
    }

    private async Task AddDependencyAsync(Guid taskId, Guid prerequisiteTaskId)
    {
        _context.TaskDependencies.Add(new TaskDependency
        {
            TaskId = taskId,
            PrerequisiteTaskId = prerequisiteTaskId
        });
        await _context.SaveChangesAsync();
    }

    [Fact]
    public async Task UpdateStatus_NoPrerequisites_AllowsInProgress()
    {
        var (_, mId) = await SeedProjectAsync();
        var task = await CreateTaskAsync(mId, "Task A", StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.NotStarted);

        var dto = new UpdateTaskDto
        {
            Name = task.Name,
            Description = task.Description,
            StartDate = task.StartDate,
            DueDate = task.DueDate,
            Status = StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.InProgress
        };

        var result = await _controller.UpdateTask(task.TaskId, dto);
        
        var okResult = Assert.IsType<OkObjectResult>(result);
        var returnedDto = Assert.IsType<TaskDto>(okResult.Value);
        Assert.Equal(StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.InProgress, returnedDto.Status);
    }

    [Fact]
    public async Task UpdateStatus_AllPrerequisitesCompleted_AllowsInProgress()
    {
        var (_, mId) = await SeedProjectAsync();
        var t1 = await CreateTaskAsync(mId, "Task A", StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.Completed);
        var t2 = await CreateTaskAsync(mId, "Task B", StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.Completed);
        var t3 = await CreateTaskAsync(mId, "Task C", StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.NotStarted);

        await AddDependencyAsync(t3.TaskId, t1.TaskId);
        await AddDependencyAsync(t3.TaskId, t2.TaskId);

        var dto = new UpdateTaskDto
        {
            Name = t3.Name,
            StartDate = t3.StartDate,
            DueDate = t3.DueDate,
            Status = StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.InProgress
        };

        var result = await _controller.UpdateTask(t3.TaskId, dto);
        var okResult = Assert.IsType<OkObjectResult>(result);
        var returnedDto = Assert.IsType<TaskDto>(okResult.Value);
        Assert.Equal(StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.InProgress, returnedDto.Status);
    }

    [Fact]
    public async Task UpdateStatus_OnePrerequisiteIncomplete_ReturnsBadRequest()
    {
        var (_, mId) = await SeedProjectAsync();
        var t1 = await CreateTaskAsync(mId, "Task A", StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.Completed);
        var t2 = await CreateTaskAsync(mId, "Task B", StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.InProgress);
        var t3 = await CreateTaskAsync(mId, "Task C", StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.NotStarted);

        await AddDependencyAsync(t3.TaskId, t1.TaskId);
        await AddDependencyAsync(t3.TaskId, t2.TaskId);

        var dto = new UpdateTaskDto
        {
            Name = t3.Name,
            StartDate = t3.StartDate,
            DueDate = t3.DueDate,
            Status = StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.InProgress
        };

        var result = await _controller.UpdateTask(t3.TaskId, dto);
        
        var badRequest = Assert.IsType<BadRequestObjectResult>(result);
        // We know we return an anonymous object in the controller for this specific exception
        // Unfortunately anonymous objects are internal by default and hard to reflect on directly in tests if they are in different assemblies.
        // To be safe, since it's returned as an object, we can serialize it and check the properties or use dynamic.
        var json = System.Text.Json.JsonSerializer.Serialize(badRequest.Value);
        Assert.Contains("Task cannot start because prerequisite tasks are incomplete.", json);
        Assert.Contains(t2.TaskId.ToString(), json, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain(t1.TaskId.ToString(), json, StringComparison.OrdinalIgnoreCase); // T1 is complete
    }

    [Fact]
    public async Task UpdateStatus_MultiplePrerequisitesIncomplete_ReturnsBoth()
    {
        var (_, mId) = await SeedProjectAsync();
        var t1 = await CreateTaskAsync(mId, "Task A", StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.NotStarted);
        var t2 = await CreateTaskAsync(mId, "Task B", StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.InProgress);
        var t3 = await CreateTaskAsync(mId, "Task C", StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.Completed);
        var t4 = await CreateTaskAsync(mId, "Task D", StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.NotStarted);

        await AddDependencyAsync(t4.TaskId, t1.TaskId);
        await AddDependencyAsync(t4.TaskId, t2.TaskId);
        await AddDependencyAsync(t4.TaskId, t3.TaskId);

        var dto = new UpdateTaskDto
        {
            Name = t4.Name,
            StartDate = t4.StartDate,
            DueDate = t4.DueDate,
            Status = StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.InProgress
        };

        var result = await _controller.UpdateTask(t4.TaskId, dto);
        
        var badRequest = Assert.IsType<BadRequestObjectResult>(result);
        var json = System.Text.Json.JsonSerializer.Serialize(badRequest.Value);
        Assert.Contains("Task cannot start because prerequisite tasks are incomplete.", json);
        Assert.Contains(t1.TaskId.ToString(), json, StringComparison.OrdinalIgnoreCase);
        Assert.Contains(t2.TaskId.ToString(), json, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain(t3.TaskId.ToString(), json, StringComparison.OrdinalIgnoreCase); // T3 is complete
    }

    [Fact]
    public async Task UpdateStatus_DelayedPrerequisite_ReturnsBadRequest()
    {
        var (_, mId) = await SeedProjectAsync();
        var t1 = await CreateTaskAsync(mId, "Task A", StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.Delayed);
        var t2 = await CreateTaskAsync(mId, "Task B", StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.NotStarted);

        await AddDependencyAsync(t2.TaskId, t1.TaskId);

        var dto = new UpdateTaskDto
        {
            Name = t2.Name,
            StartDate = t2.StartDate,
            DueDate = t2.DueDate,
            Status = StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.InProgress
        };

        var result = await _controller.UpdateTask(t2.TaskId, dto);
        
        var badRequest = Assert.IsType<BadRequestObjectResult>(result);
        var json = System.Text.Json.JsonSerializer.Serialize(badRequest.Value);
        Assert.Contains(t1.TaskId.ToString(), json, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task UpdateStatus_DelayedToInProgress_StillRunsGuard()
    {
        var (_, mId) = await SeedProjectAsync();
        var t1 = await CreateTaskAsync(mId, "Task A", StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.NotStarted);
        var t2 = await CreateTaskAsync(mId, "Task B", StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.Delayed);

        await AddDependencyAsync(t2.TaskId, t1.TaskId);

        var dto = new UpdateTaskDto
        {
            Name = t2.Name,
            StartDate = t2.StartDate,
            DueDate = t2.DueDate,
            Status = StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.InProgress
        };

        var result = await _controller.UpdateTask(t2.TaskId, dto);
        
        var badRequest = Assert.IsType<BadRequestObjectResult>(result);
        var json = System.Text.Json.JsonSerializer.Serialize(badRequest.Value);
        Assert.Contains(t1.TaskId.ToString(), json, StringComparison.OrdinalIgnoreCase);
    }
}
