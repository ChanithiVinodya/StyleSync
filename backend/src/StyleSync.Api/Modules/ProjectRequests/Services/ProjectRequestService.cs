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
        // Guard: budget min must not exceed max
        if (dto.BudgetMin.HasValue && dto.BudgetMax.HasValue && dto.BudgetMin > dto.BudgetMax)
            throw new ArgumentException("Budget minimum cannot be greater than budget maximum.");

        // Guard: preferred dates must be in future and start before end
        if (dto.PreferredStartDate.HasValue && dto.PreferredStartDate.Value.Date < DateTime.UtcNow.Date)
            throw new ArgumentException("Preferred start date must be today or in the future.");

        if (dto.PreferredStartDate.HasValue && dto.PreferredEndDate.HasValue
            && dto.PreferredStartDate >= dto.PreferredEndDate)
            throw new ArgumentException("Preferred end date must be after start date.");

        var client = await _context.Users.FindAsync(clientId)
            ?? throw new KeyNotFoundException("Client account not found.");

        if (client.Role != UserRole.Client)
            throw new UnauthorizedAccessException("Only clients may submit project requests.");

        var entity = new ProjectRequest
        {
            ClientId = clientId,
            Title = dto.Title.Trim(),
            Description = dto.Description.Trim(),
            RoomType = dto.RoomType,
            BudgetMin = dto.BudgetMin,
            BudgetMax = dto.BudgetMax,
            PreferredStartDate = dto.PreferredStartDate,
            PreferredEndDate = dto.PreferredEndDate,
            StylePreferences = dto.StylePreferences?.Trim(),
            SpecialRequirements = dto.SpecialRequirements?.Trim(),
            Status = dto.SubmitImmediately ? ProjectRequestStatus.Submitted : ProjectRequestStatus.Draft,
            CreatedAtUtc = DateTime.UtcNow,
            UpdatedAtUtc = DateTime.UtcNow
        };

        _context.ProjectRequests.Add(entity);
        await _context.SaveChangesAsync();

        return MapToDetail(entity, client.Name);
    }

    // ─── Read ─────────────────────────────────────────────────────────────────

    public async Task<IReadOnlyList<ProjectRequestSummaryDto>> GetByClientAsync(Guid clientId)
    {
        return await _context.ProjectRequests
            .Where(r => r.ClientId == clientId)
            .OrderByDescending(r => r.CreatedAtUtc)
            .Select(r => new ProjectRequestSummaryDto(
                r.Id,
                r.Title,
                r.RoomType.ToString(),
                r.Status.ToString(),
                r.CreatedAtUtc))
            .ToListAsync();
    }

    public async Task<IReadOnlyList<ProjectRequestSummaryDto>> GetAllAsync()
    {
        return await _context.ProjectRequests
            .OrderByDescending(r => r.CreatedAtUtc)
            .Select(r => new ProjectRequestSummaryDto(
                r.Id,
                r.Title,
                r.RoomType.ToString(),
                r.Status.ToString(),
                r.CreatedAtUtc))
            .ToListAsync();
    }

    public async Task<ProjectRequestDetailDto> GetByIdAsync(int requestId, Guid requestingUserId, string requestingUserRole)
    {
        var entity = await _context.ProjectRequests
            .Include(r => r.Client)
            .FirstOrDefaultAsync(r => r.Id == requestId)
            ?? throw new KeyNotFoundException($"Project request '{requestId}' not found.");

        // Clients may only see their own requests
        if (requestingUserRole == UserRole.Client.ToString() && entity.ClientId != requestingUserId)
            throw new UnauthorizedAccessException("You are not authorised to view this request.");

        return MapToDetail(entity, entity.Client.Name);
    }

    // ─── Update ───────────────────────────────────────────────────────────────

    public async Task<ProjectRequestDetailDto> UpdateAsync(int requestId, Guid clientId, UpdateProjectRequestDto dto)
    {
        var entity = await _context.ProjectRequests
            .Include(r => r.Client)
            .FirstOrDefaultAsync(r => r.Id == requestId)
            ?? throw new KeyNotFoundException($"Project request '{requestId}' not found.");

        if (entity.ClientId != clientId)
            throw new UnauthorizedAccessException("You are not authorised to edit this request.");

        if (entity.Status != ProjectRequestStatus.Draft && entity.Status != ProjectRequestStatus.Submitted)
            throw new InvalidOperationException("Only Draft or Submitted requests may be edited.");

        // Apply updates
        if (!string.IsNullOrWhiteSpace(dto.Title)) entity.Title = dto.Title.Trim();
        if (!string.IsNullOrWhiteSpace(dto.Description)) entity.Description = dto.Description.Trim();
        if (dto.RoomType.HasValue) entity.RoomType = dto.RoomType.Value;
        if (dto.BudgetMin.HasValue) entity.BudgetMin = dto.BudgetMin;
        if (dto.BudgetMax.HasValue) entity.BudgetMax = dto.BudgetMax;
        if (dto.PreferredStartDate.HasValue) entity.PreferredStartDate = dto.PreferredStartDate;
        if (dto.PreferredEndDate.HasValue) entity.PreferredEndDate = dto.PreferredEndDate;
        if (dto.StylePreferences != null) entity.StylePreferences = dto.StylePreferences.Trim();
        if (dto.SpecialRequirements != null) entity.SpecialRequirements = dto.SpecialRequirements.Trim();

        // Re-validate budget range after patching
        if (entity.BudgetMin.HasValue && entity.BudgetMax.HasValue && entity.BudgetMin > entity.BudgetMax)
            throw new ArgumentException("Budget minimum cannot exceed budget maximum.");

        entity.UpdatedAtUtc = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return MapToDetail(entity, entity.Client.Name);
    }

    // ─── Cancel ───────────────────────────────────────────────────────────────

    public async Task CancelAsync(int requestId, Guid clientId)
    {
        var entity = await _context.ProjectRequests.FindAsync(requestId)
            ?? throw new KeyNotFoundException($"Project request '{requestId}' not found.");

        if (entity.ClientId != clientId)
            throw new UnauthorizedAccessException("You are not authorised to cancel this request.");

        var cancellableStatuses = new[]
        {
            ProjectRequestStatus.Draft,
            ProjectRequestStatus.Submitted,
            ProjectRequestStatus.UnderReview
        };

        if (!cancellableStatuses.Contains(entity.Status))
            throw new InvalidOperationException($"Requests in '{entity.Status}' status cannot be cancelled.");

        entity.Status = ProjectRequestStatus.Cancelled;
        entity.UpdatedAtUtc = DateTime.UtcNow;
        await _context.SaveChangesAsync();
    }

    // ─── Admin: Status transitions ────────────────────────────────────────────

    public async Task<ProjectRequestDetailDto> UpdateStatusAsync(int requestId, string newStatus, string? rejectionReason)
    {
        var entity = await _context.ProjectRequests
            .Include(r => r.Client)
            .FirstOrDefaultAsync(r => r.Id == requestId)
            ?? throw new KeyNotFoundException($"Project request '{requestId}' not found.");

        if (!Enum.TryParse<ProjectRequestStatus>(newStatus, ignoreCase: true, out var parsedStatus))
            throw new ArgumentException($"'{newStatus}' is not a valid project request status.");

        // Status transition rules
        var allowedTransitions = new Dictionary<ProjectRequestStatus, ProjectRequestStatus[]>
        {
            [ProjectRequestStatus.Draft]         = [ProjectRequestStatus.Submitted, ProjectRequestStatus.Cancelled],
            [ProjectRequestStatus.Submitted]     = [ProjectRequestStatus.UnderReview, ProjectRequestStatus.Rejected],
            [ProjectRequestStatus.UnderReview]   = [ProjectRequestStatus.QuoteProvided, ProjectRequestStatus.Rejected],
            [ProjectRequestStatus.QuoteProvided] = [ProjectRequestStatus.Accepted, ProjectRequestStatus.Rejected],
        };

        if (!allowedTransitions.TryGetValue(entity.Status, out var allowed) || !allowed.Contains(parsedStatus))
            throw new InvalidOperationException(
                $"Cannot transition from '{entity.Status}' to '{parsedStatus}'.");

        if (parsedStatus == ProjectRequestStatus.Rejected)
        {
            if (string.IsNullOrWhiteSpace(rejectionReason))
                throw new ArgumentException("A rejection reason is required when rejecting a request.");
            entity.RejectionReason = rejectionReason.Trim();
        }

        entity.Status = parsedStatus;
        entity.UpdatedAtUtc = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return MapToDetail(entity, entity.Client.Name);
    }

    // ─── Mapper ───────────────────────────────────────────────────────────────

    private static ProjectRequestDetailDto MapToDetail(ProjectRequest r, string clientName) =>
        new(
            r.Id,
            r.ClientId,
            clientName,
            r.Title,
            r.Description,
            r.RoomType.ToString(),
            r.BudgetMin,
            r.BudgetMax,
            r.PreferredStartDate,
            r.PreferredEndDate,
            r.StylePreferences,
            r.SpecialRequirements,
            r.Status.ToString(),
            r.AssignedDesignerId,
            r.RejectionReason,
            r.CreatedAtUtc,
            r.UpdatedAtUtc
        );
}
