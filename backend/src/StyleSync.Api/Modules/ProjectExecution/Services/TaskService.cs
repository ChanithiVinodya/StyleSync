using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.ProjectExecution.DTOs;
using StyleSync.Api.Modules.ProjectExecution.Exceptions;
using StyleSync.Api.Modules.ProjectExecution.Interfaces;
using StyleSync.Api.Modules.ProjectExecution.Models;

namespace StyleSync.Api.Modules.ProjectExecution.Services;

public class TaskService : ITaskService
{
    private readonly AppDbContext _context;
    private readonly ITaskDependencyService _taskDependencyService;

    public TaskService(AppDbContext context, ITaskDependencyService taskDependencyService)
    {
        _context = context;
        _taskDependencyService = taskDependencyService;
    }

    public async Task<IEnumerable<TaskDto>> GetAllAsync(Guid? milestoneId, Models.TaskStatus? status)
    {
        var query = _context.ProjectTasks.AsQueryable();

        if (milestoneId.HasValue)
        {
            query = query.Where(t => t.MilestoneId == milestoneId.Value);
        }

        if (status.HasValue)
        {
            query = query.Where(t => t.Status == status.Value);
        }

        var tasks = await query.ToListAsync();

        return tasks.Select(MapToDto);
    }

    public async Task<TaskDto?> GetByIdAsync(Guid id)
    {
        var task = await _context.ProjectTasks.FindAsync(id);
        if (task == null)
            return null;

        return MapToDto(task);
    }

    public async Task<TaskDto> CreateAsync(CreateTaskDto request)
    {
        if (request.DueDate < request.StartDate)
        {
            throw new ArgumentException("DueDate cannot be earlier than StartDate.");
        }

        var milestoneExists = await _context.ProjectMilestones.AnyAsync(m => m.MilestoneId == request.MilestoneId);
        if (!milestoneExists)
        {
            throw new KeyNotFoundException("Milestone not found.");
        }

        var task = new ProjectTask
        {
            TaskId = Guid.NewGuid(),
            MilestoneId = request.MilestoneId,
            Name = request.Name,
            Description = request.Description,
            StartDate = request.StartDate,
            DueDate = request.DueDate,
            Status = Models.TaskStatus.NotStarted,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _context.ProjectTasks.Add(task);
        await _context.SaveChangesAsync();

        return MapToDto(task);
    }

    public async Task<TaskDto?> UpdateAsync(Guid id, UpdateTaskDto request)
    {
        if (request.DueDate < request.StartDate)
        {
            throw new ArgumentException("DueDate cannot be earlier than StartDate.");
        }

        var task = await _context.ProjectTasks.FindAsync(id);
        if (task == null)
            return null;

        if (request.Status == Models.TaskStatus.InProgress && task.Status != Models.TaskStatus.InProgress)
        {
            var prerequisites = await _taskDependencyService.GetPrerequisitesAsync(id);
            var incompletePrereqs = prerequisites.Where(p => p.Status != Models.TaskStatus.Completed).ToList();

            if (incompletePrereqs.Any())
            {
                throw new DependencyGuardException(id, incompletePrereqs);
            }
        }

        task.Name = request.Name;
        task.Description = request.Description;
        task.StartDate = request.StartDate;
        task.DueDate = request.DueDate;
        task.Status = request.Status;
        task.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return MapToDto(task);
    }

    public async Task<bool> DeleteAsync(Guid id)
    {
        var task = await _context.ProjectTasks
            .Include(t => t.Prerequisites)
            .Include(t => t.Dependents)
            .FirstOrDefaultAsync(t => t.TaskId == id);

        if (task == null)
            return false;

        if (task.Prerequisites.Any() || task.Dependents.Any())
        {
            throw new InvalidOperationException("Cannot delete task because it contains dependent records.");
        }

        _context.ProjectTasks.Remove(task);
        await _context.SaveChangesAsync();
        return true;
    }

    private static TaskDto MapToDto(ProjectTask t)
    {
        return new TaskDto
        {
            TaskId = t.TaskId,
            MilestoneId = t.MilestoneId,
            Name = t.Name,
            Description = t.Description,
            StartDate = t.StartDate,
            DueDate = t.DueDate,
            Status = t.Status,
            CreatedAt = t.CreatedAt,
            UpdatedAt = t.UpdatedAt
        };
    }
}
