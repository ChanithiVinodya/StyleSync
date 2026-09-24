using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.Designers.DTOs;
using StyleSync.Api.Modules.Designers.Models;
using StyleSync.Api.Modules.Designers.Services;
using Xunit;

namespace StyleSync.Tests.Modules.Designers;

public class MatchScoreEngineTests
{
    private AppDbContext CreateInMemoryDbContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        return new AppDbContext(options);
    }

    [Fact]
    public void CalculateMatchScore_PerfectOverlap_ReturnsMaxScore()
    {
        using var context = CreateInMemoryDbContext();
        var guard = new CapacityGuardService(context);
        var engine = new MatchScoreEngine(context, guard);

        var designer = new DesignerProfile
        {
            Id = 1,
            DisplayName = "Perfect Match Designer",
            Bio = "Bio",
            StyleTags = new() { "Modern", "Minimalist", "Scandinavian" },
            PriceRangeMin = 100000m,
            PriceRangeMax = 300000m,
            AverageRating = 5.0m,
            MaxConcurrentProjects = 3
        };

        var request = new DesignerSearchRequest
        {
            StyleTags = new() { "Modern", "Scandinavian" }, // 100% overlap
            BudgetMin = 100000m,
            BudgetMax = 300000m // 100% overlap
        };

        var (score, breakdown) = engine.CalculateMatchScore(designer, isUnderCapacity: true, request);

        // Style: 1.0 * 0.40 = 0.40
        // Budget: 1.0 * 0.30 = 0.30
        // Rating: (5.0 / 5) * 0.20 = 0.20
        // Availability: 1.0 * 0.10 = 0.10
        // Total = 1.00
        Assert.Equal(1.0, breakdown.StyleTagOverlap);
        Assert.Equal(1.0, breakdown.BudgetRangeOverlap);
        Assert.Equal(1.0, breakdown.PastRatingNormalized);
        Assert.Equal(1.0, breakdown.AvailabilityBonus);
        Assert.Equal(1.0, score);
    }

    [Fact]
    public void CalculateMatchScore_ZeroOverlap_CalculatesAccurately()
    {
        using var context = CreateInMemoryDbContext();
        var guard = new CapacityGuardService(context);
        var engine = new MatchScoreEngine(context, guard);

        var designer = new DesignerProfile
        {
            Id = 1,
            DisplayName = "Zero Match Designer",
            Bio = "Bio",
            StyleTags = new() { "Industrial", "Rustic" },
            PriceRangeMin = 500000m,
            PriceRangeMax = 800000m,
            AverageRating = 0.0m,
            MaxConcurrentProjects = 3
        };

        var request = new DesignerSearchRequest
        {
            StyleTags = new() { "Boho Chic", "Coastal" }, // 0% overlap
            BudgetMin = 100000m,
            BudgetMax = 300000m // 0% overlap ([500k-800k] vs [100k-300k])
        };

        var (score, breakdown) = engine.CalculateMatchScore(designer, isUnderCapacity: true, request);

        // Style: 0.0 * 0.40 = 0.0
        // Budget: 0.0 * 0.30 = 0.0
        // Rating: 0.0 * 0.20 = 0.0
        // Availability: 1.0 * 0.10 = 0.10
        // Total = 0.10
        Assert.Equal(0.0, breakdown.StyleTagOverlap);
        Assert.Equal(0.0, breakdown.BudgetRangeOverlap);
        Assert.Equal(0.0, breakdown.PastRatingNormalized);
        Assert.Equal(1.0, breakdown.AvailabilityBonus);
        Assert.Equal(0.10, score);
    }

    [Fact]
    public void CalculateBudgetRangeOverlap_PartialOverlap_CalculatesProportionCorrectly()
    {
        using var context = CreateInMemoryDbContext();
        var guard = new CapacityGuardService(context);
        var engine = new MatchScoreEngine(context, guard);

        // Designer range: [200k, 400k]
        // Requested range: [100k, 300k] (span = 200k)
        // Overlap: [200k, 300k] (overlap span = 100k)
        // Proportion = 100k / 200k = 0.50 (50%)
        var overlap = engine.CalculateBudgetRangeOverlap(200000m, 400000m, 100000m, 300000m);

        Assert.Equal(0.50, overlap);
    }

    [Fact]
    public void CalculatePastRatingNormalized_NoRatingHistory_DefaultsToHalf()
    {
        using var context = CreateInMemoryDbContext();
        var guard = new CapacityGuardService(context);
        var engine = new MatchScoreEngine(context, guard);

        var designerWithNullRating = new DesignerProfile
        {
            Id = 1,
            DisplayName = "New Designer",
            Bio = "Bio",
            AverageRating = null, // No rating history
            StyleTags = new() { "Tropical Modernism" },
            PriceRangeMin = 100000m,
            PriceRangeMax = 300000m
        };

        var request = new DesignerSearchRequest
        {
            StyleTags = new() { "Tropical Modernism" },
            BudgetMin = 100000m,
            BudgetMax = 300000m
        };

        var (score, breakdown) = engine.CalculateMatchScore(designerWithNullRating, isUnderCapacity: true, request);

        // Rating should normalize to 0.5
        Assert.Equal(0.50, breakdown.PastRatingNormalized);

        // Total score = (1.0 * 0.40) + (1.0 * 0.30) + (0.5 * 0.20) + (1.0 * 0.10)
        //             = 0.40 + 0.30 + 0.10 + 0.10 = 0.90
        Assert.Equal(0.90, score);
    }

    [Fact]
    public async Task SearchDesigners_CapacityExcludedAndUnpublishedDesigners_AreCompletelyExcluded()
    {
        using var context = CreateInMemoryDbContext();
        var guard = new CapacityGuardService(context);
        var engine = new MatchScoreEngine(context, guard);

        // Designer A: Published, 100% style/budget match, but AT CAPACITY (3/3 active projects)
        var designerA = new DesignerProfile
        {
            Id = 1,
            UserId = 101,
            DisplayName = "Designer A (Busy)",
            Bio = "Bio",
            StyleTags = new() { "Modern", "Minimalist" },
            PriceRangeMin = 100000m,
            PriceRangeMax = 300000m,
            AverageRating = 5.0m,
            MaxConcurrentProjects = 3,
            ListingStatus = ListingStatus.Published,
            IsAvailable = true
        };

        // Designer B: Published, 100% match, UNDER CAPACITY (1/3 active projects)
        var designerB = new DesignerProfile
        {
            Id = 2,
            UserId = 102,
            DisplayName = "Designer B (Available)",
            Bio = "Bio",
            StyleTags = new() { "Modern", "Minimalist" },
            PriceRangeMin = 100000m,
            PriceRangeMax = 300000m,
            AverageRating = 4.8m,
            MaxConcurrentProjects = 3,
            ListingStatus = ListingStatus.Published,
            IsAvailable = true
        };

        // Designer C: Draft status (not published), under capacity
        var designerC = new DesignerProfile
        {
            Id = 3,
            UserId = 103,
            DisplayName = "Designer C (Draft)",
            Bio = "Bio",
            StyleTags = new() { "Modern", "Minimalist" },
            PriceRangeMin = 100000m,
            PriceRangeMax = 300000m,
            AverageRating = 4.9m,
            MaxConcurrentProjects = 3,
            ListingStatus = ListingStatus.Draft,
            IsAvailable = true
        };

        context.DesignerProfiles.AddRange(designerA, designerB, designerC);

        // Designer A has 3 active contracts (at limit 3)
        context.Contracts.AddRange(
            new ContractStub { Id = 1, DesignerId = designerA.Id, Status = ContractStatus.Active },
            new ContractStub { Id = 2, DesignerId = designerA.Id, Status = ContractStatus.Active },
            new ContractStub { Id = 3, DesignerId = designerA.Id, Status = ContractStatus.Active }
        );

        // Designer B has 1 active contract (limit 3 -> under capacity)
        context.Contracts.Add(
            new ContractStub { Id = 4, DesignerId = designerB.Id, Status = ContractStatus.Active }
        );

        await context.SaveChangesAsync();

        var searchRequest = new DesignerSearchRequest
        {
            StyleTags = new() { "Modern", "Minimalist" },
            BudgetMin = 100000m,
            BudgetMax = 300000m
        };

        var searchResults = await engine.SearchDesignersAsync(searchRequest);

        // Designer A (at capacity) and Designer C (Draft) must NOT appear in results at all
        Assert.Single(searchResults);
        Assert.Equal(designerB.Id, searchResults[0].DesignerId);
        Assert.Equal("Designer B (Available)", searchResults[0].DisplayName);
        Assert.True(searchResults[0].IsUnderCapacity);
        Assert.Equal(1, searchResults[0].ActiveProjectCount);
    }

    [Fact]
    public async Task Breakdown_FourWeightedComponents_SumToIdenticalMatchScoreFromSearchDesigners()
    {
        using var context = CreateInMemoryDbContext();
        var guard = new CapacityGuardService(context);
        var engine = new MatchScoreEngine(context, guard);

        var designer = new DesignerProfile
        {
            Id = 5,
            UserId = 105,
            DisplayName = "Test Studio",
            Bio = "Bio",
            StyleTags = new() { "Tropical Modernism", "Minimalist", "Japandi" },
            PriceRangeMin = 150000m,
            PriceRangeMax = 450000m,
            AverageRating = 4.75m,
            MaxConcurrentProjects = 3,
            ListingStatus = ListingStatus.Published,
            IsAvailable = true
        };
        context.DesignerProfiles.Add(designer);

        // 1 active project out of 3 -> IsUnderCapacity = true
        context.Contracts.Add(new ContractStub { Id = 1, DesignerId = designer.Id, Status = ContractStatus.Active });
        await context.SaveChangesAsync();

        var searchRequest = new DesignerSearchRequest
        {
            StyleTags = new() { "Tropical Modernism", "Scandinavian" }, // 1 of 2 match = 0.50
            BudgetMin = 200000m,
            BudgetMax = 500000m // Overlap: [200k, 450k] (250k) / 300k span = 0.8333
        };

        // 1. Perform search_designers()
        var searchResults = await engine.SearchDesignersAsync(searchRequest);
        Assert.Single(searchResults);
        var searchItem = searchResults[0];

        // 2. Fetch breakdown for the designer
        var breakdownResponse = await engine.GetDesignerMatchScoreBreakdownAsync(designer.Id, searchRequest);
        Assert.NotNull(breakdownResponse);

        // 3. Confirm (a) scalar calculation, (b) breakdown calculation, and search_designers matchScore are identical
        var scalarScore = engine.ComputeMatchScore(designer, isUnderCapacity: true, searchRequest);
        var (tupleScore, tupleBreakdown) = engine.CalculateMatchScore(designer, isUnderCapacity: true, searchRequest);

        Assert.Equal(searchItem.MatchScore, scalarScore);
        Assert.Equal(searchItem.MatchScore, tupleScore);
        Assert.Equal(searchItem.MatchScore, breakdownResponse.MatchScore);

        // 4. Confirm the breakdown's 4 weighted components sum to the same matchScore
        double weightedSum = (breakdownResponse.StyleTagOverlapPct * MatchScoreEngine.StyleWeight)
                           + (breakdownResponse.BudgetRangeOverlapPct * MatchScoreEngine.BudgetWeight)
                           + (breakdownResponse.PastRatingNormalized * MatchScoreEngine.RatingWeight)
                           + (breakdownResponse.AvailabilityBonus * MatchScoreEngine.AvailabilityWeight);

        Assert.Equal(searchItem.MatchScore, Math.Round(weightedSum, 4));
        Assert.Equal(searchItem.ScoreBreakdown.StyleTagOverlap, breakdownResponse.StyleTagOverlapPct);
        Assert.Equal(searchItem.ScoreBreakdown.BudgetRangeOverlap, breakdownResponse.BudgetRangeOverlapPct);
        Assert.Equal(searchItem.ScoreBreakdown.PastRatingNormalized, breakdownResponse.PastRatingNormalized);
        Assert.Equal(searchItem.ScoreBreakdown.AvailabilityBonus, breakdownResponse.AvailabilityBonus);
    }

    [Fact]
    public async Task GetDesignerMatchScoreBreakdown_NotFound_ReturnsNull()
    {
        using var context = CreateInMemoryDbContext();
        var guard = new CapacityGuardService(context);
        var engine = new MatchScoreEngine(context, guard);

        var request = new DesignerSearchRequest { StyleTags = new() { "Modern" } };
        var result = await engine.GetDesignerMatchScoreBreakdownAsync(999, request);

        Assert.Null(result);
    }
}

