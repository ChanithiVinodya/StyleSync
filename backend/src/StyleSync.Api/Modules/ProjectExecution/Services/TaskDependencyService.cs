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

public class TaskDependencyService : ITaskDependencyService
{
    private readonly AppDbContext _context;

    public TaskDependencyService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<TaskDependencyDto> CreateDependencyAsync(Guid taskId, CreateTaskDependencyDto request)
    {
        if (taskId == request.PrerequisiteTaskId)
        {
            throw new ArgumentException("A task cannot depend on itself.");
        }

        var task = await _context.ProjectTasks
            .Include(t => t.Milestone)
            .FirstOrDefaultAsync(t => t.TaskId == taskId);

        var prereq = await _context.ProjectTasks
            .Include(t => t.Milestone)
            .FirstOrDefaultAsync(t => t.TaskId == request.PrerequisiteTaskId);

        if (task == null || prereq == null)
        {
            throw new KeyNotFoundException("Task or prerequisite task not found.");
        }

        if (task.Milestone.ProjectId != prereq.Milestone.ProjectId)
        {
            throw new ArgumentException("Both tasks must belong to the same project.");
        }

        var exists = await _context.TaskDependencies
            .AnyAsync(d => d.TaskId == taskId && d.PrerequisiteTaskId == request.PrerequisiteTaskId);
            
        if (exists)
        {
            throw new InvalidOperationException("This task dependency already exists.");
        }

        if (await WouldCreateCycleAsync(taskId, request.PrerequisiteTaskId))
        {
            throw new ArgumentException("The dependency would create a circular dependency.");
        }

        var dependency = new TaskDependency
        {
            TaskDependencyId = Guid.NewGuid(),
            TaskId = taskId,
            PrerequisiteTaskId = request.PrerequisiteTaskId,
            CreatedAt = DateTime.UtcNow
        };

        _context.TaskDependencies.Add(dependency);
        await _context.SaveChangesAsync();

        return new TaskDependencyDto
        {
            TaskDependencyId = dependency.TaskDependencyId,
            TaskId = dependency.TaskId,
            PrerequisiteTaskId = dependency.PrerequisiteTaskId,
            CreatedAt = dependency.CreatedAt
        };
    }

    private async Task<bool> WouldCreateCycleAsync(Guid taskId, Guid prerequisiteTaskId)
    {
        // We want to add edge: prerequisiteTaskId -> taskId.
        // A cycle occurs if there is already a path from taskId to prerequisiteTaskId.
        // We will traverse the graph starting from taskId following the "dependents" relationships.
        
        var visited = new HashSet<Guid>();
        var queue = new Queue<Guid>();
        
        queue.Enqueue(taskId);

        while (queue.Count > 0)
        {
            var current = queue.Dequeue();
            
            if (current == prerequisiteTaskId)
            {
                return true;
            }

            if (!visited.Contains(current))
            {
                visited.Add(current);

                var dependents = await _context.TaskDependencies
                    .Where(d => d.PrerequisiteTaskId == current)
                    .Select(d => d.TaskId)
                    .ToListAsync();

                foreach (var dep in dependents)
                {
                    if (!visited.Contains(dep))
                    {
                        queue.Enqueue(dep);
                    }
                }
            }
        }

        return false;
    }

    public async Task<IEnumerable<TaskDependencyTaskDto>> GetPrerequisitesAsync(Guid taskId)
    {
        return await _context.TaskDependencies
            .Where(d => d.TaskId == taskId)
            .Include(d => d.PrerequisiteTask)
            .Select(d => new TaskDependencyTaskDto
            {
                TaskId = d.PrerequisiteTask.TaskId,
                Name = d.PrerequisiteTask.Name,
                Status = d.PrerequisiteTask.Status,
                StartDate = d.PrerequisiteTask.StartDate,
                DueDate = d.PrerequisiteTask.DueDate
            })
            .ToListAsync();
    }

    public async Task<IEnumerable<TaskDependencyTaskDto>> GetDependentsAsync(Guid taskId)
    {
        return await _context.TaskDependencies
            .Where(d => d.PrerequisiteTaskId == taskId)
            .Include(d => d.Task)
            .Select(d => new TaskDependencyTaskDto
            {
                TaskId = d.Task.TaskId,
                Name = d.Task.Name,
                Status = d.Task.Status,
                StartDate = d.Task.StartDate,
                DueDate = d.Task.DueDate
            })
            .ToListAsync();
    }

    public async Task<bool> DeleteDependencyAsync(Guid taskId, Guid prerequisiteTaskId)
    {
        var dependency = await _context.TaskDependencies
            .FirstOrDefaultAsync(d => d.TaskId == taskId && d.PrerequisiteTaskId == prerequisiteTaskId);

        if (dependency == null)
        {
            return false;
        }

        _context.TaskDependencies.Remove(dependency);
        await _context.SaveChangesAsync();
        return true;
    }
}
