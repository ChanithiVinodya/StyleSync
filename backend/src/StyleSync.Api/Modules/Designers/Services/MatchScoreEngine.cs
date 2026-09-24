using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.Designers.DTOs;
using StyleSync.Api.Modules.Designers.Models;

namespace StyleSync.Api.Modules.Designers.Services;

public class MatchScoreEngine : IMatchScoreEngine
{
    private readonly AppDbContext _context;
    private readonly ICapacityGuardService _capacityGuard;

    // Weights specified by formula (Prompt 4)
    public const double StyleWeight = 0.40;
    public const double BudgetWeight = 0.30;
    public const double RatingWeight = 0.20;
    public const double AvailabilityWeight = 0.10;

    public MatchScoreEngine(AppDbContext context, ICapacityGuardService capacityGuard)
    {
        _context = context;
        _capacityGuard = capacityGuard;
    }

    /// <inheritdoc />
    public double CalculateStyleTagOverlap(IEnumerable<string>? designerTags, IEnumerable<string>? requestedTags)
    {
        if (requestedTags == null)
            return 1.0;

        var requestedList = requestedTags
            .Where(t => !string.IsNullOrWhiteSpace(t))
            .Select(t => t.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        if (requestedList.Count == 0)
            return 1.0; // No filter requested -> full overlap

        if (designerTags == null)
            return 0.0;

        var designerSet = designerTags
            .Where(t => !string.IsNullOrWhiteSpace(t))
            .Select(t => t.Trim())
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        if (designerSet.Count == 0)
            return 0.0;

        int matchCount = requestedList.Count(req => designerSet.Contains(req));
        return Math.Clamp((double)matchCount / requestedList.Count, 0.0, 1.0);
    }

    /// <inheritdoc />
    public double CalculateBudgetRangeOverlap(decimal designerMin, decimal designerMax, decimal requestedMin, decimal requestedMax)
    {
        // Normalize ranges
        if (designerMin > designerMax)
            (designerMin, designerMax) = (designerMax, designerMin);

        if (requestedMin > requestedMax)
            (requestedMin, requestedMax) = (requestedMax, requestedMin);

        // If no budget requested, default to full overlap
        if (requestedMin <= 0 && requestedMax <= 0)
            return 1.0;

        decimal requestedSpan = requestedMax - requestedMin;
        if (requestedSpan <= 0)
        {
            // Point budget
            return (requestedMin >= designerMin && requestedMin <= designerMax) ? 1.0 : 0.0;
        }

        decimal overlapStart = Math.Max(designerMin, requestedMin);
        decimal overlapEnd = Math.Min(designerMax, requestedMax);
        decimal overlapSpan = Math.Max(0, overlapEnd - overlapStart);

        double proportion = (double)(overlapSpan / requestedSpan);
        return Math.Clamp(proportion, 0.0, 1.0);
    }

    /// <inheritdoc />
    public double CalculatePastRatingNormalized(decimal? averageRating)
    {
        if (!averageRating.HasValue)
            return 0.5; // default to 0.5 when no rating history yet

        double normalized = (double)averageRating.Value / 5.0;
        return Math.Clamp(normalized, 0.0, 1.0);
    }

    /// <inheritdoc />
    public double CalculateAvailabilityBonus(bool isUnderCapacity)
    {
        return isUnderCapacity ? 1.0 : 0.0;
    }

    /// <inheritdoc />
    public double ComputeMatchScore(
        DesignerProfile designer, 
        bool isUnderCapacity, 
        DesignerSearchRequest request)
    {
        double styleOverlap = CalculateStyleTagOverlap(designer.StyleTags, request.StyleTags);
        double budgetOverlap = CalculateBudgetRangeOverlap(designer.PriceRangeMin, designer.PriceRangeMax, request.BudgetMin, request.BudgetMax);
        double ratingNormalized = CalculatePastRatingNormalized(designer.AverageRating);
        double availabilityBonus = CalculateAvailabilityBonus(isUnderCapacity);

        double totalScore = (styleOverlap * StyleWeight)
                          + (budgetOverlap * BudgetWeight)
                          + (ratingNormalized * RatingWeight)
                          + (availabilityBonus * AvailabilityWeight);

        return Math.Round(totalScore, 4);
    }

    /// <inheritdoc />
    public (double TotalScore, MatchScoreBreakdown Breakdown) CalculateMatchScore(
        DesignerProfile designer, 
        bool isUnderCapacity, 
        DesignerSearchRequest request)
    {
        double styleOverlap = CalculateStyleTagOverlap(designer.StyleTags, request.StyleTags);
        double budgetOverlap = CalculateBudgetRangeOverlap(designer.PriceRangeMin, designer.PriceRangeMax, request.BudgetMin, request.BudgetMax);
        double ratingNormalized = CalculatePastRatingNormalized(designer.AverageRating);
        double availabilityBonus = CalculateAvailabilityBonus(isUnderCapacity);

        double totalScore = (styleOverlap * StyleWeight)
                          + (budgetOverlap * BudgetWeight)
                          + (ratingNormalized * RatingWeight)
                          + (availabilityBonus * AvailabilityWeight);

        var roundedTotal = Math.Round(totalScore, 4);

        var breakdown = new MatchScoreBreakdown
        {
            StyleTagOverlap = Math.Round(styleOverlap, 4),
            BudgetRangeOverlap = Math.Round(budgetOverlap, 4),
            PastRatingNormalized = Math.Round(ratingNormalized, 4),
            AvailabilityBonus = Math.Round(availabilityBonus, 4),
            MatchScore = roundedTotal
        };

        return (roundedTotal, breakdown);
    }

    /// <inheritdoc />
    public async Task<DesignerMatchScoreBreakdownResponse?> GetDesignerMatchScoreBreakdownAsync(
        int designerId,
        DesignerSearchRequest request,
        CancellationToken cancellationToken = default)
    {
        var designer = await _context.DesignerProfiles
            .AsNoTracking()
            .FirstOrDefaultAsync(d => d.Id == designerId, cancellationToken);

        if (designer == null)
            return null;

        int activeCount = await _capacityGuard.GetActiveProjectCountAsync(designerId, cancellationToken);
        bool isUnderCapacity = _capacityGuard.IsUnderCapacity(designer, activeCount);

        var (score, breakdown) = CalculateMatchScore(designer, isUnderCapacity, request);

        return new DesignerMatchScoreBreakdownResponse
        {
            DesignerId = designer.Id,
            StyleTagOverlapPct = breakdown.StyleTagOverlap,
            BudgetRangeOverlapPct = breakdown.BudgetRangeOverlap,
            PastRatingNormalized = breakdown.PastRatingNormalized,
            AvailabilityBonus = breakdown.AvailabilityBonus,
            MatchScore = score
        };
    }

    /// <inheritdoc />
    public async Task<List<DesignerSearchResult>> SearchDesignersAsync(DesignerSearchRequest request, CancellationToken cancellationToken = default)
    {
        // 1. Query only Published designers with their portfolio items
        var publishedDesigners = await _context.DesignerProfiles
            .AsNoTracking()
            .Include(d => d.PortfolioItems)
            .Where(d => d.ListingStatus == ListingStatus.Published)
            .ToListAsync(cancellationToken);

        if (!publishedDesigners.Any())
        {
            return new List<DesignerSearchResult>();
        }

        // 2. Fetch active project counts and enforce hard capacity guard
        var designerIds = publishedDesigners.Select(d => d.Id).ToList();
        var activeCounts = await _capacityGuard.GetActiveProjectCountsAsync(designerIds, cancellationToken);

        // Only designers where IsUnderCapacity = true are eligible candidates at all
        var eligibleCandidates = publishedDesigners
            .Where(d => _capacityGuard.IsUnderCapacity(d, activeCounts.TryGetValue(d.Id, out var c) ? c : 0))
            .ToList();

        // 3. Score and rank candidates
        var results = new List<DesignerSearchResult>();

        foreach (var designer in eligibleCandidates)
        {
            int activeCount = activeCounts.TryGetValue(designer.Id, out var c) ? c : 0;
            bool isUnderCapacity = _capacityGuard.IsUnderCapacity(designer, activeCount);
            var (score, breakdown) = CalculateMatchScore(designer, isUnderCapacity, request);

            var featuredImage = designer.PortfolioItems
                .Where(p => p.CompletionStatusBadge == ListingStatus.Published)
                .OrderByDescending(p => p.CreatedAtUtc)
                .Select(p => p.ImageUrl)
                .FirstOrDefault();

            results.Add(new DesignerSearchResult
            {
                DesignerId = designer.Id,
                MatchScore = score,
                ScoreBreakdown = breakdown,
                DisplayName = designer.DisplayName,
                Bio = designer.Bio,
                StyleTags = designer.StyleTags ?? new(),
                ServiceCategories = designer.ServiceCategories ?? new(),
                PriceRangeMin = designer.PriceRangeMin,
                PriceRangeMax = designer.PriceRangeMax,
                RatePerSqFt = designer.RatePerSqFt,
                IsAvailable = designer.IsAvailable,
                MaxConcurrentProjects = designer.MaxConcurrentProjects,
                ActiveProjectCount = activeCount,
                RemainingCapacity = Math.Max(0, designer.MaxConcurrentProjects - activeCount),
                IsUnderCapacity = isUnderCapacity,
                AverageRating = designer.AverageRating,
                ListingStatus = designer.ListingStatus,
                FeaturedPortfolioImageUrl = featuredImage
            });
        }

        // 4. Sort descending by MatchScore, then by AverageRating, then DisplayName
        return results
            .OrderByDescending(r => r.MatchScore)
            .ThenByDescending(r => r.AverageRating ?? 0)
            .ThenBy(r => r.DisplayName)
            .ToList();
    }
}
