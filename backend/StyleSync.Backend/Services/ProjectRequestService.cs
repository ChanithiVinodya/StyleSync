using Microsoft.EntityFrameworkCore;
using StyleSync.Backend.Data;
using StyleSync.Backend.Domain.Entities;
using StyleSync.Backend.Domain.Enums;
using StyleSync.Backend.DTOs;

namespace StyleSync.Backend.Services;

public interface IProjectRequestService
{
    Task<ProjectRequestResponseDto> CreateRequestAsync(CreateProjectRequestDto dto, string clientId);
    Task<ProjectRequestResponseDto?> GetRequestByIdAsync(Guid id);
    Task<List<ProjectRequestResponseDto>> GetAllRequestsAsync(string? status = null, string? roomType = null, string? clientId = null);
    Task<ProjectRequestResponseDto?> UpdateRequestAsync(Guid id, UpdateProjectRequestDto dto, string clientId);
    Task<bool> DeleteRequestAsync(Guid id, string clientId);
    Task<ProjectRequestResponseDto?> UploadPhotoAsync(Guid id, IFormFile file);
    Task<ProjectRequestResponseDto?> SubmitRequestForAIAnalysisAsync(Guid id);
}

public class ProjectRequestService : IProjectRequestService
{
    private readonly StyleSyncDbContext _db;
    private readonly IPhotoStorageService _photoStorage;
    private readonly IAIServiceClient _aiClient;
    private readonly ILogger<ProjectRequestService> _logger;

    public ProjectRequestService(
        StyleSyncDbContext db,
        IPhotoStorageService photoStorage,
        IAIServiceClient aiClient,
        ILogger<ProjectRequestService> logger)
    {
        _db = db;
        _photoStorage = photoStorage;
        _aiClient = aiClient;
        _logger = logger;
    }

    public async Task<ProjectRequestResponseDto> CreateRequestAsync(CreateProjectRequestDto dto, string clientId)
    {
        var request = new ProjectRequest
        {
            ClientId = string.IsNullOrWhiteSpace(clientId) ? "client-default" : clientId,
            RoomType = dto.RoomType,
            LengthFeet = dto.LengthFeet,
            WidthFeet = dto.WidthFeet,
            HeightFeet = dto.HeightFeet,
            BudgetLkr = dto.BudgetLkr,
            PreferredStyles = dto.PreferredStyles ?? new List<string>(),
            Description = dto.Description,
            Status = dto.SubmitImmediately ? ProjectRequestStatus.Submitted : ProjectRequestStatus.Draft,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        if (dto.PhotoUrls != null && dto.PhotoUrls.Any())
        {
            foreach (var url in dto.PhotoUrls)
            {
                if (!string.IsNullOrWhiteSpace(url))
                {
                    request.Photos.Add(new ProjectRequestPhoto
                    {
                        ProjectRequestId = request.Id,
                        PhotoUrl = url,
                        StorageKey = $"uploaded/{Guid.NewGuid():N}.jpg",
                        UploadedAt = DateTime.UtcNow
                    });
                }
            }
        }

        _db.ProjectRequests.Add(request);
        await _db.SaveChangesAsync();

        if (dto.SubmitImmediately)
        {
            await ProcessAIStyleAnalysis(request);
        }

        return MapToDto(request);
    }

    public async Task<ProjectRequestResponseDto?> GetRequestByIdAsync(Guid id)
    {
        var request = await _db.ProjectRequests
            .Include(r => r.Photos)
            .Include(r => r.StyleAnalysis)
            .FirstOrDefaultAsync(r => r.Id == id);

        return request == null ? null : MapToDto(request);
    }

    public async Task<List<ProjectRequestResponseDto>> GetAllRequestsAsync(string? status = null, string? roomType = null, string? clientId = null)
    {
        var query = _db.ProjectRequests
            .Include(r => r.Photos)
            .Include(r => r.StyleAnalysis)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(status) && Enum.TryParse<ProjectRequestStatus>(status, true, out var parsedStatus))
        {
            query = query.Where(r => r.Status == parsedStatus);
        }

        if (!string.IsNullOrWhiteSpace(roomType))
        {
            query = query.Where(r => r.RoomType.ToLower().Contains(roomType.ToLower()));
        }

        if (!string.IsNullOrWhiteSpace(clientId))
        {
            query = query.Where(r => r.ClientId == clientId);
        }

        var list = await query.OrderByDescending(r => r.CreatedAt).ToListAsync();
        return list.Select(MapToDto).ToList();
    }

    public async Task<ProjectRequestResponseDto?> UpdateRequestAsync(Guid id, UpdateProjectRequestDto dto, string clientId)
    {
        var request = await _db.ProjectRequests
            .Include(r => r.Photos)
            .Include(r => r.StyleAnalysis)
            .FirstOrDefaultAsync(r => r.Id == id);

        if (request == null) return null;

        // Rule: Only Draft requests can be updated by client
        if (request.Status != ProjectRequestStatus.Draft)
        {
            throw new InvalidOperationException($"Cannot edit request {id} because its status is {request.Status}. Only Draft requests can be modified.");
        }

        request.RoomType = dto.RoomType;
        request.LengthFeet = dto.LengthFeet;
        request.WidthFeet = dto.WidthFeet;
        request.HeightFeet = dto.HeightFeet;
        request.BudgetLkr = dto.BudgetLkr;
        request.PreferredStyles = dto.PreferredStyles ?? new List<string>();
        request.Description = dto.Description;
        request.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        return MapToDto(request);
    }

    public async Task<bool> DeleteRequestAsync(Guid id, string clientId)
    {
        var request = await _db.ProjectRequests.FirstOrDefaultAsync(r => r.Id == id);
        if (request == null) return false;

        // Rule: Only Draft requests can be deleted
        if (request.Status != ProjectRequestStatus.Draft)
        {
            throw new InvalidOperationException($"Cannot delete request {id} because its status is {request.Status}. Only Draft requests can be deleted.");
        }

        request.IsDeleted = true;
        request.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<ProjectRequestResponseDto?> UploadPhotoAsync(Guid id, IFormFile file)
    {
        var request = await _db.ProjectRequests
            .Include(r => r.Photos)
            .Include(r => r.StyleAnalysis)
            .FirstOrDefaultAsync(r => r.Id == id);

        if (request == null) return null;

        var (photoUrl, storageKey) = await _photoStorage.UploadPhotoAsync(file, id);

        var photo = new ProjectRequestPhoto
        {
            ProjectRequestId = id,
            PhotoUrl = photoUrl,
            StorageKey = storageKey,
            UploadedAt = DateTime.UtcNow
        };

        request.Photos.Add(photo);
        request.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        return MapToDto(request);
    }

    public async Task<ProjectRequestResponseDto?> SubmitRequestForAIAnalysisAsync(Guid id)
    {
        var request = await _db.ProjectRequests
            .Include(r => r.Photos)
            .Include(r => r.StyleAnalysis)
            .FirstOrDefaultAsync(r => r.Id == id);

        if (request == null) return null;

        request.Status = ProjectRequestStatus.Submitted;
        request.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        await ProcessAIStyleAnalysis(request);

        return MapToDto(request);
    }

    private async Task ProcessAIStyleAnalysis(ProjectRequest request)
    {
        request.Status = ProjectRequestStatus.AIAnalysis;
        await _db.SaveChangesAsync();

        var aiRequest = new AIStyleAnalysisRequestDto(
            ProjectRequestId: request.Id,
            RoomType: request.RoomType,
            PreferredStyles: request.PreferredStyles,
            Description: request.Description,
            PhotoUrls: request.Photos.Select(p => p.PhotoUrl).ToList()
        );

        var aiResponse = await _aiClient.AnalyzeStyleAsync(aiRequest);

        var styleResult = await _db.StyleAnalysisResults.FirstOrDefaultAsync(s => s.ProjectRequestId == request.Id);
        if (styleResult == null)
        {
            styleResult = new StyleAnalysisResult
            {
                ProjectRequestId = request.Id
            };
            _db.StyleAnalysisResults.Add(styleResult);
        }

        styleResult.PrimaryStyle = aiResponse.PrimaryStyle;
        styleResult.SecondaryStyle = aiResponse.SecondaryStyle;
        styleResult.ConfidenceScore = aiResponse.ConfidenceScore;
        styleResult.RecommendedColors = aiResponse.RecommendedColors;
        styleResult.DetectedFeatures = aiResponse.DetectedFeatures;
        styleResult.AnalysisSummary = aiResponse.AnalysisSummary;
        styleResult.ConceptRenderUrl = string.IsNullOrWhiteSpace(aiResponse.ConceptRenderUrl)
            ? "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=1000&auto=format&fit=crop"
            : aiResponse.ConceptRenderUrl;
        styleResult.AnalyzedAt = DateTime.UtcNow;

        request.Status = ProjectRequestStatus.ProposalReady;
        request.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
    }

    private static ProjectRequestResponseDto MapToDto(ProjectRequest r)
    {
        return new ProjectRequestResponseDto(
            Id: r.Id,
            ClientId: r.ClientId,
            RoomType: r.RoomType,
            LengthFeet: r.LengthFeet,
            WidthFeet: r.WidthFeet,
            HeightFeet: r.HeightFeet,
            BudgetLkr: r.BudgetLkr,
            PreferredStyles: r.PreferredStyles ?? new List<string>(),
            Description: r.Description,
            Status: r.Status.ToString(),
            CreatedAt: r.CreatedAt,
            UpdatedAt: r.UpdatedAt,
            Photos: r.Photos.Select(p => new ProjectRequestPhotoDto(p.Id, p.PhotoUrl, p.StorageKey, p.UploadedAt)).ToList(),
            StyleAnalysis: r.StyleAnalysis == null ? null : new StyleAnalysisResultDto(
                Id: r.StyleAnalysis.Id,
                PrimaryStyle: r.StyleAnalysis.PrimaryStyle,
                SecondaryStyle: r.StyleAnalysis.SecondaryStyle,
                ConfidenceScore: r.StyleAnalysis.ConfidenceScore,
                RecommendedColors: r.StyleAnalysis.RecommendedColors,
                DetectedFeatures: r.StyleAnalysis.DetectedFeatures,
                AnalysisSummary: r.StyleAnalysis.AnalysisSummary,
                ConceptRenderUrl: r.StyleAnalysis.ConceptRenderUrl,
                AnalyzedAt: r.StyleAnalysis.AnalyzedAt
            )
        );
    }
}
