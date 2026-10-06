using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.Designers.DTOs;
using StyleSync.Api.Modules.Designers.Models;

namespace StyleSync.Api.Modules.Designers.Services;

public class DesignerProfileService : IDesignerProfileService
{
    private readonly AppDbContext _context;

    public DesignerProfileService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<DesignerProfileDto>> GetAllAsync()
    {
        var profiles = await _context.DesignerProfiles.ToListAsync();
        return profiles.Select(MapToDto);
    }

    public async Task<DesignerProfileDto?> GetByIdAsync(Guid id)
    {
        var profile = await _context.DesignerProfiles.FindAsync(id);
        return profile == null ? null : MapToDto(profile);
    }

    public async Task<DesignerProfileDto?> GetByUserIdAsync(Guid userId)
    {
        var profile = await _context.DesignerProfiles.FirstOrDefaultAsync(p => p.UserId == userId);
        return profile == null ? null : MapToDto(profile);
    }

    public async Task<DesignerProfileDto> CreateAsync(CreateDesignerProfileDto dto)
    {
        var profile = new DesignerProfile
        {
            Id = Guid.NewGuid(),
            UserId = dto.UserId,
            Name = dto.Name,
            Specialty = dto.Specialty,
            Location = dto.Location,
            About = dto.About,
            AvatarUrl = dto.AvatarUrl,
            CoverUrl = dto.CoverUrl,
            MatchRate = 100m, // default
            Rating = 5.0m, // default
            Reviews = 0,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _context.DesignerProfiles.Add(profile);
        await _context.SaveChangesAsync();

        return MapToDto(profile);
    }

    public async Task<DesignerProfileDto?> UpdateAsync(Guid id, UpdateDesignerProfileDto dto)
    {
        var profile = await _context.DesignerProfiles.FindAsync(id);
        if (profile == null) return null;

        profile.Name = dto.Name;
        profile.Specialty = dto.Specialty;
        profile.Location = dto.Location;
        profile.About = dto.About;
        profile.AvatarUrl = dto.AvatarUrl;
        profile.CoverUrl = dto.CoverUrl;
        profile.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return MapToDto(profile);
    }

    public async Task<bool> DeleteAsync(Guid id)
    {
        var profile = await _context.DesignerProfiles.FindAsync(id);
        if (profile == null) return false;

        _context.DesignerProfiles.Remove(profile);
        await _context.SaveChangesAsync();
        return true;
    }

    private static DesignerProfileDto MapToDto(DesignerProfile profile)
    {
        return new DesignerProfileDto(
            profile.Id,
            profile.UserId,
            profile.Name,
            profile.Specialty,
            profile.Location,
            profile.MatchRate,
            profile.Rating,
            profile.Reviews,
            profile.About,
            profile.AvatarUrl,
            profile.CoverUrl
        );
    }
}
