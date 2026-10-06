using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using StyleSync.Api.Common.Identity;
using StyleSync.Api.Modules.ProjectRequests.Models.Enums;

namespace StyleSync.Api.Modules.ProjectRequests.Models.Entities;

public class ProjectRequest
{
    public Guid Id { get; set; } = Guid.NewGuid();
    
    public string ReferenceCode { get; set; } = string.Empty;
    
    public Guid ClientId { get; set; }
    public AppUser Client { get; set; } = null!;
    
    public Guid? PreferredDesignerId { get; set; }
    public AppUser? PreferredDesigner { get; set; }
    
    public RoomType RoomType { get; set; }
    
    public decimal RoomSizeSqFt { get; set; }
    
    public decimal Budget { get; set; }
    
    public string Description { get; set; } = string.Empty;
    
    [ConcurrencyCheck]
    public RequestStatus Status { get; set; } = RequestStatus.Draft;
    
    public bool IsFlagged { get; set; }
    public string? FlagReason { get; set; }
    public DateTime? FlaggedAt { get; set; }
    public Guid? FlaggedByUserId { get; set; }
    public AppUser? FlaggedByUser { get; set; }
    
    public string? CancelReason { get; set; }
    
    public string? RoomPhotoUrl { get; set; }
    public string? RoomPhotoStorageKey { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? SubmittedAt { get; set; }

    public string? PaletteMode { get; set; }
    public string? PalettePresetId { get; set; }
    public string? PaletteBaseHex { get; set; }

    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public List<string> RequestedStyleTags { get; set; } = new();

    public List<MoodboardImage> MoodboardImages { get; set; } = new();
    public List<SuggestedPalette> SuggestedPalettes { get; set; } = new();
    public List<RequestStatusHistory> StatusHistories { get; set; } = new();
}
