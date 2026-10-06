using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Identity;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.Designers.DTOs;
using StyleSync.Api.Modules.Designers.Models;

namespace StyleSync.Api.Modules.Designers.Services;

public class DesignerProfileService : IDesignerProfileService
{
    private readonly AppDbContext _context;
    private readonly ICurrentUser _currentUser;

    public DesignerProfileService(AppDbContext context, ICurrentUser currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<IEnumerable<DesignerProfileResponse>> GetAllAsync()
    {
        var profiles = await _context.DesignerProfiles.ToListAsync();
        return profiles.Select(MapToDto);
    }

    public async Task<DesignerProfileResponse?> GetByIdAsync(int id)
    {
        var profile = await _context.DesignerProfiles.FindAsync(id);
        return profile == null ? null : MapToDto(profile);
    }

    public async Task<DesignerProfileResponse?> GetByUserIdAsync(Guid userId)
    {
        var profile = await _context.DesignerProfiles.FirstOrDefaultAsync(p => p.UserId == userId);
        return profile == null ? null : MapToDto(profile);
    }

    public async Task<DesignerProfileResponse> CreateAsync(CreateDesignerProfileRequest dto)
    {
        var userId = _currentUser.Id;

        var profile = new DesignerProfile
        {
            UserId = userId,
            DisplayName = dto.DisplayName,
            Bio = dto.Bio,
            StyleTags = dto.StyleTags ?? new List<string>(),
            ServiceCategories = dto.ServiceCategories ?? new List<string>(),
            PriceRangeMin = dto.PriceRangeMin,
            PriceRangeMax = dto.PriceRangeMax,
            RatePerSqFt = dto.RatePerSqFt,
            IsAvailable = dto.IsAvailable,
            MaxConcurrentProjects = dto.MaxConcurrentProjects ?? 3,
            ListingStatus = dto.ListingStatus ?? ListingStatus.Published,
            CreatedAtUtc = DateTime.UtcNow,
            UpdatedAtUtc = DateTime.UtcNow
        };

        _context.DesignerProfiles.Add(profile);
        await _context.SaveChangesAsync();

        return MapToDto(profile);
    }

    public async Task<DesignerProfileResponse?> UpdateAsync(int id, UpdateDesignerProfileRequest dto)
    {
        var profile = await _context.DesignerProfiles.FindAsync(id);
        if (profile == null) return null;

        profile.DisplayName = dto.DisplayName;
        profile.Bio = dto.Bio;
        profile.StyleTags = dto.StyleTags ?? new List<string>();
        profile.ServiceCategories = dto.ServiceCategories ?? new List<string>();
        profile.PriceRangeMin = dto.PriceRangeMin;
        profile.PriceRangeMax = dto.PriceRangeMax;
        profile.RatePerSqFt = dto.RatePerSqFt;
        profile.IsAvailable = dto.IsAvailable;
        if (dto.MaxConcurrentProjects.HasValue)
        {
            profile.MaxConcurrentProjects = dto.MaxConcurrentProjects.Value;
        }
        if (dto.ListingStatus.HasValue)
        {
            profile.ListingStatus = dto.ListingStatus.Value;
        }
        profile.UpdatedAtUtc = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return MapToDto(profile);
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var profile = await _context.DesignerProfiles.FindAsync(id);
        if (profile == null) return false;

        _context.DesignerProfiles.Remove(profile);
        await _context.SaveChangesAsync();
        return true;
    }

    private static DesignerProfileResponse MapToDto(DesignerProfile profile)
    {
        return new DesignerProfileResponse
        {
            Id = profile.Id,
            UserId = profile.UserId,
            DisplayName = profile.DisplayName,
            Bio = profile.Bio,
            StyleTags = profile.StyleTags ?? new List<string>(),
            ServiceCategories = profile.ServiceCategories ?? new List<string>(),
            PriceRangeMin = profile.PriceRangeMin,
            PriceRangeMax = profile.PriceRangeMax,
            RatePerSqFt = profile.RatePerSqFt,
            IsAvailable = profile.IsAvailable,
            MaxConcurrentProjects = profile.MaxConcurrentProjects,
            AverageRating = profile.AverageRating,
            ListingStatus = profile.ListingStatus,
            CreatedAtUtc = profile.CreatedAtUtc,
            UpdatedAtUtc = profile.UpdatedAtUtc ?? profile.CreatedAtUtc
        };
    }
}
