using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.ProjectExecution.DTOs;
using StyleSync.Api.Modules.ProjectExecution.Interfaces;
using StyleSync.Api.Modules.ProjectExecution.Models;

namespace StyleSync.Api.Modules.ProjectExecution.Services;

public class MaterialService : IMaterialService
{
    private readonly AppDbContext _context;

    public MaterialService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<MaterialDto> CreateAsync(CreateMaterialDto request)
    {
        await ValidateRelationshipsAsync(request.ProjectId, request.MilestoneId, request.TaskId);

        var material = new ProjectMaterial
        {
            MaterialId = Guid.NewGuid(),
            ProjectId = request.ProjectId,
            MilestoneId = request.MilestoneId,
            TaskId = request.TaskId,
            Name = request.Name,
            Description = request.Description,
            Quantity = request.Quantity,
            Unit = request.Unit,
            RequiredDate = request.RequiredDate,
            Status = MaterialStatus.Required,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _context.ProjectMaterials.Add(material);
        await _context.SaveChangesAsync();

        return MapToDto(material);
    }

    public async Task<IEnumerable<MaterialDto>> GetAllAsync(Guid? projectId = null, Guid? milestoneId = null, Guid? taskId = null, string? status = null)
    {
        var query = _context.ProjectMaterials.AsQueryable();

        if (projectId.HasValue) query = query.Where(m => m.ProjectId == projectId.Value);
        if (milestoneId.HasValue) query = query.Where(m => m.MilestoneId == milestoneId.Value);
        if (taskId.HasValue) query = query.Where(m => m.TaskId == taskId.Value);
        
        if (!string.IsNullOrEmpty(status) && Enum.TryParse<MaterialStatus>(status, true, out var parsedStatus))
        {
            query = query.Where(m => m.Status == parsedStatus);
        }

        var materials = await query.ToListAsync();
        return materials.Select(MapToDto);
    }

    public async Task<MaterialDto?> GetByIdAsync(Guid materialId)
    {
        var material = await _context.ProjectMaterials.FindAsync(materialId);
        if (material == null) return null;

        return MapToDto(material);
    }

    public async Task<MaterialDto?> UpdateAsync(Guid materialId, UpdateMaterialDto request)
    {
        var material = await _context.ProjectMaterials.FindAsync(materialId);
        if (material == null) return null;

        await ValidateRelationshipsAsync(material.ProjectId, request.MilestoneId, request.TaskId);

        material.Name = request.Name;
        material.Description = request.Description;
        material.Quantity = request.Quantity;
        material.Unit = request.Unit;
        material.RequiredDate = request.RequiredDate;
        material.MilestoneId = request.MilestoneId;
        material.TaskId = request.TaskId;
        material.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return MapToDto(material);
    }

    public async Task<bool> DeleteAsync(Guid materialId)
    {
        var material = await _context.ProjectMaterials.FindAsync(materialId);
        if (material == null) return false;

        _context.ProjectMaterials.Remove(material);
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<MaterialDto?> UpdateStatusAsync(Guid materialId, UpdateMaterialStatusDto request)
    {
        var material = await _context.ProjectMaterials.FindAsync(materialId);
        if (material == null) return null;

        var oldStatus = material.Status;
        material.Status = request.Status;

        if (request.Status == MaterialStatus.Ordered && oldStatus != MaterialStatus.Ordered && oldStatus != MaterialStatus.Delivered)
        {
            material.OrderedDate = DateTime.UtcNow;
        }
        else if (request.Status == MaterialStatus.Delivered && oldStatus != MaterialStatus.Delivered)
        {
            // If going straight to delivered from required, set ordered date too if null?
            if (material.OrderedDate == null)
            {
                material.OrderedDate = DateTime.UtcNow;
            }
            material.DeliveredDate = DateTime.UtcNow;
        }
        else if (request.Status == MaterialStatus.Required)
        {
            // Usually we wouldn't clear dates, but if it goes back to required, maybe it was a mistake?
            // "For status correction, allow backward transitions only when authorized and when they do not create inconsistent data."
            // "should not leave a misleading DeliveredDate if the existing business rules treat it as no longer delivered."
            if (oldStatus == MaterialStatus.Delivered) material.DeliveredDate = null;
            if (oldStatus == MaterialStatus.Ordered || oldStatus == MaterialStatus.Delivered)
            {
                material.OrderedDate = null;
                material.DeliveredDate = null; // Clear both if reverting all the way
            }
        }
        
        if (request.Status == MaterialStatus.Ordered && oldStatus == MaterialStatus.Delivered)
        {
            material.DeliveredDate = null; // reverting from delivered to ordered
        }

        material.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return MapToDto(material);
    }

    private async Task ValidateRelationshipsAsync(Guid projectId, Guid? milestoneId, Guid? taskId)
    {
        if (milestoneId.HasValue)
        {
            var milestone = await _context.ProjectMilestones.FindAsync(milestoneId.Value);
            if (milestone == null || milestone.ProjectId != projectId)
            {
                throw new ArgumentException("Invalid MilestoneId or Milestone does not belong to the specified Project.");
            }
        }

        if (taskId.HasValue)
        {
            var task = await _context.ProjectTasks.FindAsync(taskId.Value);
            if (task == null)
            {
                throw new ArgumentException("Invalid TaskId.");
            }

            var taskMilestone = await _context.ProjectMilestones.FindAsync(task.MilestoneId);
            if (taskMilestone == null || taskMilestone.ProjectId != projectId)
            {
                throw new ArgumentException("Task does not belong to the specified Project.");
            }
            
            // If both milestone and task are provided, they should match logically
            if (milestoneId.HasValue && task.MilestoneId != milestoneId.Value)
            {
                throw new ArgumentException("Task does not belong to the specified Milestone.");
            }
        }
    }

    private static MaterialDto MapToDto(ProjectMaterial material)
    {
        return new MaterialDto
        {
            MaterialId = material.MaterialId,
            ProjectId = material.ProjectId,
            MilestoneId = material.MilestoneId,
            TaskId = material.TaskId,
            Name = material.Name,
            Description = material.Description,
            Quantity = material.Quantity,
            Unit = material.Unit,
            RequiredDate = material.RequiredDate,
            OrderedDate = material.OrderedDate,
            DeliveredDate = material.DeliveredDate,
            Status = material.Status,
            CreatedAt = material.CreatedAt,
            UpdatedAt = material.UpdatedAt
        };
    }
}
