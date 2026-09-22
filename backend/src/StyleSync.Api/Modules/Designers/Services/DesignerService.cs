using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.Designers.DTOs;
using StyleSync.Api.Modules.Designers.Models;

namespace StyleSync.Api.Modules.Designers.Services;

public class DesignerService : IDesignerService
{
    private readonly AppDbContext _context;
    private readonly ICapacityGuardService _capacityGuard;

    public DesignerService(AppDbContext context, ICapacityGuardService capacityGuard)
    {
        _context = context;
        _capacityGuard = capacityGuard;
    }

    public async Task<DesignerProfileResponse?> GetProfileByIdAsync(int id, bool includeUnpublished = false)
    {
        var profile = await _context.DesignerProfiles
            .Include(d => d.PortfolioItems)
            .FirstOrDefaultAsync(d => d.Id == id);

        if (profile == null)
            return null;

        if (!includeUnpublished && profile.ListingStatus != ListingStatus.Published)
            return null;

        var activeProjects = await _capacityGuard.GetActiveProjectCountAsync(profile.Id);

        return MapToResponse(profile, activeProjects, _capacityGuard.IsUnderCapacity(profile, activeProjects), includeUnpublished);
    }

    public async Task<DesignerProfileResponse> CreateProfileAsync(int currentUserId, bool isAdmin, CreateDesignerProfileRequest request)
    {
        if (request.PriceRangeMin > request.PriceRangeMax)
        {
            throw new ArgumentException("PriceRangeMin cannot be greater than PriceRangeMax.");
        }

        if (request.MaxConcurrentProjects.HasValue && request.MaxConcurrentProjects.Value < 1)
        {
            throw new ArgumentException("MaxConcurrentProjects must be at least 1.");
        }

        var existing = await _context.DesignerProfiles.FirstOrDefaultAsync(d => d.UserId == currentUserId);
        if (existing != null)
        {
            throw new InvalidOperationException("A designer profile already exists for this user.");
        }

        var maxProjects = (isAdmin && request.MaxConcurrentProjects.HasValue) 
            ? request.MaxConcurrentProjects.Value 
            : (request.MaxConcurrentProjects ?? 3);

        var profile = new DesignerProfile
        {
            UserId = currentUserId,
            DisplayName = request.DisplayName.Trim(),
            Bio = request.Bio.Trim(),
            StyleTags = request.StyleTags ?? new List<string>(),
            ServiceCategories = request.ServiceCategories ?? new List<string>(),
            PriceRangeMin = request.PriceRangeMin,
            PriceRangeMax = request.PriceRangeMax,
            RatePerSqFt = request.RatePerSqFt,
            IsAvailable = request.IsAvailable,
            MaxConcurrentProjects = maxProjects,
            ListingStatus = ListingStatus.Draft, // new profiles start as Draft
            CreatedAtUtc = DateTime.UtcNow
        };

        await _context.DesignerProfiles.AddAsync(profile);
        await _context.SaveChangesAsync();

        return MapToResponse(profile, 0, isUnderCapacity: true, includeUnpublished: true);
    }

    public async Task<DesignerProfileResponse> UpdateProfileAsync(int id, int currentUserId, bool isAdmin, UpdateDesignerProfileRequest request)
    {
        if (request.PriceRangeMin > request.PriceRangeMax)
        {
            throw new ArgumentException("PriceRangeMin cannot be greater than PriceRangeMax.");
        }

        var profile = await _context.DesignerProfiles
            .Include(d => d.PortfolioItems)
            .FirstOrDefaultAsync(d => d.Id == id);

        if (profile == null)
        {
            throw new KeyNotFoundException($"Designer profile with ID {id} was not found.");
        }

        // Ownership enforcement
        if (!isAdmin && profile.UserId != currentUserId)
        {
            throw new UnauthorizedAccessException("You can only edit your own designer profile.");
        }

        profile.DisplayName = request.DisplayName.Trim();
        profile.Bio = request.Bio.Trim();
        profile.StyleTags = request.StyleTags ?? new List<string>();
        profile.ServiceCategories = request.ServiceCategories ?? new List<string>();
        profile.PriceRangeMin = request.PriceRangeMin;
        profile.PriceRangeMax = request.PriceRangeMax;
        profile.RatePerSqFt = request.RatePerSqFt;
        profile.IsAvailable = request.IsAvailable;
        profile.UpdatedAtUtc = DateTime.UtcNow;

        // Admin-only overrides
        if (isAdmin)
        {
            if (request.MaxConcurrentProjects.HasValue)
            {
                if (request.MaxConcurrentProjects.Value < 1)
                    throw new ArgumentException("MaxConcurrentProjects must be at least 1.");
                profile.MaxConcurrentProjects = request.MaxConcurrentProjects.Value;
            }

            if (request.ListingStatus.HasValue)
            {
                profile.ListingStatus = request.ListingStatus.Value;
            }
        }
        else
        {
            // Non-admin can publish or revert to draft, but cannot suspend/archive
            if (request.ListingStatus.HasValue)
            {
                if (request.ListingStatus.Value == ListingStatus.Draft || request.ListingStatus.Value == ListingStatus.Published)
                {
                    profile.ListingStatus = request.ListingStatus.Value;
                }
                else
                {
                    throw new UnauthorizedAccessException("Only administrators can set Suspended or Archived status.");
                }
            }
        }

        await _context.SaveChangesAsync();

        var activeProjects = await _capacityGuard.GetActiveProjectCountAsync(profile.Id);

        return MapToResponse(profile, activeProjects, _capacityGuard.IsUnderCapacity(profile, activeProjects), includeUnpublished: true);
    }

    public async Task<bool> ArchiveProfileAsync(int id, bool isAdmin)
    {
        if (!isAdmin)
        {
            throw new UnauthorizedAccessException("Only administrators can archive a designer profile.");
        }

        var profile = await _context.DesignerProfiles.FirstOrDefaultAsync(d => d.Id == id);
        if (profile == null)
        {
            return false;
        }

        profile.ListingStatus = ListingStatus.Archived;
        profile.UpdatedAtUtc = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<PortfolioItemResponse> AddPortfolioItemAsync(int designerId, int currentUserId, bool isAdmin, CreatePortfolioItemRequest request)
    {
        var profile = await _context.DesignerProfiles.FirstOrDefaultAsync(d => d.Id == designerId);
        if (profile == null)
        {
            throw new KeyNotFoundException($"Designer profile with ID {designerId} was not found.");
        }

        if (!isAdmin && profile.UserId != currentUserId)
        {
            throw new UnauthorizedAccessException("You can only add portfolio items to your own profile.");
        }

        var item = new PortfolioItem
        {
            DesignerProfileId = designerId,
            Title = request.Title.Trim(),
            Description = request.Description.Trim(),
            ImageUrl = request.ImageUrl.Trim(),
            BudgetRangeLabel = request.BudgetRangeLabel.Trim(),
            ClientInitials = request.ClientInitials.Trim(),
            CompletionStatusBadge = request.CompletionStatusBadge,
            CreatedAtUtc = DateTime.UtcNow
        };

        await _context.PortfolioItems.AddAsync(item);
        await _context.SaveChangesAsync();

        return MapPortfolioItem(item);
    }

    public async Task<List<PortfolioItemResponse>> GetPortfolioItemsAsync(int designerId, bool publicOnly = true)
    {
        var query = _context.PortfolioItems
            .AsNoTracking()
            .Where(p => p.DesignerProfileId == designerId);

        if (publicOnly)
        {
            query = query.Where(p => p.CompletionStatusBadge == ListingStatus.Published);
        }

        var items = await query
            .OrderByDescending(p => p.CreatedAtUtc)
            .ToListAsync();

        return items.Select(MapPortfolioItem).ToList();
    }

    public async Task<bool> DeletePortfolioItemAsync(int designerId, int itemId, int currentUserId, bool isAdmin)
    {
        var item = await _context.PortfolioItems
            .Include(p => p.DesignerProfile)
            .FirstOrDefaultAsync(p => p.Id == itemId && p.DesignerProfileId == designerId);

        if (item == null)
        {
            return false;
        }

        if (!isAdmin && item.DesignerProfile.UserId != currentUserId)
        {
            throw new UnauthorizedAccessException("You can only delete portfolio items from your own profile.");
        }

        _context.PortfolioItems.Remove(item);
        await _context.SaveChangesAsync();
        return true;
    }

    private static DesignerProfileResponse MapToResponse(DesignerProfile profile, int activeProjects, bool isUnderCapacity, bool includeUnpublished)
    {
        var portfolioItems = profile.PortfolioItems
            .Where(p => includeUnpublished || p.CompletionStatusBadge == ListingStatus.Published)
            .OrderByDescending(p => p.CreatedAtUtc)
            .Select(MapPortfolioItem)
            .ToList();

        var remainingCapacity = Math.Max(0, profile.MaxConcurrentProjects - activeProjects);

        return new DesignerProfileResponse
        {
            Id = profile.Id,
            UserId = profile.UserId,
            DisplayName = profile.DisplayName,
            Bio = profile.Bio,
            StyleTags = profile.StyleTags ?? new(),
            ServiceCategories = profile.ServiceCategories ?? new(),
            PriceRangeMin = profile.PriceRangeMin,
            PriceRangeMax = profile.PriceRangeMax,
            RatePerSqFt = profile.RatePerSqFt,
            IsAvailable = profile.IsAvailable,
            MaxConcurrentProjects = profile.MaxConcurrentProjects,
            ActiveProjectCount = activeProjects,
            RemainingCapacity = remainingCapacity,
            IsUnderCapacity = isUnderCapacity,
            IsAtCapacity = !isUnderCapacity,
            AverageRating = profile.AverageRating,
            ListingStatus = profile.ListingStatus,
            CreatedAtUtc = profile.CreatedAtUtc,
            UpdatedAtUtc = profile.UpdatedAtUtc,
            PortfolioItems = portfolioItems
        };
    }

    private static PortfolioItemResponse MapPortfolioItem(PortfolioItem item)
    {
        return new PortfolioItemResponse
        {
            Id = item.Id,
            DesignerProfileId = item.DesignerProfileId,
            Title = item.Title,
            Description = item.Description,
            ImageUrl = item.ImageUrl,
            BudgetRangeLabel = item.BudgetRangeLabel,
            ClientInitials = item.ClientInitials,
            CompletionStatusBadge = item.CompletionStatusBadge,
            CreatedAtUtc = item.CreatedAtUtc,
            UpdatedAtUtc = item.UpdatedAtUtc
        };
    }
}
