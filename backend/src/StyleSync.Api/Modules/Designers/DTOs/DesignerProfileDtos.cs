using System.ComponentModel.DataAnnotations;
using StyleSync.Api.Modules.Designers.Models;

namespace StyleSync.Api.Modules.Designers.DTOs;

public class CreateDesignerProfileRequest
{
    [Required(ErrorMessage = "DisplayName is required.")]
    [StringLength(200, ErrorMessage = "DisplayName cannot exceed 200 characters.")]
    public string DisplayName { get; set; } = default!;

    [Required(ErrorMessage = "Bio is required.")]
    [StringLength(2000, ErrorMessage = "Bio cannot exceed 2000 characters.")]
    public string Bio { get; set; } = default!;

    public List<string> StyleTags { get; set; } = new();
    public List<string> ServiceCategories { get; set; } = new();

    [Range(0, double.MaxValue, ErrorMessage = "PriceRangeMin must be non-negative.")]
    public decimal PriceRangeMin { get; set; }

    [Range(0, double.MaxValue, ErrorMessage = "PriceRangeMax must be non-negative.")]
    public decimal PriceRangeMax { get; set; }

    [Range(0, double.MaxValue, ErrorMessage = "RatePerSqFt must be non-negative.")]
    public decimal RatePerSqFt { get; set; }

    public bool IsAvailable { get; set; } = true;
    public int? MaxConcurrentProjects { get; set; }
}

public class UpdateDesignerProfileRequest
{
    [Required(ErrorMessage = "DisplayName is required.")]
    [StringLength(200, ErrorMessage = "DisplayName cannot exceed 200 characters.")]
    public string DisplayName { get; set; } = default!;

    [Required(ErrorMessage = "Bio is required.")]
    [StringLength(2000, ErrorMessage = "Bio cannot exceed 2000 characters.")]
    public string Bio { get; set; } = default!;

    public List<string> StyleTags { get; set; } = new();
    public List<string> ServiceCategories { get; set; } = new();

    [Range(0, double.MaxValue, ErrorMessage = "PriceRangeMin must be non-negative.")]
    public decimal PriceRangeMin { get; set; }

    [Range(0, double.MaxValue, ErrorMessage = "PriceRangeMax must be non-negative.")]
    public decimal PriceRangeMax { get; set; }

    [Range(0, double.MaxValue, ErrorMessage = "RatePerSqFt must be non-negative.")]
    public decimal RatePerSqFt { get; set; }

    public bool IsAvailable { get; set; }

    public int? MaxConcurrentProjects { get; set; }
    public ListingStatus? ListingStatus { get; set; }
}

public class DesignerProfileResponse
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string DisplayName { get; set; } = default!;
    public string Bio { get; set; } = default!;
    public List<string> StyleTags { get; set; } = new();
    public List<string> ServiceCategories { get; set; } = new();
    public decimal PriceRangeMin { get; set; }
    public decimal PriceRangeMax { get; set; }
    public decimal RatePerSqFt { get; set; }
    public bool IsAvailable { get; set; }
    public int MaxConcurrentProjects { get; set; }
    public int ActiveProjectCount { get; set; }
    public int RemainingCapacity { get; set; }
    public bool IsUnderCapacity { get; set; }
    public bool IsAtCapacity { get; set; }
    public decimal? AverageRating { get; set; }
    public ListingStatus ListingStatus { get; set; }
    public DateTime CreatedAtUtc { get; set; }
    public DateTime? UpdatedAtUtc { get; set; }
    public List<PortfolioItemResponse> PortfolioItems { get; set; } = new();
}

public class DesignerAvailabilityResponse
{
    public bool IsAvailable { get; set; }
    public bool IsUnderCapacity { get; set; }
    public int ActiveProjectCount { get; set; }
    public int MaxConcurrentProjects { get; set; }
}
