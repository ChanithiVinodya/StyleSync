using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
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

public class MilestoneCrudTests : IDisposable
{
    private readonly AppDbContext _context;
    private readonly MilestoneService _service;
    private readonly TaskService _taskService;
    private readonly MilestonesController _controller;

    public MilestoneCrudTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        _context = new AppDbContext(options);
        _service = new MilestoneService(_context);
        _taskService = new TaskService(_context);
        
        _controller = new MilestonesController(_service, _taskService);
        
        // Mocking user context for authorization is normally done via ControllerContext in integration tests.
        // For unit tests, we're primarily testing logic, but we can set up HttpContext if needed.
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
    public async Task Create_ValidMilestone_ReturnsCreated()
    {
        var dto = new CreateMilestoneDto
        {
            ProjectId = Guid.NewGuid(),
            Name = "Design Phase",
            Description = "Initial designs",
            StartDate = DateTime.UtcNow.AddDays(1),
            DueDate = DateTime.UtcNow.AddDays(10)
        };

        var result = await _controller.CreateMilestone(dto);

        var createdResult = Assert.IsType<CreatedAtActionResult>(result);
        var returnedDto = Assert.IsType<MilestoneDto>(createdResult.Value);
        
        Assert.Equal("Design Phase", returnedDto.Name);
        Assert.Equal(MilestoneStatus.NotStarted, returnedDto.Status);
    }

    [Fact]
    public async Task Create_InvalidDateRange_ReturnsBadRequest()
    {
        var dto = new CreateMilestoneDto
        {
            ProjectId = Guid.NewGuid(),
            Name = "Design Phase",
            StartDate = DateTime.UtcNow.AddDays(10),
            DueDate = DateTime.UtcNow.AddDays(1) // Due before start
        };

        var result = await _controller.CreateMilestone(dto);

        var badRequestResult = Assert.IsType<BadRequestObjectResult>(result);
        var error = Assert.IsType<ErrorResponse>(badRequestResult.Value);
        Assert.Equal("DueDate cannot be earlier than StartDate.", error.Message);
    }

    [Fact]
    public async Task GetAll_ReturnsMilestones_AndFiltersCorrectly()
    {
        var pId1 = Guid.NewGuid();
        var pId2 = Guid.NewGuid();

        _context.ProjectMilestones.AddRange(
            new ProjectMilestone { MilestoneId = Guid.NewGuid(), ProjectId = pId1, Name = "M1", Status = MilestoneStatus.NotStarted },
            new ProjectMilestone { MilestoneId = Guid.NewGuid(), ProjectId = pId1, Name = "M2", Status = MilestoneStatus.InProgress },
            new ProjectMilestone { MilestoneId = Guid.NewGuid(), ProjectId = pId2, Name = "M3", Status = MilestoneStatus.NotStarted }
        );
        await _context.SaveChangesAsync();

        // Get all
        var res1 = await _controller.GetAllMilestones(null, null);
        var ok1 = Assert.IsType<OkObjectResult>(res1);
        var list1 = Assert.IsAssignableFrom<IEnumerable<MilestoneDto>>(ok1.Value);
        Assert.Equal(3, list1.Count());

        // Filter by projectId
        var res2 = await _controller.GetAllMilestones(pId1, null);
        var ok2 = Assert.IsType<OkObjectResult>(res2);
        var list2 = Assert.IsAssignableFrom<IEnumerable<MilestoneDto>>(ok2.Value);
        Assert.Equal(2, list2.Count());

        // Filter by status
        var res3 = await _controller.GetAllMilestones(null, MilestoneStatus.InProgress);
        var ok3 = Assert.IsType<OkObjectResult>(res3);
        var list3 = Assert.IsAssignableFrom<IEnumerable<MilestoneDto>>(ok3.Value);
        Assert.Single(list3);
        Assert.Equal("M2", list3.First().Name);
    }

    [Fact]
    public async Task GetById_ReturnsMilestone_WhenExists()
    {
        var id = Guid.NewGuid();
        _context.ProjectMilestones.Add(new ProjectMilestone { MilestoneId = id, ProjectId = Guid.NewGuid(), Name = "M1" });
        await _context.SaveChangesAsync();

        var result = await _controller.GetMilestoneById(id);
        var ok = Assert.IsType<OkObjectResult>(result);
        var dto = Assert.IsType<MilestoneDto>(ok.Value);
        Assert.Equal(id, dto.MilestoneId);
    }

    [Fact]
    public async Task GetById_ReturnsNotFound_WhenDoesNotExist()
    {
        var result = await _controller.GetMilestoneById(Guid.NewGuid());
        Assert.IsType<NotFoundObjectResult>(result);
    }

    [Fact]
    public async Task GetTasksForMilestone_ReturnsTasks_WhenMilestoneExists()
    {
        var milestoneId = Guid.NewGuid();
        _context.ProjectMilestones.Add(new ProjectMilestone { MilestoneId = milestoneId, ProjectId = Guid.NewGuid(), Name = "M1" });
        _context.ProjectTasks.Add(new ProjectTask { TaskId = Guid.NewGuid(), MilestoneId = milestoneId, Name = "T1" });
        await _context.SaveChangesAsync();

        var result = await _controller.GetTasksForMilestone(milestoneId);
        var ok = Assert.IsType<OkObjectResult>(result);
        var tasks = Assert.IsAssignableFrom<IEnumerable<TaskDto>>(ok.Value);
        Assert.Single(tasks);
    }

    [Fact]
    public async Task GetTasksForMilestone_ReturnsNotFound_WhenMilestoneDoesNotExist()
    {
        var result = await _controller.GetTasksForMilestone(Guid.NewGuid());
        Assert.IsType<NotFoundObjectResult>(result);
    }

    [Fact]
    public async Task Update_UpdatesFields_AndSetsUpdatedAt()
    {
        var id = Guid.NewGuid();
        var original = new ProjectMilestone 
        { 
            MilestoneId = id, 
            ProjectId = Guid.NewGuid(), 
            Name = "M1",
            StartDate = DateTime.UtcNow,
            DueDate = DateTime.UtcNow.AddDays(5),
            CreatedAt = DateTime.UtcNow.AddDays(-1)
        };
        _context.ProjectMilestones.Add(original);
        await _context.SaveChangesAsync();

        var dto = new UpdateMilestoneDto
        {
            Name = "M1 Updated",
            Description = "Desc",
            StartDate = original.StartDate,
            DueDate = original.DueDate.AddDays(2),
            Status = MilestoneStatus.InProgress
        };

        var result = await _controller.UpdateMilestone(id, dto);
        var ok = Assert.IsType<OkObjectResult>(result);
        var returnedDto = Assert.IsType<MilestoneDto>(ok.Value);

        Assert.Equal("M1 Updated", returnedDto.Name);
        Assert.Equal(MilestoneStatus.InProgress, returnedDto.Status);
        Assert.NotNull(returnedDto.UpdatedAt);
    }

    [Fact]
    public async Task Delete_RemovesMilestone_WhenNoDependencies()
    {
        var id = Guid.NewGuid();
        _context.ProjectMilestones.Add(new ProjectMilestone { MilestoneId = id, ProjectId = Guid.NewGuid(), Name = "M1" });
        await _context.SaveChangesAsync();

        var result = await _controller.DeleteMilestone(id);
        Assert.IsType<NoContentResult>(result);

        Assert.Empty(_context.ProjectMilestones);
    }

    [Fact]
    public async Task Delete_ReturnsConflict_WhenTasksExist()
    {
        var id = Guid.NewGuid();
        var milestone = new ProjectMilestone 
        { 
            MilestoneId = id, 
            ProjectId = Guid.NewGuid(), 
            Name = "M1" 
        };
        milestone.Tasks.Add(new ProjectTask { TaskId = Guid.NewGuid(), Name = "T1" });
        
        _context.ProjectMilestones.Add(milestone);
        await _context.SaveChangesAsync();

        var result = await _controller.DeleteMilestone(id);
        var conflict = Assert.IsType<ConflictObjectResult>(result);
        var error = Assert.IsType<ErrorResponse>(conflict.Value);
        Assert.Contains("Cannot delete milestone", error.Message);
    }
}
