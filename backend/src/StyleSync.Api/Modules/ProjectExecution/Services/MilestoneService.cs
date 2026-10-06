using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.ProjectExecution.DTOs;
using StyleSync.Api.Modules.ProjectExecution.Interfaces;
using StyleSync.Api.Modules.ProjectExecution.Exceptions;
using StyleSync.Api.Modules.ProjectExecution.Models;

namespace StyleSync.Api.Modules.ProjectExecution.Services;

public class MilestoneService : IMilestoneService
{
    private readonly AppDbContext _context;

    public MilestoneService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<MilestoneDto>> GetAllAsync(Guid? projectId, MilestoneStatus? status)
    {
        var query = _context.ProjectMilestones.AsQueryable();

        if (projectId.HasValue)
        {
            query = query.Where(m => m.ProjectId == projectId.Value);
        }

        if (status.HasValue)
        {
            query = query.Where(m => m.Status == status.Value);
        }

        var milestones = await query.ToListAsync();

        return milestones.Select(MapToDto);
    }

    public async Task<MilestoneDto?> GetByIdAsync(Guid id)
    {
        var milestone = await _context.ProjectMilestones.FindAsync(id);
        if (milestone == null)
            return null;

        return MapToDto(milestone);
    }

    public async Task<MilestoneDto> CreateAsync(CreateMilestoneDto request)
    {
        if (request.DueDate < request.StartDate)
        {
            throw new ArgumentException("DueDate cannot be earlier than StartDate.");
        }

        var milestone = new ProjectMilestone
        {
            MilestoneId = Guid.NewGuid(),
            ProjectId = request.ProjectId,
            Name = request.Name,
            Description = request.Description,
            StartDate = request.StartDate,
            DueDate = request.DueDate,
            Status = MilestoneStatus.NotStarted,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _context.ProjectMilestones.Add(milestone);
        await _context.SaveChangesAsync();

        return MapToDto(milestone);
    }

    public async Task<MilestoneDto?> UpdateAsync(Guid id, UpdateMilestoneDto request)
    {
        if (request.DueDate < request.StartDate)
        {
            throw new ArgumentException("DueDate cannot be earlier than StartDate.");
        }

        var milestone = await _context.ProjectMilestones.FindAsync(id);
        if (milestone == null)
            return null;

        if (request.Status == MilestoneStatus.Completed && milestone.Status != MilestoneStatus.Completed)
        {
            var incompleteMaterials = await _context.ProjectMaterials
                .Where(m => m.MilestoneId == id && m.Status != MaterialStatus.Delivered)
                .Select(m => new IncompleteMaterialDto
                {
                    MaterialId = m.MaterialId,
                    Name = m.Name,
                    Status = m.Status.ToString()
                })
                .ToListAsync();

            if (incompleteMaterials.Any())
            {
                throw new MaterialCompletionGuardException(id, incompleteMaterials);
            }
        }

        milestone.Name = request.Name;
        milestone.Description = request.Description;
        milestone.StartDate = request.StartDate;
        milestone.DueDate = request.DueDate;
        milestone.Status = request.Status;
        milestone.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return MapToDto(milestone);
    }

    public async Task<bool> DeleteAsync(Guid id)
    {
        var milestone = await _context.ProjectMilestones
            .Include(m => m.Tasks)
            .Include(m => m.Materials)
            .Include(m => m.ProgressPhotos)
            .FirstOrDefaultAsync(m => m.MilestoneId == id);

        if (milestone == null)
            return false;

        // Check if deletion is safe (e.g. no dependent tasks exist)
        // If dependent records exist, EF Core DeleteBehavior dictates what happens.
        // For tasks it's Cascade, but the prompt says:
        // "If deletion is not safe because dependent records exist, return an appropriate conflict response instead of silently deleting data."
        if (milestone.Tasks.Any() || milestone.Materials.Any() || milestone.ProgressPhotos.Any())
        {
            throw new InvalidOperationException("Cannot delete milestone because it contains dependent records (tasks, materials, or photos).");
        }

        _context.ProjectMilestones.Remove(milestone);
        await _context.SaveChangesAsync();
        return true;
    }

    private static MilestoneDto MapToDto(ProjectMilestone m)
    {
        return new MilestoneDto
        {
            MilestoneId = m.MilestoneId,
            ProjectId = m.ProjectId,
            Name = m.Name,
            Description = m.Description,
            StartDate = m.StartDate,
            DueDate = m.DueDate,
            Status = m.Status,
            CreatedAt = m.CreatedAt,
            UpdatedAt = m.UpdatedAt
        };
    }
}
