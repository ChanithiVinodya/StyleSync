using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Identity;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Common.Storage;
using StyleSync.Api.Modules.ProjectRequests.Models.Entities;
using StyleSync.Api.Modules.ProjectRequests.Models.Enums;
using StyleSync.Api.Modules.ProjectRequests.DTOs;

namespace StyleSync.Api.Modules.ProjectRequests.Controllers;


[ApiController]
[Route("requests/{id:guid}/images")]
[Route("api/requests/{id:guid}/images")]
[Authorize]
public class ProjectRequestImagesController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IFileStorage _fileStorage;
    private readonly ICurrentUser _currentUser;
    public ProjectRequestImagesController(
        AppDbContext context, 
        IFileStorage fileStorage, 
        ICurrentUser currentUser)
    {
        _context = context;
        _fileStorage = fileStorage;
        _currentUser = currentUser;
    }

    /// <summary>
    /// Uploads room or moodboard images for a draft request.
    /// </summary>
    /// <response code="200">Returns the updated image URLs.</response>
    /// <response code="400">If validation fails.</response>
    /// <response code="404">If the request is not found.</response>
    /// <response code="409">If the request is not a Draft.</response>
    [HttpPost]
    [ProducesResponseType(200)]
    [ProducesResponseType(typeof(ProblemDetails), 400)]
    [Authorize(Roles = "Client")]
    public async Task<IActionResult> UploadImages(Guid id, [FromForm] string type, [FromForm] List<IFormFile> files)
    {
        if (type != "room" && type != "moodboard")
            return BadRequest(new { message = "Invalid type. Must be 'room' or 'moodboard'." });

        if (files == null || files.Count == 0 || files.Count > 10)
            return BadRequest(new { message = "Must provide between 1 and 10 files." });

        if (type == "room" && files.Count > 1)
            return BadRequest(new { message = "Only 1 room photo can be uploaded at a time." });

        var request = await _context.ProjectRequests
            .Include(r => r.MoodboardImages)
            .FirstOrDefaultAsync(r => r.Id == id);

        if (request == null || request.ClientId != _currentUser.Id)
            return NotFound(new { message = "Request not found." });

        if (request.Status != RequestStatus.Draft)
            return Conflict(new { message = "Images can only be uploaded while the request is a Draft." });

        if (type == "moodboard" && request.MoodboardImages.Count + files.Count > 10)
            return BadRequest(new { message = "Maximum of 10 moodboard images allowed." });

        var errors = new List<object>();
        var streams = new Dictionary<IFormFile, System.IO.MemoryStream>();

        foreach (var file in files)
        {
            if (!FileValidator.IsValidSize(file.Length))
            {
                errors.Add(new { file = file.FileName, error = "File exceeds 10MB limit." });
                continue;
            }
            if (!FileValidator.IsValidExtensionAndMime(file.FileName, file.ContentType))
            {
                errors.Add(new { file = file.FileName, error = "Invalid file type. Only JPEG, PNG, WEBP are allowed." });
                continue;
            }
            var ms = new System.IO.MemoryStream();
            await file.CopyToAsync(ms);
            if (!FileValidator.IsValidSignature(ms))
            {
                ms.Dispose();
                errors.Add(new { file = file.FileName, error = "Invalid file signature (magic bytes mismatch)." });
                continue;
            }
            ms.Position = 0;
            streams[file] = ms;
        }

        if (errors.Any())
        {
            foreach (var s in streams.Values) s.Dispose();
            return BadRequest(new { errors });
        }

        var uploadedKeys = new List<string>();

        try
        {
            if (type == "room")
            {
                var file = files.First();
                var stream = streams[file];
                var result = await _fileStorage.UploadAsync(stream, file.FileName, file.ContentType, $"requests/{id}/room");
                uploadedKeys.Add(result.StorageKey);
                
                var oldKey = request.RoomPhotoStorageKey;
                
                request.RoomPhotoUrl = result.Url;
                request.RoomPhotoStorageKey = result.StorageKey;
                request.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                if (!string.IsNullOrEmpty(oldKey))
                {
                    await _fileStorage.DeleteAsync(oldKey);
                }
            }
            else
            {
                int sortOrder = request.MoodboardImages.Any() ? request.MoodboardImages.Max(m => m.SortOrder) + 1 : 1;
                foreach (var file in files)
                {
                    var stream = streams[file];
                    var result = await _fileStorage.UploadAsync(stream, file.FileName, file.ContentType, $"requests/{id}/moodboards");
                    uploadedKeys.Add(result.StorageKey);

                    var moodboardImage = new MoodboardImage
                    {
                        Id = Guid.NewGuid(),
                        ProjectRequestId = id,
                        Url = result.Url,
                        StorageKey = result.StorageKey,
                        SortOrder = sortOrder++,
                        UploadedAt = DateTime.UtcNow
                    };
                    _context.MoodboardImages.Add(moodboardImage);
                }

                request.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();
            }
        }
        catch (Exception)
        {
            foreach (var key in uploadedKeys)
            {
                try { await _fileStorage.DeleteAsync(key); } catch { }
            }
            throw;
        }
        finally
        {
            foreach (var s in streams.Values) s.Dispose();
        }

        return Ok(new
        {
            RoomPhotoUrl = request.RoomPhotoUrl,
            Moodboards = request.MoodboardImages.OrderBy(m => m.SortOrder)
                .Select(m => new MoodboardImageDto(m.Id, m.Url, m.SortOrder)).ToList()
        });
    }

    /// <summary>
    /// Deletes a specific image from a draft request.
    /// </summary>
    /// <response code="204">If deletion is successful.</response>
    /// <response code="404">If the request or image is not found.</response>
    /// <response code="409">If the request is not a Draft.</response>
    [HttpDelete("{imageId}")]
    [ProducesResponseType(204)]
    [ProducesResponseType(typeof(ProblemDetails), 400)]
    [Authorize(Roles = "Client")]
    public async Task<IActionResult> DeleteImage(Guid id, string imageId)
    {
        var request = await _context.ProjectRequests
            .Include(r => r.MoodboardImages)
            .Include(r => r.SuggestedPalettes)
            .FirstOrDefaultAsync(r => r.Id == id);

        if (request == null || request.ClientId != _currentUser.Id)
            return NotFound(new { message = "Request not found." });

        if (request.Status != RequestStatus.Draft)
            return Conflict(new { message = "Images can only be deleted while the request is a Draft." });

        if (imageId.ToLower() == "room")
        {
            if (string.IsNullOrEmpty(request.RoomPhotoStorageKey))
                return NotFound(new { message = "No room photo to delete." });

            var key = request.RoomPhotoStorageKey;
            request.RoomPhotoUrl = null;
            request.RoomPhotoStorageKey = null;
            
            _context.SuggestedPalettes.RemoveRange(request.SuggestedPalettes);

            await _context.SaveChangesAsync();
            await _fileStorage.DeleteAsync(key);
        }
        else if (Guid.TryParse(imageId, out var mbId))
        {
            var mb = request.MoodboardImages.FirstOrDefault(m => m.Id == mbId);
            if (mb == null)
                return NotFound(new { message = "Moodboard image not found." });

            var key = mb.StorageKey;
            _context.MoodboardImages.Remove(mb);
            request.UpdatedAt = DateTime.UtcNow;
            
            await _context.SaveChangesAsync();
            await _fileStorage.DeleteAsync(key);
        }
        else
        {
            return BadRequest(new { message = "Invalid imageId format." });
        }

        return NoContent();
    }
}
