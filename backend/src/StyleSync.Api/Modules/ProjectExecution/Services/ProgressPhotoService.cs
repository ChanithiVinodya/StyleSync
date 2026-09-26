using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.ProjectExecution.DTOs;
using StyleSync.Api.Modules.ProjectExecution.Interfaces;
using StyleSync.Api.Modules.ProjectExecution.Models;

namespace StyleSync.Api.Modules.ProjectExecution.Services;

public class ProgressPhotoService : IProgressPhotoService
{
    private readonly AppDbContext _context;
    private readonly IFileStorageService _fileStorageService;
    private readonly long _maxFileSize = 10 * 1024 * 1024; // 10MB
    private readonly string[] _allowedContentTypes = { "image/jpeg", "image/png", "image/webp" };
    private readonly string[] _allowedExtensions = { ".jpg", ".jpeg", ".png", ".webp" };

    public ProgressPhotoService(AppDbContext context, IFileStorageService fileStorageService)
    {
        _context = context;
        _fileStorageService = fileStorageService;
    }

    public async Task<ProgressPhotoDto> CreateAsync(CreateProgressPhotoDto request, Guid userId)
    {
        if (request.File == null || request.File.Length == 0)
            throw new ArgumentException("File is required and cannot be empty.");

        if (request.File.Length > _maxFileSize)
            throw new ArgumentException("File exceeds the maximum allowed size of 10MB.");

        if (!_allowedContentTypes.Contains(request.File.ContentType.ToLowerInvariant()))
            throw new ArgumentException("Unsupported file type.");

        var ext = Path.GetExtension(request.File.FileName).ToLowerInvariant();
        if (!_allowedExtensions.Contains(ext))
            throw new ArgumentException("Unsupported file extension.");

        await ValidateRelationshipsAsync(request.ProjectId, request.MilestoneId, request.TaskId);

        var fileUrl = await _fileStorageService.SaveFileAsync(request.File, "progress-photos");

        var photo = new ProgressPhoto
        {
            ProgressPhotoId = Guid.NewGuid(),
            ProjectId = request.ProjectId,
            MilestoneId = request.MilestoneId,
            TaskId = request.TaskId,
            UploadedBy = userId,
            FileName = request.File.FileName, // Or generate a secure one, but we generated a secure physical name in FileStorageService
            ImageUrl = fileUrl,
            ContentType = request.File.ContentType,
            FileSize = request.File.Length,
            Description = request.Caption,
            UploadedAt = DateTime.UtcNow
        };

        _context.ProgressPhotos.Add(photo);
        await _context.SaveChangesAsync();

        return MapToDto(photo);
    }

    public async Task<ProgressPhotoDto?> GetByIdAsync(Guid photoId)
    {
        var photo = await _context.ProgressPhotos.FindAsync(photoId);
        if (photo == null) return null;
        return MapToDto(photo);
    }

    public async Task<IEnumerable<ProgressPhotoDto>> GetProjectPhotosAsync(Guid projectId, Guid? milestoneId = null, Guid? taskId = null, DateTime? from = null, DateTime? to = null, string sort = "desc")
    {
        var query = _context.ProgressPhotos.Where(p => p.ProjectId == projectId);

        if (milestoneId.HasValue)
            query = query.Where(p => p.MilestoneId == milestoneId.Value);

        if (taskId.HasValue)
            query = query.Where(p => p.TaskId == taskId.Value);

        if (from.HasValue)
            query = query.Where(p => p.UploadedAt >= from.Value);

        if (to.HasValue)
            query = query.Where(p => p.UploadedAt <= to.Value);

        if (sort.ToLower() == "asc")
            query = query.OrderBy(p => p.UploadedAt);
        else
            query = query.OrderByDescending(p => p.UploadedAt);

        var photos = await query.ToListAsync();
        return photos.Select(MapToDto);
    }

    public async Task<ProgressPhotoDto?> UpdateAsync(Guid photoId, UpdateProgressPhotoDto request)
    {
        var photo = await _context.ProgressPhotos.FindAsync(photoId);
        if (photo == null) return null;

        await ValidateRelationshipsAsync(photo.ProjectId, request.MilestoneId, request.TaskId);

        photo.Description = request.Caption;
        photo.MilestoneId = request.MilestoneId;
        photo.TaskId = request.TaskId;

        await _context.SaveChangesAsync();
        return MapToDto(photo);
    }

    public async Task<bool> DeleteAsync(Guid photoId)
    {
        var photo = await _context.ProgressPhotos.FindAsync(photoId);
        if (photo == null) return false;

        await _fileStorageService.DeleteFileAsync(photo.ImageUrl);

        _context.ProgressPhotos.Remove(photo);
        await _context.SaveChangesAsync();
        return true;
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

            if (milestoneId.HasValue && task.MilestoneId != milestoneId.Value)
            {
                throw new ArgumentException("Task does not belong to the specified Milestone.");
            }
        }
    }

    private static ProgressPhotoDto MapToDto(ProgressPhoto photo)
    {
        return new ProgressPhotoDto
        {
            PhotoId = photo.ProgressPhotoId,
            ProjectId = photo.ProjectId,
            MilestoneId = photo.MilestoneId,
            TaskId = photo.TaskId,
            FileName = photo.FileName,
            FileUrl = photo.ImageUrl,
            ContentType = photo.ContentType,
            FileSize = photo.FileSize,
            Caption = photo.Description,
            UploadedBy = photo.UploadedBy,
            UploadedAt = photo.UploadedAt
        };
    }
}
