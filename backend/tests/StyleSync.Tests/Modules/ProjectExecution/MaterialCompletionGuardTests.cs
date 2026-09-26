using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.ProjectExecution.Controllers;
using StyleSync.Api.Modules.ProjectExecution.DTOs;
using StyleSync.Api.Modules.ProjectExecution.Exceptions;
using StyleSync.Api.Modules.ProjectExecution.Models;
using StyleSync.Api.Modules.ProjectExecution.Services;
using Xunit;

namespace StyleSync.Tests.Modules.ProjectExecution;

public class MaterialCompletionGuardTests : IDisposable
{
    private readonly AppDbContext _context;
    private readonly MilestoneService _service;
    private readonly MilestonesController _controller;

    public MaterialCompletionGuardTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        _context = new AppDbContext(options);
        _service = new MilestoneService(_context);
        var dependencyService = new TaskDependencyService(_context);
        var taskService = new TaskService(_context, dependencyService);
        var materialService = new MaterialService(_context);

        _controller = new MilestonesController(_service, taskService, materialService);
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

    private async Task<ProjectMilestone> SeedMilestoneAsync()
    {
        var milestone = new ProjectMilestone
        {
            MilestoneId = Guid.NewGuid(),
            ProjectId = Guid.NewGuid(),
            Name = "Test Milestone",
            Status = MilestoneStatus.InProgress,
            StartDate = DateTime.UtcNow,
            DueDate = DateTime.UtcNow.AddDays(10),
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        _context.ProjectMilestones.Add(milestone);
        await _context.SaveChangesAsync();
        return milestone;
    }

    private async Task<ProjectMaterial> SeedMaterialAsync(Guid milestoneId, MaterialStatus status)
    {
        var material = new ProjectMaterial
        {
            MaterialId = Guid.NewGuid(),
            ProjectId = Guid.NewGuid(),
            MilestoneId = milestoneId,
            Name = "Test Material " + Guid.NewGuid().ToString().Substring(0, 4),
            Status = status,
            RequiredDate = DateTime.UtcNow.AddDays(5),
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        _context.ProjectMaterials.Add(material);
        await _context.SaveChangesAsync();
        return material;
    }

    [Fact]
    public async Task UpdateMilestone_ToCompleted_NoMaterials_ReturnsOk()
    {
        var milestone = await SeedMilestoneAsync();
        var request = new UpdateMilestoneDto
        {
            Name = milestone.Name,
            StartDate = milestone.StartDate,
            DueDate = milestone.DueDate,
            Status = MilestoneStatus.Completed
        };

        var result = await _controller.UpdateMilestone(milestone.MilestoneId, request);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var dto = Assert.IsType<MilestoneDto>(okResult.Value);
        Assert.Equal(MilestoneStatus.Completed, dto.Status);
    }

    [Fact]
    public async Task UpdateMilestone_ToCompleted_AllMaterialsDelivered_ReturnsOk()
    {
        var milestone = await SeedMilestoneAsync();
        await SeedMaterialAsync(milestone.MilestoneId, MaterialStatus.Delivered);
        await SeedMaterialAsync(milestone.MilestoneId, MaterialStatus.Delivered);

        var request = new UpdateMilestoneDto
        {
            Name = milestone.Name,
            StartDate = milestone.StartDate,
            DueDate = milestone.DueDate,
            Status = MilestoneStatus.Completed
        };

        var result = await _controller.UpdateMilestone(milestone.MilestoneId, request);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var dto = Assert.IsType<MilestoneDto>(okResult.Value);
        Assert.Equal(MilestoneStatus.Completed, dto.Status);
    }

    [Fact]
    public async Task UpdateMilestone_ToCompleted_OneIncompleteMaterial_ReturnsBadRequest()
    {
        var milestone = await SeedMilestoneAsync();
        await SeedMaterialAsync(milestone.MilestoneId, MaterialStatus.Delivered);
        var incomplete = await SeedMaterialAsync(milestone.MilestoneId, MaterialStatus.Ordered);

        var request = new UpdateMilestoneDto
        {
            Name = milestone.Name,
            StartDate = milestone.StartDate,
            DueDate = milestone.DueDate,
            Status = MilestoneStatus.Completed
        };

        var result = await _controller.UpdateMilestone(milestone.MilestoneId, request);

        var badRequestResult = Assert.IsType<BadRequestObjectResult>(result);
        var response = badRequestResult.Value;

        // Use reflection to assert anonymous type properties
        var messageProp = response.GetType().GetProperty("message");
        var message = (string)messageProp.GetValue(response);
        Assert.Contains("required materials have not been delivered", message);

        var incompleteMaterialsProp = response.GetType().GetProperty("incompleteMaterials");
        var incompleteMaterials = (IEnumerable<IncompleteMaterialDto>)incompleteMaterialsProp.GetValue(response);

        Assert.Single(incompleteMaterials);
        Assert.Equal(incomplete.MaterialId, incompleteMaterials.First().MaterialId);
    }

    [Fact]
    public async Task UpdateMilestone_ToCompleted_OtherMilestoneMaterial_DoesNotBlock()
    {
        var milestone = await SeedMilestoneAsync();
        var otherMilestone = await SeedMilestoneAsync();

        // This material belongs to another milestone and is not delivered
        await SeedMaterialAsync(otherMilestone.MilestoneId, MaterialStatus.Required);

        // Target milestone has all materials delivered
        await SeedMaterialAsync(milestone.MilestoneId, MaterialStatus.Delivered);

        var request = new UpdateMilestoneDto
        {
            Name = milestone.Name,
            StartDate = milestone.StartDate,
            DueDate = milestone.DueDate,
            Status = MilestoneStatus.Completed
        };

        var result = await _controller.UpdateMilestone(milestone.MilestoneId, request);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var dto = Assert.IsType<MilestoneDto>(okResult.Value);
        Assert.Equal(MilestoneStatus.Completed, dto.Status);
    }

    [Fact]
    public async Task UpdateMilestone_ToCompleted_MaterialBecomesDelivered_Succeeds()
    {
        var milestone = await SeedMilestoneAsync();
        var material = await SeedMaterialAsync(milestone.MilestoneId, MaterialStatus.Ordered);

        var request = new UpdateMilestoneDto
        {
            Name = milestone.Name,
            StartDate = milestone.StartDate,
            DueDate = milestone.DueDate,
            Status = MilestoneStatus.Completed
        };

        // First attempt fails
        var result1 = await _controller.UpdateMilestone(milestone.MilestoneId, request);
        Assert.IsType<BadRequestObjectResult>(result1);

        // Now deliver the material
        material.Status = MaterialStatus.Delivered;
        await _context.SaveChangesAsync();

        // Second attempt succeeds
        var result2 = await _controller.UpdateMilestone(milestone.MilestoneId, request);
        Assert.IsType<OkObjectResult>(result2);
    }
}
