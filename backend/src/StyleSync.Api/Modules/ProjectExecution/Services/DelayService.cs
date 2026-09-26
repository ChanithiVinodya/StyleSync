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

public class DelayService : IDelayService
{
    private readonly AppDbContext _context;

    public DelayService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<DelayedTaskDto>> GetDelayedTasksAsync()
    {
        var currentDate = DateTime.UtcNow.Date;

        var tasks = await _context.ProjectTasks
            .Where(t => t.Status != Models.TaskStatus.Completed && t.DueDate.Date < currentDate)
            .ToListAsync();

        return tasks.Select(t => new DelayedTaskDto
        {
            TaskId = t.TaskId,
            Name = t.Name,
            DueDate = t.DueDate,
            Status = Models.TaskStatus.Delayed, // Reflects computed status or DB status
            DaysDelayed = (currentDate - t.DueDate.Date).Days
        });
    }

    public async Task<DelayDetectionResultDto> RunDelayDetectionAsync()
    {
        var currentDate = DateTime.UtcNow.Date;

        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var initialDelayedTasks = await _context.ProjectTasks
                .Where(t => t.Status != Models.TaskStatus.Completed && t.DueDate.Date < currentDate)
                .ToListAsync();

            var shiftDict = new Dictionary<Guid, int>();
            var queue = new Queue<ProjectTask>();
            int detectedTasksCount = 0;

            foreach (var task in initialDelayedTasks)
            {
                int totalDelay = (currentDate - task.DueDate.Date).Days;
                if (totalDelay < 0) totalDelay = 0;

                int newDelayToCascade = totalDelay - task.CascadedDelay;

                if (newDelayToCascade > 0)
                {
                    shiftDict[task.TaskId] = newDelayToCascade;
                    queue.Enqueue(task);
                    task.CascadedDelay = totalDelay;
                }

                if (task.Status != Models.TaskStatus.Delayed)
                {
                    task.Status = Models.TaskStatus.Delayed;
                    task.UpdatedAt = DateTime.UtcNow;
                }
                detectedTasksCount++;
            }

            var allIncompleteTasks = await _context.ProjectTasks
                .Where(t => t.Status != Models.TaskStatus.Completed)
                .ToDictionaryAsync(t => t.TaskId);

            var allDependencies = await _context.TaskDependencies.ToListAsync();
            var dependentsMap = allDependencies
                .GroupBy(d => d.PrerequisiteTaskId)
                .ToDictionary(g => g.Key, g => g.Select(d => d.TaskId).ToList());

            while (queue.Count > 0)
            {
                var current = queue.Dequeue();
                int currentShift = shiftDict[current.TaskId];

                if (dependentsMap.TryGetValue(current.TaskId, out var depIds))
                {
                    foreach (var depId in depIds)
                    {
                        if (allIncompleteTasks.TryGetValue(depId, out var depTask))
                        {
                            int existingShift = shiftDict.GetValueOrDefault(depId, 0);
                            if (currentShift > existingShift)
                            {
                                shiftDict[depId] = currentShift;
                                queue.Enqueue(depTask);
                            }
                        }
                    }
                }
            }

            int cascadeUpdatedCount = 0;
            foreach (var kvp in shiftDict)
            {
                var taskId = kvp.Key;
                int shiftDays = kvp.Value;

                // Shift dependent tasks. 
                // Initial delayed tasks maintain their original DueDate and record CascadedDelay to ensure idempotency.
                if (shiftDays > 0 && allIncompleteTasks.TryGetValue(taskId, out var taskToUpdate))
                {
                    // Do not shift the initial delayed task's own dates unless it is ALSO a dependent 
                    // that received a LARGER shift from a prerequisite.
                    var isInitialDelayed = initialDelayedTasks.Any(t => t.TaskId == taskId);

                    // If it's an initial delayed task, we only shift its dates if it inherited a shift
                    // larger than its own delay (which would be extremely rare/impossible unless dependencies were set up weirdly).
                    // Actually, to keep it simple, we just don't shift initial delayed tasks. 
                    if (!isInitialDelayed)
                    {
                        taskToUpdate.StartDate = taskToUpdate.StartDate.AddDays(shiftDays);
                        taskToUpdate.DueDate = taskToUpdate.DueDate.AddDays(shiftDays);
                        taskToUpdate.UpdatedAt = DateTime.UtcNow;
                        cascadeUpdatedCount++;
                    }
                }
            }

            await _context.SaveChangesAsync();
            await transaction.CommitAsync();

            return new DelayDetectionResultDto
            {
                DetectedTasks = detectedTasksCount,
                CascadeUpdatedTasks = cascadeUpdatedCount
            };
        }
        catch (Exception)
        {
            await transaction.RollbackAsync();
            throw;
        }
    }
}
