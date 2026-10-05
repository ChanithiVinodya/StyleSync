using System;
using StyleSync.Api.Common.Identity;

namespace StyleSync.Api.Modules.Designers.Models;

public class DesignerProfile
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public AppUser User { get; set; } = null!;
    public string Name { get; set; } = string.Empty;
    public string Specialty { get; set; } = string.Empty;
    public string Location { get; set; } = string.Empty;
    public decimal MatchRate { get; set; }
    public decimal Rating { get; set; }
    public int Reviews { get; set; }
    public string About { get; set; } = string.Empty;
    public string AvatarUrl { get; set; } = string.Empty;
    public string CoverUrl { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}
