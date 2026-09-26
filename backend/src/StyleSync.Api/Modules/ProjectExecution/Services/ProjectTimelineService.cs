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

public class ProjectTimelineService : IProjectTimelineService
{
    private readonly AppDbContext _context;

    public ProjectTimelineService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<ProjectTimelineEventDto>> GetProjectTimelineAsync(Guid projectId, string? eventType = null, DateTime? from = null, DateTime? to = null)
    {
        var timeline = new List<ProjectTimelineEventDto>();

        // 1. Photos
        var photos = await _context.ProgressPhotos
            .Where(p => p.ProjectId == projectId)
            .ToListAsync();
            
        timeline.AddRange(photos.Select(p => new ProjectTimelineEventDto
        {
            EventId = $"photo-{p.ProgressPhotoId}",
            ProjectId = p.ProjectId,
            EventType = "ProgressPhotoUploaded",
            Title = "Progress photo uploaded",
            Description = p.Description,
            EntityType = "ProgressPhoto",
            EntityId = p.ProgressPhotoId.ToString(),
            Timestamp = p.UploadedAt,
            CreatedBy = p.UploadedBy
        }));

        // 2. Materials (Delivered)
        var materialsDelivered = await _context.ProjectMaterials
            .Where(m => m.ProjectId == projectId && m.Status == MaterialStatus.Delivered && m.DeliveredDate != null)
            .ToListAsync();

        timeline.AddRange(materialsDelivered.Select(m => new ProjectTimelineEventDto
        {
            EventId = $"material-delivered-{m.MaterialId}",
            ProjectId = m.ProjectId,
            EventType = "MaterialDelivered",
            Title = $"{m.Name} delivered",
            Description = m.Description,
            EntityType = "ProjectMaterial",
            EntityId = m.MaterialId.ToString(),
            Timestamp = m.DeliveredDate!.Value,
            CreatedBy = null
        }));
        
        // 3. Materials (Ordered)
        var materialsOrdered = await _context.ProjectMaterials
            .Where(m => m.ProjectId == projectId && (m.Status == MaterialStatus.Ordered || m.Status == MaterialStatus.Delivered) && m.OrderedDate != null)
            .ToListAsync();

        timeline.AddRange(materialsOrdered.Select(m => new ProjectTimelineEventDto
        {
            EventId = $"material-ordered-{m.MaterialId}",
            ProjectId = m.ProjectId,
            EventType = "MaterialOrdered",
            Title = $"{m.Name} ordered",
            Description = m.Description,
            EntityType = "ProjectMaterial",
            EntityId = m.MaterialId.ToString(),
            Timestamp = m.OrderedDate!.Value,
            CreatedBy = null
        }));

        // 4. Milestones (Created)
        var milestones = await _context.ProjectMilestones
            .Where(m => m.ProjectId == projectId)
            .ToListAsync();
            
        timeline.AddRange(milestones.Select(m => new ProjectTimelineEventDto
        {
            EventId = $"milestone-created-{m.MilestoneId}",
            ProjectId = m.ProjectId,
            EventType = "MilestoneCreated",
            Title = $"Milestone \"{m.Name}\" created",
            Description = null,
            EntityType = "ProjectMilestone",
            EntityId = m.MilestoneId.ToString(),
            Timestamp = m.CreatedAt,
            CreatedBy = null
        }));
        
        // Milestones (Completed - estimating by UpdatedAt if Status is Completed, ideally we'd add CompletedAt)
        // Since prompt says "prefer deriving from existing data" and "keep schema change minimal", we'll use UpdatedAt if status is completed, but this can be slightly inaccurate.
        timeline.AddRange(milestones.Where(m => m.Status == MilestoneStatus.Completed).Select(m => new ProjectTimelineEventDto
        {
            EventId = $"milestone-completed-{m.MilestoneId}",
            ProjectId = m.ProjectId,
            EventType = "MilestoneCompleted",
            Title = $"Milestone \"{m.Name}\" completed",
            Description = null,
            EntityType = "ProjectMilestone",
            EntityId = m.MilestoneId.ToString(),
            Timestamp = m.UpdatedAt ?? m.CreatedAt,
            CreatedBy = null
        }));

        // 5. Tasks
        var tasks = await _context.ProjectTasks
            .Include(t => t.Milestone)
            .Where(t => t.Milestone!.ProjectId == projectId)
            .ToListAsync();
            
        timeline.AddRange(tasks.Select(t => new ProjectTimelineEventDto
        {
            EventId = $"task-created-{t.TaskId}",
            ProjectId = t.Milestone!.ProjectId,
            EventType = "TaskCreated",
            Title = $"Task \"{t.Name}\" created",
            Description = null,
            EntityType = "ProjectTask",
            EntityId = t.TaskId.ToString(),
            Timestamp = t.CreatedAt,
            CreatedBy = null
        }));

        timeline.AddRange(tasks.Where(t => t.Status == Models.TaskStatus.Completed).Select(t => new ProjectTimelineEventDto
        {
            EventId = $"task-completed-{t.TaskId}",
            ProjectId = t.Milestone!.ProjectId,
            EventType = "TaskCompleted",
            Title = $"Task \"{t.Name}\" completed",
            Description = null,
            EntityType = "ProjectTask",
            EntityId = t.TaskId.ToString(),
            Timestamp = t.UpdatedAt ?? t.CreatedAt,
            CreatedBy = null
        }));

        // Apply filters
        var filteredTimeline = timeline.AsEnumerable();

        if (!string.IsNullOrEmpty(eventType))
        {
            filteredTimeline = filteredTimeline.Where(t => t.EventType.Equals(eventType, StringComparison.OrdinalIgnoreCase));
        }

        if (from.HasValue)
        {
            filteredTimeline = filteredTimeline.Where(t => t.Timestamp >= from.Value);
        }

        if (to.HasValue)
        {
            filteredTimeline = filteredTimeline.Where(t => t.Timestamp <= to.Value);
        }

        // Sort chronologically (descending by default)
        return filteredTimeline.OrderByDescending(t => t.Timestamp);
    }
}
