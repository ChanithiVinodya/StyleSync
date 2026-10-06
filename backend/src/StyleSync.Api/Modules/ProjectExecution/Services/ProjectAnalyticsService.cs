using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.ProjectExecution.DTOs;
using StyleSync.Api.Modules.ProjectExecution.Interfaces;
using StyleSync.Api.Modules.ProjectExecution.Models;

namespace StyleSync.Api.Modules.ProjectExecution.Services;

public class ProjectAnalyticsService : IProjectAnalyticsService
{
    private readonly AppDbContext _context;

    public ProjectAnalyticsService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<ProjectAnalyticsDto> GetProjectAnalyticsAsync(Guid projectId, DateTime? from = null, DateTime? to = null)
    {
        var dto = new ProjectAnalyticsDto
        {
            ProjectId = projectId,
            ProjectName = "Project" // Ideally we'd get this from a Projects table, but it's not defined in our module
        };

        // 1. Task Analytics
        var tasksQuery = _context.ProjectTasks
            .Include(t => t.Milestone)
            .Where(t => t.Milestone!.ProjectId == projectId);
            
        var allTasks = await tasksQuery.ToListAsync();

        dto.Tasks.Total = allTasks.Count;
        dto.Tasks.Completed = allTasks.Count(t => t.Status == Models.TaskStatus.Completed);
        dto.Tasks.InProgress = allTasks.Count(t => t.Status == Models.TaskStatus.InProgress);
        dto.Tasks.NotStarted = allTasks.Count(t => t.Status == Models.TaskStatus.NotStarted);
        dto.Tasks.Delayed = allTasks.Count(t => t.Status == Models.TaskStatus.Delayed);
        
        dto.Tasks.CompletionPercentage = dto.Tasks.Total > 0 
            ? Math.Round((double)dto.Tasks.Completed / dto.Tasks.Total * 100, 2) 
            : 0.0;

        dto.OverallProgress = dto.Tasks.CompletionPercentage;

        // 2. Milestone Analytics
        var milestonesQuery = _context.ProjectMilestones
            .Where(m => m.ProjectId == projectId);
            
        var allMilestones = await milestonesQuery.ToListAsync();

        dto.Milestones.Total = allMilestones.Count;
        dto.Milestones.Completed = allMilestones.Count(m => m.Status == MilestoneStatus.Completed);
        dto.Milestones.InProgress = allMilestones.Count(m => m.Status == MilestoneStatus.InProgress);
        dto.Milestones.NotStarted = allMilestones.Count(m => m.Status == MilestoneStatus.NotStarted);
        dto.Milestones.Delayed = allMilestones.Count(m => m.Status == MilestoneStatus.Delayed);

        dto.Milestones.CompletionPercentage = dto.Milestones.Total > 0
            ? Math.Round((double)dto.Milestones.Completed / dto.Milestones.Total * 100, 2)
            : 0.0;

        // 3. Material Analytics
        var materialsQuery = _context.ProjectMaterials
            .Where(m => m.ProjectId == projectId);
            
        var allMaterials = await materialsQuery.ToListAsync();

        dto.Materials.Total = allMaterials.Count;
        dto.Materials.Required = allMaterials.Count(m => m.Status == MaterialStatus.Required);
        dto.Materials.Ordered = allMaterials.Count(m => m.Status == MaterialStatus.Ordered);
        dto.Materials.Delivered = allMaterials.Count(m => m.Status == MaterialStatus.Delivered);

        dto.Materials.CompletionPercentage = dto.Materials.Total > 0
            ? Math.Round((double)dto.Materials.Delivered / dto.Materials.Total * 100, 2)
            : 0.0;

        // 4. Material-Gated Analytics
        // Milestones blocked by incomplete materials
        dto.MaterialGated.BlockedMilestones = allMilestones.Count(m => 
            m.Status != MilestoneStatus.Completed && 
            allMaterials.Any(mat => mat.MilestoneId == m.MilestoneId && mat.Status != MaterialStatus.Delivered));

        // 5. Delay Analytics
        var currentDate = DateTime.UtcNow.Date;
        
        var delayedTasks = allTasks.Where(t => t.Status != Models.TaskStatus.Completed && t.DueDate.Date < currentDate).ToList();
        
        dto.Delays.DelayedTasks = delayedTasks.Count;
        
        if (delayedTasks.Any())
        {
            var delayDaysList = delayedTasks.Select(t => (currentDate - t.DueDate.Date).Days).ToList();
            dto.Delays.TotalDelayDays = delayDaysList.Sum();
            dto.Delays.AverageDelayDays = Math.Round(delayDaysList.Average(), 2);
            dto.Delays.MaximumDelayDays = delayDaysList.Max();
        }

        // 6. Progress Photo Analytics
        var photosQuery = _context.ProgressPhotos
            .Where(p => p.ProjectId == projectId);
            
        if (from.HasValue) photosQuery = photosQuery.Where(p => p.UploadedAt >= from.Value);
        if (to.HasValue) photosQuery = photosQuery.Where(p => p.UploadedAt <= to.Value);
            
        var photos = await photosQuery.ToListAsync();
        dto.ProgressPhotos.Total = photos.Count;

        // 7. Timeline Activity Analytics
        // Time filter applies to events based on their completion/delivery date
        var taskEvents = allTasks.Where(t => t.Status == Models.TaskStatus.Completed);
        if (from.HasValue) taskEvents = taskEvents.Where(t => (t.UpdatedAt ?? t.CreatedAt) >= from.Value);
        if (to.HasValue) taskEvents = taskEvents.Where(t => (t.UpdatedAt ?? t.CreatedAt) <= to.Value);
        dto.Activity.TasksCompleted = taskEvents.Count();

        var milestoneEvents = allMilestones.Where(m => m.Status == MilestoneStatus.Completed);
        if (from.HasValue) milestoneEvents = milestoneEvents.Where(m => (m.UpdatedAt ?? m.CreatedAt) >= from.Value);
        if (to.HasValue) milestoneEvents = milestoneEvents.Where(m => (m.UpdatedAt ?? m.CreatedAt) <= to.Value);
        dto.Activity.MilestonesCompleted = milestoneEvents.Count();

        var materialEvents = allMaterials.Where(m => m.Status == MaterialStatus.Delivered && m.DeliveredDate != null);
        if (from.HasValue) materialEvents = materialEvents.Where(m => m.DeliveredDate >= from.Value);
        if (to.HasValue) materialEvents = materialEvents.Where(m => m.DeliveredDate <= to.Value);
        dto.Activity.MaterialsDelivered = materialEvents.Count();

        dto.Activity.PhotosUploaded = dto.ProgressPhotos.Total;

        dto.Activity.TotalEvents = dto.Activity.PhotosUploaded + dto.Activity.MaterialsDelivered + dto.Activity.TasksCompleted + dto.Activity.MilestonesCompleted;

        return dto;
    }
}
