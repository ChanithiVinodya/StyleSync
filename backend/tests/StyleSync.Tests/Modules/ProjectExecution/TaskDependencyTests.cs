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

public class TaskDependencyTests : IDisposable
{
    private readonly AppDbContext _context;
    private readonly TaskDependencyService _service;
    private readonly TaskDependenciesController _controller;

    public TaskDependencyTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        _context = new AppDbContext(options);
        _service = new TaskDependencyService(_context);
        
        _controller = new TaskDependenciesController(_service);
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

    private async Task<(Guid pId, Guid mId, Guid t1, Guid t2, Guid t3)> SeedTasksAsync()
    {
        var pId = Guid.NewGuid();
        var mId = Guid.NewGuid();
        var t1 = Guid.NewGuid();
        var t2 = Guid.NewGuid();
        var t3 = Guid.NewGuid();

        _context.ProjectMilestones.Add(new ProjectMilestone { MilestoneId = mId, ProjectId = pId, Name = "M1" });
        _context.ProjectTasks.AddRange(
            new ProjectTask { TaskId = t1, MilestoneId = mId, Name = "T1" },
            new ProjectTask { TaskId = t2, MilestoneId = mId, Name = "T2" },
            new ProjectTask { TaskId = t3, MilestoneId = mId, Name = "T3" }
        );
        await _context.SaveChangesAsync();
        
        return (pId, mId, t1, t2, t3);
    }

    [Fact]
    public async Task CreateDependency_Valid_ReturnsCreated()
    {
        var (_, _, t1, t2, _) = await SeedTasksAsync();
        
        var dto = new CreateTaskDependencyDto { PrerequisiteTaskId = t1 };
        var result = await _controller.CreateDependency(t2, dto);

        var createdResult = Assert.IsType<ObjectResult>(result);
        Assert.Equal(201, createdResult.StatusCode);
        var returnedDto = Assert.IsType<TaskDependencyDto>(createdResult.Value);
        
        Assert.Equal(t2, returnedDto.TaskId);
        Assert.Equal(t1, returnedDto.PrerequisiteTaskId);
    }

    [Fact]
    public async Task CreateDependency_SelfDependency_ReturnsBadRequest()
    {
        var (_, _, t1, _, _) = await SeedTasksAsync();
        
        var dto = new CreateTaskDependencyDto { PrerequisiteTaskId = t1 };
        var result = await _controller.CreateDependency(t1, dto);

        var badRequestResult = Assert.IsType<BadRequestObjectResult>(result);
        var error = Assert.IsType<ErrorResponse>(badRequestResult.Value);
        Assert.Equal("A task cannot depend on itself.", error.Message);
    }

    [Fact]
    public async Task CreateDependency_CrossProject_ReturnsBadRequest()
    {
        var (_, m1, t1, _, _) = await SeedTasksAsync();
        var m2 = Guid.NewGuid();
        var t4 = Guid.NewGuid();
        _context.ProjectMilestones.Add(new ProjectMilestone { MilestoneId = m2, ProjectId = Guid.NewGuid(), Name = "M2" });
        _context.ProjectTasks.Add(new ProjectTask { TaskId = t4, MilestoneId = m2, Name = "T4" });
        await _context.SaveChangesAsync();
        
        var dto = new CreateTaskDependencyDto { PrerequisiteTaskId = t4 };
        var result = await _controller.CreateDependency(t1, dto);

        var badRequestResult = Assert.IsType<BadRequestObjectResult>(result);
        var error = Assert.IsType<ErrorResponse>(badRequestResult.Value);
        Assert.Equal("Both tasks must belong to the same project.", error.Message);
    }

    [Fact]
    public async Task CreateDependency_Duplicate_ReturnsConflict()
    {
        var (_, _, t1, t2, _) = await SeedTasksAsync();
        _context.TaskDependencies.Add(new TaskDependency { TaskId = t2, PrerequisiteTaskId = t1 });
        await _context.SaveChangesAsync();
        
        var dto = new CreateTaskDependencyDto { PrerequisiteTaskId = t1 };
        var result = await _controller.CreateDependency(t2, dto);

        var conflictResult = Assert.IsType<ConflictObjectResult>(result);
        var error = Assert.IsType<ErrorResponse>(conflictResult.Value);
        Assert.Equal("This task dependency already exists.", error.Message);
    }

    [Fact]
    public async Task CreateDependency_DirectCycle_ReturnsBadRequest()
    {
        var (_, _, t1, t2, _) = await SeedTasksAsync();
        // t2 depends on t1
        _context.TaskDependencies.Add(new TaskDependency { TaskId = t2, PrerequisiteTaskId = t1 });
        await _context.SaveChangesAsync();
        
        // try to make t1 depend on t2
        var dto = new CreateTaskDependencyDto { PrerequisiteTaskId = t2 };
        var result = await _controller.CreateDependency(t1, dto);

        var badRequestResult = Assert.IsType<BadRequestObjectResult>(result);
        var error = Assert.IsType<ErrorResponse>(badRequestResult.Value);
        Assert.Equal("The dependency would create a circular dependency.", error.Message);
    }

    [Fact]
    public async Task CreateDependency_IndirectCycle_ReturnsBadRequest()
    {
        var (_, _, t1, t2, t3) = await SeedTasksAsync();
        // t2 depends on t1, t3 depends on t2
        _context.TaskDependencies.Add(new TaskDependency { TaskId = t2, PrerequisiteTaskId = t1 });
        _context.TaskDependencies.Add(new TaskDependency { TaskId = t3, PrerequisiteTaskId = t2 });
        await _context.SaveChangesAsync();
        
        // try to make t1 depend on t3 (cycle: t1->t3->t2->t1)
        var dto = new CreateTaskDependencyDto { PrerequisiteTaskId = t3 };
        var result = await _controller.CreateDependency(t1, dto);

        var badRequestResult = Assert.IsType<BadRequestObjectResult>(result);
        var error = Assert.IsType<ErrorResponse>(badRequestResult.Value);
        Assert.Equal("The dependency would create a circular dependency.", error.Message);
    }

    [Fact]
    public async Task CreateDependency_TaskNotFound_ReturnsNotFound()
    {
        var (_, _, t1, _, _) = await SeedTasksAsync();
        
        var dto = new CreateTaskDependencyDto { PrerequisiteTaskId = t1 };
        var result = await _controller.CreateDependency(Guid.NewGuid(), dto);

        var notFoundResult = Assert.IsType<NotFoundObjectResult>(result);
        var error = Assert.IsType<ErrorResponse>(notFoundResult.Value);
        Assert.Equal("Task or prerequisite task not found.", error.Message);
    }

    [Fact]
    public async Task CreateDependency_PrerequisiteNotFound_ReturnsNotFound()
    {
        var (_, _, t1, _, _) = await SeedTasksAsync();
        
        var dto = new CreateTaskDependencyDto { PrerequisiteTaskId = Guid.NewGuid() };
        var result = await _controller.CreateDependency(t1, dto);

        var notFoundResult = Assert.IsType<NotFoundObjectResult>(result);
        var error = Assert.IsType<ErrorResponse>(notFoundResult.Value);
        Assert.Equal("Task or prerequisite task not found.", error.Message);
    }

    [Fact]
    public async Task GetPrerequisites_ReturnsCorrectTasks()
    {
        var (_, _, t1, t2, t3) = await SeedTasksAsync();
        // t3 depends on t1 and t2
        _context.TaskDependencies.Add(new TaskDependency { TaskId = t3, PrerequisiteTaskId = t1 });
        _context.TaskDependencies.Add(new TaskDependency { TaskId = t3, PrerequisiteTaskId = t2 });
        await _context.SaveChangesAsync();
        
        var result = await _controller.GetPrerequisites(t3);
        var okResult = Assert.IsType<OkObjectResult>(result);
        var dtos = Assert.IsAssignableFrom<IEnumerable<TaskDependencyTaskDto>>(okResult.Value);
        
        Assert.Equal(2, dtos.Count());
        Assert.Contains(dtos, d => d.TaskId == t1);
        Assert.Contains(dtos, d => d.TaskId == t2);
    }

    [Fact]
    public async Task GetDependents_ReturnsCorrectTasks()
    {
        var (_, _, t1, t2, t3) = await SeedTasksAsync();
        // t2 and t3 depend on t1
        _context.TaskDependencies.Add(new TaskDependency { TaskId = t2, PrerequisiteTaskId = t1 });
        _context.TaskDependencies.Add(new TaskDependency { TaskId = t3, PrerequisiteTaskId = t1 });
        await _context.SaveChangesAsync();
        
        var result = await _controller.GetDependents(t1);
        var okResult = Assert.IsType<OkObjectResult>(result);
        var dtos = Assert.IsAssignableFrom<IEnumerable<TaskDependencyTaskDto>>(okResult.Value);
        
        Assert.Equal(2, dtos.Count());
        Assert.Contains(dtos, d => d.TaskId == t2);
        Assert.Contains(dtos, d => d.TaskId == t3);
    }

    [Fact]
    public async Task DeleteDependency_Valid_ReturnsNoContent()
    {
        var (_, _, t1, t2, _) = await SeedTasksAsync();
        _context.TaskDependencies.Add(new TaskDependency { TaskId = t2, PrerequisiteTaskId = t1 });
        await _context.SaveChangesAsync();
        
        var result = await _controller.DeleteDependency(t2, t1);
        Assert.IsType<NoContentResult>(result);
        
        Assert.Empty(_context.TaskDependencies);
    }

    [Fact]
    public async Task DeleteDependency_NotFound_ReturnsNotFound()
    {
        var (_, _, t1, t2, _) = await SeedTasksAsync();
        var result = await _controller.DeleteDependency(t2, t1);
        
        var notFoundResult = Assert.IsType<NotFoundObjectResult>(result);
        var error = Assert.IsType<ErrorResponse>(notFoundResult.Value);
        Assert.Equal("Task dependency not found.", error.Message);
    }
}
