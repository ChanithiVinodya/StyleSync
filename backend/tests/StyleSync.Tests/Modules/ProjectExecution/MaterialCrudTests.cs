using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.ProjectExecution.DTOs;
using StyleSync.Api.Modules.ProjectExecution.Models;
using StyleSync.Api.Modules.ProjectExecution.Services;
using Xunit;

namespace StyleSync.Tests.Modules.ProjectExecution;

public class MaterialCrudTests : IDisposable
{
    private readonly AppDbContext _context;
    private readonly MaterialService _service;
    private readonly Guid _projectId = Guid.NewGuid();
    private readonly Guid _milestoneId = Guid.NewGuid();
    private readonly Guid _taskId = Guid.NewGuid();

    public MaterialCrudTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        _context = new AppDbContext(options);
        _service = new MaterialService(_context);

        SeedData();
    }

    private void SeedData()
    {
        _context.ProjectMilestones.Add(new ProjectMilestone
        {
            MilestoneId = _milestoneId,
            ProjectId = _projectId,
            Name = "M1",
            Status = MilestoneStatus.NotStarted,
            CreatedAt = DateTime.UtcNow
        });

        _context.ProjectTasks.Add(new ProjectTask
        {
            TaskId = _taskId,
            MilestoneId = _milestoneId,
            Name = "T1",
            Status = StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus.NotStarted,
            CreatedAt = DateTime.UtcNow
        });

        _context.SaveChanges();
    }

    public void Dispose()
    {
        _context.Database.EnsureDeleted();
        _context.Dispose();
    }

    [Fact]
    public async Task CreateMaterial_ValidRequest_CreatesSuccessfully()
    {
        var dto = new CreateMaterialDto
        {
            ProjectId = _projectId,
            Name = "Paint",
            Quantity = 10,
            Unit = "Liters"
        };

        var result = await _service.CreateAsync(dto);

        Assert.NotNull(result);
        Assert.Equal("Paint", result.Name);
        Assert.Equal(MaterialStatus.Required, result.Status);

        var dbEntity = await _context.ProjectMaterials.FindAsync(result.MaterialId);
        Assert.NotNull(dbEntity);
        Assert.Equal(MaterialStatus.Required, dbEntity.Status);
    }

    [Fact]
    public async Task CreateMaterial_WithValidMilestone_CreatesSuccessfully()
    {
        var dto = new CreateMaterialDto
        {
            ProjectId = _projectId,
            MilestoneId = _milestoneId,
            Name = "Wood",
            Quantity = 20,
            Unit = "Planks"
        };

        var result = await _service.CreateAsync(dto);

        Assert.Equal(_milestoneId, result.MilestoneId);
    }

    [Fact]
    public async Task CreateMaterial_CrossProjectMilestone_ThrowsException()
    {
        var otherMilestone = Guid.NewGuid();
        _context.ProjectMilestones.Add(new ProjectMilestone
        {
            MilestoneId = otherMilestone,
            ProjectId = Guid.NewGuid(), // Different project
            Name = "M2",
            Status = MilestoneStatus.NotStarted,
            CreatedAt = DateTime.UtcNow
        });
        await _context.SaveChangesAsync();

        var dto = new CreateMaterialDto
        {
            ProjectId = _projectId,
            MilestoneId = otherMilestone,
            Name = "Wood",
            Quantity = 20,
            Unit = "Planks"
        };

        await Assert.ThrowsAsync<ArgumentException>(() => _service.CreateAsync(dto));
    }

    [Fact]
    public async Task GetAllMaterials_FiltersCorrectly()
    {
        await _service.CreateAsync(new CreateMaterialDto { ProjectId = _projectId, Name = "M1", Quantity = 1, Unit = "X", MilestoneId = _milestoneId });
        await _service.CreateAsync(new CreateMaterialDto { ProjectId = _projectId, Name = "M2", Quantity = 1, Unit = "X" });
        await _service.CreateAsync(new CreateMaterialDto { ProjectId = Guid.NewGuid(), Name = "M3", Quantity = 1, Unit = "X" });

        var projMaterials = await _service.GetAllAsync(projectId: _projectId);
        Assert.Equal(2, projMaterials.Count());

        var milestoneMaterials = await _service.GetAllAsync(milestoneId: _milestoneId);
        Assert.Single(milestoneMaterials);
    }

    [Fact]
    public async Task UpdateMaterial_UpdatesFieldsAndTimestamp()
    {
        var created = await _service.CreateAsync(new CreateMaterialDto
        {
            ProjectId = _projectId,
            Name = "Original",
            Quantity = 5,
            Unit = "kg"
        });

        var updateDto = new UpdateMaterialDto
        {
            Name = "Updated",
            Quantity = 10,
            Unit = "kg"
        };

        var result = await _service.UpdateAsync(created.MaterialId, updateDto);

        Assert.NotNull(result);
        Assert.Equal("Updated", result.Name);
        Assert.Equal(10, result.Quantity);
        
        var dbEntity = await _context.ProjectMaterials.FindAsync(created.MaterialId);
        Assert.Equal("Updated", dbEntity!.Name);
    }

    [Fact]
    public async Task DeleteMaterial_RemovesFromDatabase()
    {
        var created = await _service.CreateAsync(new CreateMaterialDto
        {
            ProjectId = _projectId,
            Name = "To Delete",
            Quantity = 1,
            Unit = "item"
        });

        var deleted = await _service.DeleteAsync(created.MaterialId);
        
        Assert.True(deleted);
        var dbEntity = await _context.ProjectMaterials.FindAsync(created.MaterialId);
        Assert.Null(dbEntity);
    }

    [Fact]
    public async Task UpdateStatus_RequiredToOrdered_SetsOrderedDate()
    {
        var created = await _service.CreateAsync(new CreateMaterialDto
        {
            ProjectId = _projectId,
            Name = "Test",
            Quantity = 1,
            Unit = "item"
        });

        var update = new UpdateMaterialStatusDto { Status = MaterialStatus.Ordered };
        var result = await _service.UpdateStatusAsync(created.MaterialId, update);

        Assert.Equal(MaterialStatus.Ordered, result!.Status);
        Assert.NotNull(result.OrderedDate);
        Assert.Null(result.DeliveredDate);
    }

    [Fact]
    public async Task UpdateStatus_OrderedToDelivered_SetsDeliveredDate()
    {
        var created = await _service.CreateAsync(new CreateMaterialDto
        {
            ProjectId = _projectId,
            Name = "Test",
            Quantity = 1,
            Unit = "item"
        });

        await _service.UpdateStatusAsync(created.MaterialId, new UpdateMaterialStatusDto { Status = MaterialStatus.Ordered });
        var result = await _service.UpdateStatusAsync(created.MaterialId, new UpdateMaterialStatusDto { Status = MaterialStatus.Delivered });

        Assert.Equal(MaterialStatus.Delivered, result!.Status);
        Assert.NotNull(result.OrderedDate);
        Assert.NotNull(result.DeliveredDate);
    }

    [Fact]
    public async Task UpdateStatus_RequiredToDelivered_SetsBothDates()
    {
        var created = await _service.CreateAsync(new CreateMaterialDto
        {
            ProjectId = _projectId,
            Name = "Test",
            Quantity = 1,
            Unit = "item"
        });

        var result = await _service.UpdateStatusAsync(created.MaterialId, new UpdateMaterialStatusDto { Status = MaterialStatus.Delivered });

        Assert.Equal(MaterialStatus.Delivered, result!.Status);
        Assert.NotNull(result.OrderedDate);
        Assert.NotNull(result.DeliveredDate);
    }
}
