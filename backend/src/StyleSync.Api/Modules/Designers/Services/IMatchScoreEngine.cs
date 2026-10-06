using StyleSync.Api.Modules.Designers.DTOs;
using StyleSync.Api.Modules.Designers.Models;

namespace StyleSync.Api.Modules.Designers.Services;

public interface IMatchScoreEngine
{
    /// <summary>
    /// Pure deterministic calculation of style tag overlap proportion [0.0 - 1.0].
    /// |designer.StyleTags ∩ requestedStyleTags| / |requestedStyleTags|
    /// </summary>
    double CalculateStyleTagOverlap(IEnumerable<string>? designerTags, IEnumerable<string>? requestedTags);

    /// <summary>
    /// Pure deterministic calculation of budget range overlap proportion [0.0 - 1.0] relative to requested range.
    /// </summary>
    double CalculateBudgetRangeOverlap(decimal designerMin, decimal designerMax, decimal requestedMin, decimal requestedMax);

    /// <summary>
    /// Pure deterministic normalized rating [0.0 - 1.0] (averageRating / 5.0, defaults to 0.5 if null).
    /// </summary>
    double CalculatePastRatingNormalized(decimal? averageRating);

    /// <summary>
    /// Pure deterministic availability bonus [0.0 or 1.0] (1 if IsUnderCapacity else 0).
    /// </summary>
    double CalculateAvailabilityBonus(bool isUnderCapacity);

    /// <summary>
    /// Option (a): Computes just the final scalar match score [0.0 - 1.0] according to the weighted formula:
    /// MatchScore = (StyleTagOverlap × 0.40) + (BudgetRangeOverlap × 0.30) + (PastRatingNormalized × 0.20) + (AvailabilityBonus × 0.10)
    /// </summary>
    double ComputeMatchScore(
        DesignerProfile designer,
        bool isUnderCapacity,
        DesignerSearchRequest request);

    /// <summary>
    /// Option (b): Computes both total score and full breakdown:
    /// { styleTagOverlapPct, budgetRangeOverlapPct, pastRatingNormalized, availabilityBonus, matchScore }
    /// </summary>
    (double TotalScore, MatchScoreBreakdown Breakdown) CalculateMatchScore(
        DesignerProfile designer, 
        bool isUnderCapacity, 
        DesignerSearchRequest request);

    /// <summary>
    /// Retrieves a designer by ID and evaluates their match score breakdown against the supplied styleTags/budget parameters.
    /// </summary>
    Task<DesignerMatchScoreBreakdownResponse?> GetDesignerMatchScoreBreakdownAsync(
        int designerId,
        DesignerSearchRequest request,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Public search_designers() tool contract for AI matching agent and search endpoints.
    /// Filters candidates strictly: ListingStatus = Published AND IsUnderCapacity = true.
    /// Returns candidates ranked descending by deterministic MatchScore.
    /// </summary>
    Task<List<DesignerSearchResult>> SearchDesignersAsync(DesignerSearchRequest request, CancellationToken cancellationToken = default);
}
