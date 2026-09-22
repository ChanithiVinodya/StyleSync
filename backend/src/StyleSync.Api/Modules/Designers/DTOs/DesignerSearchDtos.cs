using System.ComponentModel.DataAnnotations;
using StyleSync.Api.Modules.Designers.Models;

namespace StyleSync.Api.Modules.Designers.DTOs;

/// <summary>
/// Input search query for the deterministic match-score engine and AI agent tool contract.
/// </summary>
public class DesignerSearchRequest
{
    /// <summary>
    /// Desired interior design style tags (e.g., ["Tropical Modernism", "Minimalist"]).
    /// </summary>
    public List<string> StyleTags { get; set; } = new();

    /// <summary>
    /// Minimum client budget in LKR.
    /// </summary>
    [Range(0, double.MaxValue, ErrorMessage = "BudgetMin must be non-negative.")]
    public decimal BudgetMin { get; set; }

    /// <summary>
    /// Maximum client budget in LKR.
    /// </summary>
    [Range(0, double.MaxValue, ErrorMessage = "BudgetMax must be non-negative.")]
    public decimal BudgetMax { get; set; }
}

/// <summary>
/// Breakdown of how the deterministic match score was computed.
/// </summary>
public class MatchScoreBreakdown
{
    /// <summary>
    /// |designer.StyleTags ∩ requestedStyleTags| / |requestedStyleTags| (Weight: 40%)
    /// </summary>
    public double StyleTagOverlap { get; set; }

    /// <summary>
    /// Overlap of designer's price range with requested budget range as a 0-1 proportion (Weight: 30%)
    /// </summary>
    public double BudgetRangeOverlap { get; set; }

    /// <summary>
    /// designer.AverageRating / 5.0 (defaults to 0.5 if AverageRating is null) (Weight: 20%)
    /// </summary>
    public double PastRatingNormalized { get; set; }

    /// <summary>
    /// 1.0 if IsUnderCapacity else 0.0 (Weight: 10%)
    /// </summary>
    public double AvailabilityBonus { get; set; }
}

/// <summary>
/// Output item from search_designers() tool contract for AI Agent and Client UI.
/// </summary>
public class DesignerSearchResult
{
    public int DesignerId { get; set; }
    public double MatchScore { get; set; }
    public MatchScoreBreakdown ScoreBreakdown { get; set; } = new();

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
    public decimal? AverageRating { get; set; }
    public ListingStatus ListingStatus { get; set; }
    public string? FeaturedPortfolioImageUrl { get; set; }
}
