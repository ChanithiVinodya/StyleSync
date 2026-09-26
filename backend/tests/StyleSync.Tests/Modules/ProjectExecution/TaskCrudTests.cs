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

public class TaskCrudTests : IDisposable
{
    private readonly AppDbContext _context;
    private readonly TaskService _service;
    private readonly TasksController _controller;

    public TaskCrudTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        _context = new AppDbContext(options);
        var dependencyService = new TaskDependencyService(_context);
        _service = new TaskService(_context, dependencyService);

        _controller = new TasksController(_service);

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

    [Fact]
    public async Task Create_ValidTask_ReturnsCreated()
    {
        var milestoneId = Guid.NewGuid();
        _context.ProjectMilestones.Add(new ProjectMilestone { MilestoneId = milestoneId, ProjectId = Guid.NewGuid(), Name = "M1" });
        await _context.SaveChangesAsync();

        var dto = new CreateTaskDto
        {
            MilestoneId = milestoneId,
            Name = "Paint walls",
            Description = "Apply two coats",
            StartDate = DateTime.UtcNow.AddDays(1),
            DueDate = DateTime.UtcNow.AddDays(3)
        };

        var result = await _controller.CreateTask(dto);

        var createdResult = Assert.IsType<CreatedAtActionResult>(result);
        var returnedDto = Assert.IsType<TaskDto>(createdResult.Value);

        Assert.Equal("Paint walls", returnedDto.Name);
        Assert.Equal(StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.NotStarted, returnedDto.Status);
    }

    [Fact]
    public async Task Create_InvalidDateRange_ReturnsBadRequest()
    {
        var dto = new CreateTaskDto
        {
            MilestoneId = Guid.NewGuid(),
            Name = "Paint walls",
            StartDate = DateTime.UtcNow.AddDays(10),
            DueDate = DateTime.UtcNow.AddDays(1) // Due before start
        };

        var result = await _controller.CreateTask(dto);

        var badRequestResult = Assert.IsType<BadRequestObjectResult>(result);
        var error = Assert.IsType<ErrorResponse>(badRequestResult.Value);
        Assert.Equal("DueDate cannot be earlier than StartDate.", error.Message);
    }

    [Fact]
    public async Task Create_MilestoneNotFound_ReturnsNotFound()
    {
        var dto = new CreateTaskDto
        {
            MilestoneId = Guid.NewGuid(),
            Name = "Paint walls",
            StartDate = DateTime.UtcNow.AddDays(1),
            DueDate = DateTime.UtcNow.AddDays(3)
        };

        var result = await _controller.CreateTask(dto);

        var notFoundResult = Assert.IsType<NotFoundObjectResult>(result);
        var error = Assert.IsType<ErrorResponse>(notFoundResult.Value);
        Assert.Equal("Milestone not found.", error.Message);
    }

    [Fact]
    public async Task GetAll_ReturnsTasks_AndFiltersCorrectly()
    {
        var mId1 = Guid.NewGuid();
        var mId2 = Guid.NewGuid();

        _context.ProjectTasks.AddRange(
            new ProjectTask { TaskId = Guid.NewGuid(), MilestoneId = mId1, Name = "T1", Status = StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.NotStarted },
            new ProjectTask { TaskId = Guid.NewGuid(), MilestoneId = mId1, Name = "T2", Status = StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.InProgress },
            new ProjectTask { TaskId = Guid.NewGuid(), MilestoneId = mId2, Name = "T3", Status = StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.NotStarted }
        );
        await _context.SaveChangesAsync();

        // Get all
        var res1 = await _controller.GetAllTasks(null, null);
        var ok1 = Assert.IsType<OkObjectResult>(res1);
        var list1 = Assert.IsAssignableFrom<IEnumerable<TaskDto>>(ok1.Value);
        Assert.Equal(3, list1.Count());

        // Filter by milestoneId
        var res2 = await _controller.GetAllTasks(mId1, null);
        var ok2 = Assert.IsType<OkObjectResult>(res2);
        var list2 = Assert.IsAssignableFrom<IEnumerable<TaskDto>>(ok2.Value);
        Assert.Equal(2, list2.Count());

        // Filter by status
        var res3 = await _controller.GetAllTasks(null, StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.InProgress);
        var ok3 = Assert.IsType<OkObjectResult>(res3);
        var list3 = Assert.IsAssignableFrom<IEnumerable<TaskDto>>(ok3.Value);
        Assert.Single(list3);
        Assert.Equal("T2", list3.First().Name);
    }

    [Fact]
    public async Task GetById_ReturnsTask_WhenExists()
    {
        var id = Guid.NewGuid();
        _context.ProjectTasks.Add(new ProjectTask { TaskId = id, MilestoneId = Guid.NewGuid(), Name = "T1" });
        await _context.SaveChangesAsync();

        var result = await _controller.GetTaskById(id);
        var ok = Assert.IsType<OkObjectResult>(result);
        var dto = Assert.IsType<TaskDto>(ok.Value);
        Assert.Equal(id, dto.TaskId);
    }

    [Fact]
    public async Task GetById_ReturnsNotFound_WhenDoesNotExist()
    {
        var result = await _controller.GetTaskById(Guid.NewGuid());
        Assert.IsType<NotFoundObjectResult>(result);
    }

    [Fact]
    public async Task Update_UpdatesFields_AndSetsUpdatedAt()
    {
        var id = Guid.NewGuid();
        var original = new ProjectTask
        {
            TaskId = id,
            MilestoneId = Guid.NewGuid(),
            Name = "T1",
            StartDate = DateTime.UtcNow,
            DueDate = DateTime.UtcNow.AddDays(5),
            CreatedAt = DateTime.UtcNow.AddDays(-1)
        };
        _context.ProjectTasks.Add(original);
        await _context.SaveChangesAsync();

        var dto = new UpdateTaskDto
        {
            Name = "T1 Updated",
            Description = "Desc",
            StartDate = original.StartDate,
            DueDate = original.DueDate.AddDays(2),
            Status = StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.InProgress
        };

        var result = await _controller.UpdateTask(id, dto);
        var ok = Assert.IsType<OkObjectResult>(result);
        var returnedDto = Assert.IsType<TaskDto>(ok.Value);

        Assert.Equal("T1 Updated", returnedDto.Name);
        Assert.Equal(StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.InProgress, returnedDto.Status);
        Assert.NotNull(returnedDto.UpdatedAt);
    }

    [Fact]
    public async Task Delete_RemovesTask_WhenNoDependencies()
    {
        var id = Guid.NewGuid();
        _context.ProjectTasks.Add(new ProjectTask { TaskId = id, MilestoneId = Guid.NewGuid(), Name = "T1" });
        await _context.SaveChangesAsync();

        var result = await _controller.DeleteTask(id);
        Assert.IsType<NoContentResult>(result);

        Assert.Empty(_context.ProjectTasks);
    }

    [Fact]
    public async Task Delete_ReturnsConflict_WhenDependenciesExist()
    {
        var id = Guid.NewGuid();
        var task = new ProjectTask
        {
            TaskId = id,
            MilestoneId = Guid.NewGuid(),
            Name = "T1"
        };
        task.Dependents.Add(new TaskDependency { TaskDependencyId = Guid.NewGuid() });

        _context.ProjectTasks.Add(task);
        await _context.SaveChangesAsync();

        var result = await _controller.DeleteTask(id);
        var conflict = Assert.IsType<ConflictObjectResult>(result);
        var error = Assert.IsType<ErrorResponse>(conflict.Value);
        Assert.Contains("Cannot delete task", error.Message);
    }
}
