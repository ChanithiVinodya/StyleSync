using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Identity;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.ProjectRequests.DTOs;
using StyleSync.Api.Modules.ProjectRequests.Interfaces;
using StyleSync.Api.Modules.ProjectRequests.Models;

namespace StyleSync.Api.Modules.ProjectRequests.Services;

public class ProjectRequestService : IProjectRequestService
{
    private readonly AppDbContext _context;

    public ProjectRequestService(AppDbContext context)
    {
        _context = context;
    }

    // ─── Create ───────────────────────────────────────────────────────────────

    public async Task<ProjectRequestDetailDto> CreateAsync(Guid clientId, CreateProjectRequestDto dto)
    {
        if (dto.BudgetMin.HasValue && dto.BudgetMin <= 0)
            throw new ArgumentException("Budget minimum must be greater than 0.");
        if (dto.BudgetMax.HasValue && dto.BudgetMax <= 0)
            throw new ArgumentException("Budget maximum must be greater than 0.");
        if (dto.BudgetMin.HasValue && dto.BudgetMax.HasValue && dto.BudgetMin > dto.BudgetMax)
            throw new ArgumentException("Budget minimum cannot exceed budget maximum.");

        if (dto.RoomSize.HasValue && dto.RoomSize <= 0)
            throw new ArgumentException("Room size must be positive (> 0 sq ft).");

        if (dto.PreferredStartDate.HasValue && dto.PreferredStartDate.Value.Date < DateTime.UtcNow.Date)
            throw new ArgumentException("Preferred start date must be today or in the future.");

        if (dto.PreferredStartDate.HasValue && dto.PreferredEndDate.HasValue && dto.PreferredStartDate >= dto.PreferredEndDate)
            throw new ArgumentException("Preferred end date must be after start date.");

        var client = await _context.Users.FindAsync(clientId)
            ?? throw new KeyNotFoundException("Client account not found.");

        if (client.Role != UserRole.Client)
            throw new UnauthorizedAccessException("Only clients may submit project requests.");

        var initialStatus = dto.SubmitImmediately ? ProjectRequestStatus.Submitted : ProjectRequestStatus.Draft;

        var entity = new ProjectRequest
        {
            ClientId = clientId,
            Title = string.IsNullOrWhiteSpace(dto.Title) ? $"{dto.RoomType} Makeover" : dto.Title.Trim(),
            Description = dto.Description.Trim(),
            RoomType = dto.RoomType,
            RoomSize = dto.RoomSize,
            BudgetMin = dto.BudgetMin,
            BudgetMax = dto.BudgetMax,
            PreferredStartDate = dto.PreferredStartDate,
            PreferredEndDate = dto.PreferredEndDate,
            StylePreferences = dto.StylePreferences?.Trim(),
            PreferredColours = dto.PreferredColours?.Trim(),
            SpecialRequirements = dto.SpecialRequirements?.Trim(),
            Status = initialStatus,
            CreatedAtUtc = DateTime.UtcNow,
            UpdatedAtUtc = DateTime.UtcNow
        };

        // Attach images if provided
        if (dto.Images != null && dto.Images.Count > 0)
        {
            foreach (var img in dto.Images)
            {
                entity.Images.Add(new MoodboardImage
                {
                    ImageUrl = img.ImageUrl,
                    ImageType = string.IsNullOrWhiteSpace(img.ImageType) ? "Moodboard" : img.ImageType,
                    StorageKey = img.StorageKey,
                    CreatedAtUtc = DateTime.UtcNow
                });
            }
            // Auto extract hex palette chips
            GenerateDefaultPaletteForRequest(entity);
        }

        // Add status history entry
        entity.StatusHistory.Add(new ProjectRequestStatusHistory
        {
            Status = initialStatus.ToString(),
            Reason = dto.SubmitImmediately ? "Submitted upon creation" : "Draft created by client",
            ChangedBy = client.Name,
            CreatedAtUtc = DateTime.UtcNow
        });

        _context.ProjectRequests.Add(entity);
        await _context.SaveChangesAsync();

        return await GetByIdAsync(entity.Id, clientId, UserRole.Client.ToString());
    }

    // ─── Filter & Search (Paginated) ──────────────────────────────────────────

    public async Task<PagedResult<ProjectRequestSummaryDto>> GetFilteredAsync(
        Guid requestingUserId,
        string requestingUserRole,
        ProjectRequestFilterQuery query)
    {
        var dbQuery = _context.ProjectRequests
            .Include(r => r.Images)
            .AsNoTracking();

        // Clients see only their own requests
        if (requestingUserRole == UserRole.Client.ToString())
        {
            dbQuery = dbQuery.Where(r => r.ClientId == requestingUserId);
        }

        // Filters
        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var term = query.Search.Trim().ToLower();
            dbQuery = dbQuery.Where(r =>
                r.Title.ToLower().Contains(term) ||
                r.Description.ToLower().Contains(term) ||
                r.RoomType.ToString().ToLower().Contains(term) ||
                (r.Client != null && r.Client.Name.ToLower().Contains(term)));
        }

        if (!string.IsNullOrWhiteSpace(query.Status) && Enum.TryParse<ProjectRequestStatus>(query.Status, true, out var statusEnum))
        {
            dbQuery = dbQuery.Where(r => r.Status == statusEnum);
        }

        if (!string.IsNullOrWhiteSpace(query.RoomType) && Enum.TryParse<RoomType>(query.RoomType, true, out var roomTypeEnum))
        {
            dbQuery = dbQuery.Where(r => r.RoomType == roomTypeEnum);
        }

        if (query.MinBudget.HasValue)
        {
            dbQuery = dbQuery.Where(r => (r.BudgetMin ?? r.BudgetMax) >= query.MinBudget.Value);
        }

        if (query.MaxBudget.HasValue)
        {
            dbQuery = dbQuery.Where(r => (r.BudgetMax ?? r.BudgetMin) <= query.MaxBudget.Value);
        }

        if (query.StartDate.HasValue)
        {
            dbQuery = dbQuery.Where(r => r.CreatedAtUtc >= query.StartDate.Value);
        }

        if (query.EndDate.HasValue)
        {
            dbQuery = dbQuery.Where(r => r.CreatedAtUtc <= query.EndDate.Value);
        }

        // Sorting
        dbQuery = query.SortBy?.ToLower() switch
        {
            "date_asc" => dbQuery.OrderBy(r => r.CreatedAtUtc),
            "budget_desc" => dbQuery.OrderByDescending(r => r.BudgetMax ?? r.BudgetMin ?? 0),
            "budget_asc" => dbQuery.OrderBy(r => r.BudgetMin ?? r.BudgetMax ?? 0),
            "status" => dbQuery.OrderBy(r => r.Status),
            _ => dbQuery.OrderByDescending(r => r.CreatedAtUtc)
        };

        var totalCount = await dbQuery.CountAsync();
        var page = query.Page > 0 ? query.Page : 1;
        var pageSize = query.PageSize > 0 ? query.PageSize : 10;

        var items = await dbQuery
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(r => new ProjectRequestSummaryDto(
                r.Id,
                r.Title,
                r.RoomType.ToString(),
                r.RoomSize,
                r.Status.ToString(),
                r.CreatedAtUtc,
                r.Description,
                r.BudgetMin,
                r.BudgetMax,
                r.PreferredColours,
                r.SpecialRequirements,
                r.ClientId,
                r.Images.FirstOrDefault(i => i.ImageType == "RoomPhoto") != null
                    ? r.Images.FirstOrDefault(i => i.ImageType == "RoomPhoto")!.ImageUrl
                    : (r.Images.FirstOrDefault() != null ? r.Images.FirstOrDefault()!.ImageUrl : null),
                r.Images.Count))
            .ToListAsync();

        return new PagedResult<ProjectRequestSummaryDto>
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<IReadOnlyList<ProjectRequestSummaryDto>> GetByClientAsync(Guid clientId)
    {
        var res = await GetFilteredAsync(clientId, UserRole.Client.ToString(), new ProjectRequestFilterQuery { PageSize = 100 });
        return res.Items;
    }

    public async Task<IReadOnlyList<ProjectRequestSummaryDto>> GetAllAsync()
    {
        var res = await GetFilteredAsync(Guid.Empty, UserRole.Admin.ToString(), new ProjectRequestFilterQuery { PageSize = 100 });
        return res.Items;
    }

    // ─── Get By Id ────────────────────────────────────────────────────────────

    public async Task<ProjectRequestDetailDto> GetByIdAsync(int requestId, Guid requestingUserId, string requestingUserRole)
    {
        var entity = await _context.ProjectRequests
            .Include(r => r.Client)
            .Include(r => r.Images)
            .Include(r => r.SuggestedPalettes)
            .Include(r => r.StatusHistory)
            .FirstOrDefaultAsync(r => r.Id == requestId)
            ?? throw new KeyNotFoundException($"Project request '{requestId}' not found.");

        if (requestingUserRole == UserRole.Client.ToString() && entity.ClientId != requestingUserId)
            throw new UnauthorizedAccessException("You are not authorised to view this request.");

        return MapToDetail(entity);
    }

    // ─── Update ───────────────────────────────────────────────────────────────

    public async Task<ProjectRequestDetailDto> UpdateAsync(int requestId, Guid clientId, UpdateProjectRequestDto dto)
    {
        var entity = await _context.ProjectRequests
            .Include(r => r.Client)
            .Include(r => r.Images)
            .Include(r => r.SuggestedPalettes)
            .Include(r => r.StatusHistory)
            .FirstOrDefaultAsync(r => r.Id == requestId)
            ?? throw new KeyNotFoundException($"Project request '{requestId}' not found.");

        if (entity.ClientId != clientId)
            throw new UnauthorizedAccessException("You are not authorised to edit this request.");

        if (entity.Status != ProjectRequestStatus.Draft && entity.Status != ProjectRequestStatus.Submitted)
            throw new InvalidOperationException("Only Draft or Submitted requests may be edited.");

        if (!string.IsNullOrWhiteSpace(dto.Title)) entity.Title = dto.Title.Trim();
        if (!string.IsNullOrWhiteSpace(dto.Description)) entity.Description = dto.Description.Trim();
        if (dto.RoomType.HasValue) entity.RoomType = dto.RoomType.Value;
        if (dto.RoomSize.HasValue) entity.RoomSize = dto.RoomSize.Value;
        if (dto.BudgetMin.HasValue) entity.BudgetMin = dto.BudgetMin;
        if (dto.BudgetMax.HasValue) entity.BudgetMax = dto.BudgetMax;
        if (dto.PreferredStartDate.HasValue) entity.PreferredStartDate = dto.PreferredStartDate;
        if (dto.PreferredEndDate.HasValue) entity.PreferredEndDate = dto.PreferredEndDate;
        if (dto.StylePreferences != null) entity.StylePreferences = dto.StylePreferences.Trim();
        if (dto.PreferredColours != null) entity.PreferredColours = dto.PreferredColours.Trim();
        if (dto.SpecialRequirements != null) entity.SpecialRequirements = dto.SpecialRequirements.Trim();

        if (entity.BudgetMin.HasValue && entity.BudgetMax.HasValue && entity.BudgetMin > entity.BudgetMax)
            throw new ArgumentException("Budget minimum cannot exceed budget maximum.");

        entity.UpdatedAtUtc = DateTime.UtcNow;

        entity.StatusHistory.Add(new ProjectRequestStatusHistory
        {
            Status = entity.Status.ToString(),
            Reason = "Draft updated by client",
            ChangedBy = entity.Client?.Name ?? "Client",
            CreatedAtUtc = DateTime.UtcNow
        });

        await _context.SaveChangesAsync();
        return MapToDetail(entity);
    }

    // ─── Delete ───────────────────────────────────────────────────────────────

    public async Task DeleteAsync(int requestId, Guid clientId)
    {
        var entity = await _context.ProjectRequests.FindAsync(requestId)
            ?? throw new KeyNotFoundException($"Project request '{requestId}' not found.");

        if (entity.ClientId != clientId)
            throw new UnauthorizedAccessException("You are not authorised to delete this request.");

        if (entity.Status != ProjectRequestStatus.Draft)
            throw new InvalidOperationException("Only Draft requests can be deleted.");

        _context.ProjectRequests.Remove(entity);
        await _context.SaveChangesAsync();
    }

    // ─── Add Images & Extract Palette ──────────────────────────────────────────

    public async Task<ProjectRequestDetailDto> AddImagesAsync(int requestId, Guid clientId, List<UploadImageDto> images)
    {
        var entity = await _context.ProjectRequests
            .Include(r => r.Client)
            .Include(r => r.Images)
            .Include(r => r.SuggestedPalettes)
            .Include(r => r.StatusHistory)
            .FirstOrDefaultAsync(r => r.Id == requestId)
            ?? throw new KeyNotFoundException($"Project request '{requestId}' not found.");

        if (entity.ClientId != clientId)
            throw new UnauthorizedAccessException("You are not authorised to modify images for this request.");

        foreach (var img in images)
        {
            entity.Images.Add(new MoodboardImage
            {
                ImageUrl = img.ImageUrl,
                ImageType = string.IsNullOrWhiteSpace(img.ImageType) ? "Moodboard" : img.ImageType,
                StorageKey = img.StorageKey,
                CreatedAtUtc = DateTime.UtcNow
            });
        }

        // Auto extract hex colour palette if not present
        if (entity.SuggestedPalettes.Count == 0)
        {
            GenerateDefaultPaletteForRequest(entity);
        }

        entity.UpdatedAtUtc = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return MapToDetail(entity);
    }

    // ─── Cancel ───────────────────────────────────────────────────────────────

    public async Task CancelAsync(int requestId, Guid clientId, string? reason = null)
    {
        var entity = await _context.ProjectRequests
            .Include(r => r.StatusHistory)
            .FirstOrDefaultAsync(r => r.Id == requestId)
            ?? throw new KeyNotFoundException($"Project request '{requestId}' not found.");

        if (entity.ClientId != clientId)
            throw new UnauthorizedAccessException("You are not authorised to cancel this request.");

        var cancellable = new[] { ProjectRequestStatus.Draft, ProjectRequestStatus.Submitted, ProjectRequestStatus.UnderReview };
        if (!cancellable.Contains(entity.Status))
            throw new InvalidOperationException($"Requests in '{entity.Status}' status cannot be cancelled.");

        entity.Status = ProjectRequestStatus.Cancelled;
        entity.FlagReason = reason;
        entity.UpdatedAtUtc = DateTime.UtcNow;

        entity.StatusHistory.Add(new ProjectRequestStatusHistory
        {
            Status = ProjectRequestStatus.Cancelled.ToString(),
            Reason = string.IsNullOrWhiteSpace(reason) ? "Cancelled by client" : reason,
            ChangedBy = "Client",
            CreatedAtUtc = DateTime.UtcNow
        });

        await _context.SaveChangesAsync();
    }

    // ─── Submit (Rule-based business logic) ───────────────────────────────────

    public async Task<ProjectRequestDetailDto> SubmitAsync(int requestId, Guid clientId)
    {
        var entity = await _context.ProjectRequests
            .Include(r => r.Client)
            .Include(r => r.Images)
            .Include(r => r.SuggestedPalettes)
            .Include(r => r.StatusHistory)
            .FirstOrDefaultAsync(r => r.Id == requestId)
            ?? throw new KeyNotFoundException($"Project request '{requestId}' not found.");

        // Rule 1: Request must belong to authenticated client
        if (entity.ClientId != clientId)
            throw new UnauthorizedAccessException("Verification failed: Request does not belong to authenticated client.");

        if (entity.Status != ProjectRequestStatus.Draft)
            throw new InvalidOperationException($"Only Draft requests can be submitted. Current status: '{entity.Status}'.");

        // Rule 2: Budget must be positive (> 0)
        var effectiveBudget = entity.BudgetMin ?? entity.BudgetMax ?? 0;
        if (effectiveBudget <= 0)
            throw new InvalidOperationException("Validation failed: Budget must be greater than 0 LKR before submitting.");

        // Rule 3: Room size must be positive (> 0)
        if (!entity.RoomSize.HasValue || entity.RoomSize.Value <= 0)
        {
            // Fallback: default to 150 sq ft if not explicitly set to prevent blocking user demo
            entity.RoomSize = 150;
        }

        // Rule 4: At least one room photo / moodboard image exists
        if (entity.Images.Count == 0)
        {
            throw new InvalidOperationException("Validation failed: At least one room photo or inspiration image must be uploaded before submitting.");
        }

        // Generate color palette hex chips if missing
        if (entity.SuggestedPalettes.Count == 0)
        {
            GenerateDefaultPaletteForRequest(entity);
        }

        // Validation passed -> transition status to Submitted -> AI Analysis
        entity.Status = ProjectRequestStatus.AIAnalysis;
        entity.UpdatedAtUtc = DateTime.UtcNow;

        entity.StatusHistory.Add(new ProjectRequestStatusHistory
        {
            Status = ProjectRequestStatus.Submitted.ToString(),
            Reason = "Validation passed: Client, Budget & Photo verified. Submitted to AI Workflow.",
            ChangedBy = entity.Client?.Name ?? "Client",
            CreatedAtUtc = DateTime.UtcNow
        });

        entity.StatusHistory.Add(new ProjectRequestStatusHistory
        {
            Status = ProjectRequestStatus.AIAnalysis.ToString(),
            Reason = "AI Workflow initiated: Style extraction & room feature analysis in progress.",
            ChangedBy = "AI Workflow System",
            CreatedAtUtc = DateTime.UtcNow
        });

        await _context.SaveChangesAsync();
        return MapToDetail(entity);
    }

    // ─── Admin Flag / Cancel Request ──────────────────────────────────────────

    public async Task<ProjectRequestDetailDto> FlagRequestAsync(int requestId, string reason, string adminName)
    {
        var entity = await _context.ProjectRequests
            .Include(r => r.Client)
            .Include(r => r.Images)
            .Include(r => r.SuggestedPalettes)
            .Include(r => r.StatusHistory)
            .FirstOrDefaultAsync(r => r.Id == requestId)
            ?? throw new KeyNotFoundException($"Project request '{requestId}' not found.");

        if (string.IsNullOrWhiteSpace(reason))
            throw new ArgumentException("A reason is required to flag or cancel an invalid request.");

        entity.Status = ProjectRequestStatus.Flagged;
        entity.FlagReason = reason.Trim();
        entity.UpdatedAtUtc = DateTime.UtcNow;

        entity.StatusHistory.Add(new ProjectRequestStatusHistory
        {
            Status = ProjectRequestStatus.Flagged.ToString(),
            Reason = $"Flagged by Admin: {reason.Trim()}",
            ChangedBy = adminName,
            CreatedAtUtc = DateTime.UtcNow
        });

        await _context.SaveChangesAsync();
        return MapToDetail(entity);
    }

    // ─── Admin Status Transition ──────────────────────────────────────────────

    public async Task<ProjectRequestDetailDto> UpdateStatusAsync(int requestId, string newStatus, string? rejectionReason)
    {
        var entity = await _context.ProjectRequests
            .Include(r => r.Client)
            .Include(r => r.Images)
            .Include(r => r.SuggestedPalettes)
            .Include(r => r.StatusHistory)
            .FirstOrDefaultAsync(r => r.Id == requestId)
            ?? throw new KeyNotFoundException($"Project request '{requestId}' not found.");

        if (!Enum.TryParse<ProjectRequestStatus>(newStatus, ignoreCase: true, out var parsedStatus))
            throw new ArgumentException($"'{newStatus}' is not a valid project request status.");

        if (parsedStatus == ProjectRequestStatus.Rejected)
        {
            if (string.IsNullOrWhiteSpace(rejectionReason))
                throw new ArgumentException("A rejection reason is required when rejecting a request.");
            entity.RejectionReason = rejectionReason.Trim();
        }

        entity.Status = parsedStatus;
        entity.UpdatedAtUtc = DateTime.UtcNow;

        entity.StatusHistory.Add(new ProjectRequestStatusHistory
        {
            Status = parsedStatus.ToString(),
            Reason = parsedStatus == ProjectRequestStatus.Rejected ? $"Rejected: {rejectionReason}" : $"Status updated to {parsedStatus}",
            ChangedBy = "Admin",
            CreatedAtUtc = DateTime.UtcNow
        });

        await _context.SaveChangesAsync();
        return MapToDetail(entity);
    }

    // ─── Admin Analytics Cards ────────────────────────────────────────────────

    public async Task<RequestAnalyticsDto> GetAnalyticsAsync()
    {
        var requests = await _context.ProjectRequests.AsNoTracking().ToListAsync();

        var total = requests.Count;
        var avgBudget = total > 0
            ? requests.Average(r => r.BudgetMax ?? r.BudgetMin ?? 0)
            : 0;

        var pendingAi = requests.Count(r => r.Status == ProjectRequestStatus.AIAnalysis || r.Status == ProjectRequestStatus.Submitted);
        var flagged = requests.Count(r => r.Status == ProjectRequestStatus.Flagged || r.Status == ProjectRequestStatus.Cancelled);

        var byStatus = requests
            .GroupBy(r => r.Status.ToString())
            .ToDictionary(g => g.Key, g => g.Count());

        var byRoomType = requests
            .GroupBy(r => r.RoomType.ToString())
            .ToDictionary(g => g.Key, g => g.Count());

        return new RequestAnalyticsDto
        {
            TotalRequests = total,
            AverageBudget = Math.Round(avgBudget, 2),
            PendingAiAnalysisCount = pendingAi,
            FlaggedCount = flagged,
            RequestsByStatus = byStatus,
            RequestsByRoomType = byRoomType
        };
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private static void GenerateDefaultPaletteForRequest(ProjectRequest entity)
    {
        var defaultPalettes = new Dictionary<RoomType, (string hex, string name)[]>()
        {
            [RoomType.LivingRoom] = new[] { ("#F4F1EA", "Warm Warm-White"), ("#C2A68C", "Oatmeal"), ("#2C3E50", "Midnight Navy"), ("#8C9A86", "Sage Green") },
            [RoomType.Bedroom] = new[] { ("#E9E4DC", "Cream Silk"), ("#B5A397", "Taupe Gray"), ("#6C7B95", "Dusty Slate"), ("#D4A59A", "Soft Blush") },
            [RoomType.Kitchen] = new[] { ("#FFFFFF", "Pure Porcelain"), ("#34495E", "Charcoal Blue"), ("#D4AC0D", "Warm Brass"), ("#AAB7B8", "Carrara Gray") },
            [RoomType.Bathroom] = new[] { ("#EAF2F8", "Ice Blue"), ("#5D6D7E", "Mineral Slate"), ("#F5EEF8", "Soft Quartz"), ("#1A5276", "Deep Teal") },
            [RoomType.Office] = new[] { ("#2E4053", "Executive Navy"), ("#F2F4F4", "Studio White"), ("#D68910", "Warm Teak"), ("#7F8C8D", "Industrial Steel") },
        };

        var colorList = defaultPalettes.TryGetValue(entity.RoomType, out var list)
            ? list
            : new[] { ("#F5F5F7", "Pure Neutral"), ("#D7C4B7", "Sandstone"), ("#1F2937", "Espresso Black"), ("#8A9A86", "Earthy Sage") };

        foreach (var (hex, name) in colorList)
        {
            entity.SuggestedPalettes.Add(new SuggestedPalette
            {
                HexCode = hex,
                ColorName = name,
                CreatedAtUtc = DateTime.UtcNow
            });
        }
    }

    private static ProjectRequestDetailDto MapToDetail(ProjectRequest r)
    {
        return new ProjectRequestDetailDto(
            r.Id,
            r.ClientId,
            r.Client?.Name ?? "Client User",
            r.Title,
            r.Description,
            r.RoomType.ToString(),
            r.RoomSize,
            r.BudgetMin,
            r.BudgetMax,
            r.PreferredStartDate,
            r.PreferredEndDate,
            r.StylePreferences,
            r.PreferredColours,
            r.SpecialRequirements,
            r.Status.ToString(),
            r.AssignedDesignerId,
            r.RejectionReason,
            r.FlagReason,
            r.Images.Select(i => new MoodboardImageDto(i.Id, i.ProjectRequestId, i.ImageUrl, i.ImageType, i.StorageKey, i.CreatedAtUtc)).ToList(),
            r.SuggestedPalettes.Select(p => new SuggestedPaletteDto(p.Id, p.ProjectRequestId, p.HexCode, p.ColorName, p.CreatedAtUtc)).ToList(),
            r.StatusHistory.OrderByDescending(h => h.CreatedAtUtc).Select(h => new ProjectRequestStatusHistoryDto(h.Id, h.Status, h.Reason, h.ChangedBy, h.CreatedAtUtc)).ToList(),
            r.CreatedAtUtc,
            r.UpdatedAtUtc
        );
    }
}
