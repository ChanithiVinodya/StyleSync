using Microsoft.EntityFrameworkCore;
using Moq;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Models;
using StyleSync.Api.Modules.Designers.DTOs;
using StyleSync.Api.Modules.Designers.Models;
using StyleSync.Api.Modules.Designers.Services;
using Xunit;

namespace StyleSync.Tests.Modules.Designers;

public class MatchScoreAndCapacityVerificationTests
{
    private AppDbContext CreateInMemoryDbContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        return new AppDbContext(options);
    }

    [Theory]
    [Trait("TestCase", "TC-BE-01")]
    [InlineData(new string[] { "Modern", "Minimalist" }, 100000, 300000, 5.0, true, 1.0000)]
    public void ComputeMatchScore_FullOverlapMaxRatingAvailable_ReturnsOnePointZero(
        string[] designerTags, decimal designerMin, decimal designerMax, double rating, bool isUnderCapacity, double expectedScore)
    {
        using var context = CreateInMemoryDbContext();
        var guardMock = new Mock<ICapacityGuardService>();
        var engine = new MatchScoreEngine(context, guardMock.Object);

        var designer = new DesignerProfile
        {
            Id = 1,
            DisplayName = "Top Designer",
            Bio = "Bio",
            StyleTags = designerTags.ToList(),
            PriceRangeMin = designerMin,
            PriceRangeMax = designerMax,
            AverageRating = (decimal)rating,
            MaxConcurrentProjects = 5
        };

        var request = new DesignerSearchRequest
        {
            StyleTags = new List<string> { "Modern", "Minimalist" },
            BudgetMin = 100000m,
            BudgetMax = 300000m
        };

        var score = engine.ComputeMatchScore(designer, isUnderCapacity, request);

        Assert.Equal(expectedScore, score, precision: 4);
    }

    [Theory]
    [Trait("TestCase", "TC-BE-02")]
    [InlineData(new string[] { "Modern", "Rustic" }, 100000, 200000, 4.0, true, 0.6100)]
    public void ComputeMatchScore_PartialOverlapFourRatingAvailable_ReturnsZeroPointSixtyOne(
        string[] designerTags, decimal designerMin, decimal designerMax, double rating, bool isUnderCapacity, double expectedScore)
    {
        using var context = CreateInMemoryDbContext();
        var guardMock = new Mock<ICapacityGuardService>();
        var engine = new MatchScoreEngine(context, guardMock.Object);

        // Requested: style: ["Modern", "Scandinavian"] (1 of 2 matches -> 0.5)
        // Requested budget: 100,000 - 300,000 (span: 200,000)
        // Designer budget: 100,000 - 200,000 (overlap span: 100,000 -> 100,000 / 200,000 = 0.5)
        // Rating: 4.0 / 5.0 = 0.8
        // Available: true -> 1.0
        // Expected: (0.5 * 0.40) + (0.5 * 0.30) + (0.8 * 0.20) + (1.0 * 0.10) = 0.20 + 0.15 + 0.16 + 0.10 = 0.6100
        var designer = new DesignerProfile
        {
            Id = 2,
            DisplayName = "Mid Match Designer",
            Bio = "Bio",
            StyleTags = designerTags.ToList(),
            PriceRangeMin = designerMin,
            PriceRangeMax = designerMax,
            AverageRating = (decimal)rating,
            MaxConcurrentProjects = 5
        };

        var request = new DesignerSearchRequest
        {
            StyleTags = new List<string> { "Modern", "Scandinavian" },
            BudgetMin = 100000m,
            BudgetMax = 300000m
        };

        var score = engine.ComputeMatchScore(designer, isUnderCapacity, request);

        Assert.Equal(expectedScore, score, precision: 4);
    }

    [Fact]
    [Trait("TestCase", "TC-BE-03")]
    public void ComputeMatchScore_ZeroOverlapNoRatingUnavailable_ReturnsZeroPointTen()
    {
        using var context = CreateInMemoryDbContext();
        var guardMock = new Mock<ICapacityGuardService>();
        var engine = new MatchScoreEngine(context, guardMock.Object);

        // Style: 0 / 2 = 0.0 -> 0.0 * 0.40 = 0.0
        // Budget: 0.0 overlap -> 0.0 * 0.30 = 0.0
        // Rating: null -> default 0.5 -> 0.5 * 0.20 = 0.10
        // Availability: false -> 0.0 * 0.10 = 0.0
        // Expected = 0.1000
        var designer = new DesignerProfile
        {
            Id = 3,
            DisplayName = "Zero Match Designer",
            Bio = "Bio",
            StyleTags = new List<string> { "Industrial", "Bohemian" },
            PriceRangeMin = 400000m,
            PriceRangeMax = 600000m,
            AverageRating = null,
            MaxConcurrentProjects = 3
        };

        var request = new DesignerSearchRequest
        {
            StyleTags = new List<string> { "Modern", "Minimalist" },
            BudgetMin = 100000m,
            BudgetMax = 200000m
        };

        var score = engine.ComputeMatchScore(designer, isUnderCapacity: false, request);

        Assert.Equal(0.1000, score, precision: 4);
    }

    [Theory]
    [Trait("TestCase", "TC-BE-04")]
    [InlineData(new string[] { "Modern", "Minimalist" }, 100000, 300000, 5.0, false, 0.9000)]
    public void ComputeMatchScore_FullOverlapMaxRatingUnavailable_ReturnsZeroPointNinety(
        string[] designerTags, decimal designerMin, decimal designerMax, double rating, bool isUnderCapacity, double expectedScore)
    {
        using var context = CreateInMemoryDbContext();
        var guardMock = new Mock<ICapacityGuardService>();
        var engine = new MatchScoreEngine(context, guardMock.Object);

        // Style: 1.0 * 0.40 = 0.40
        // Budget: 1.0 * 0.30 = 0.30
        // Rating: (5.0 / 5) * 0.20 = 0.20
        // Availability: 0.0 * 0.10 = 0.00
        // Total = 0.9000
        var designer = new DesignerProfile
        {
            Id = 4,
            DisplayName = "Busy Top Designer",
            Bio = "Bio",
            StyleTags = designerTags.ToList(),
            PriceRangeMin = designerMin,
            PriceRangeMax = designerMax,
            AverageRating = (decimal)rating,
            MaxConcurrentProjects = 3
        };

        var request = new DesignerSearchRequest
        {
            StyleTags = new List<string> { "Modern", "Minimalist" },
            BudgetMin = 100000m,
            BudgetMax = 300000m
        };

        var score = engine.ComputeMatchScore(designer, isUnderCapacity, request);

        Assert.Equal(expectedScore, score, precision: 4);
    }

    [Theory]
    [Trait("TestCase", "TC-BE-05")]
    [InlineData(new string[] { "Modern" }, new string[] { "Modern" }, 100000, 200000, 100000, 200000, 5.0, true)]
    [InlineData(new string[] { "Modern" }, new string[] { "Vintage" }, 100000, 200000, 300000, 400000, 0.0, false)]
    [InlineData(new string[] { "Modern", "Vintage" }, new string[] { "Modern", "Industrial" }, 150000, 250000, 100000, 200000, 3.5, true)]
    [InlineData(new string[] { }, new string[] { "Modern" }, 0, 0, 100000, 200000, null, false)]
    [InlineData(new string[] { "Modern" }, new string[] { }, 100000, 200000, 0, 0, 2.5, true)]
    [InlineData(new string[] { "ArtDeco" }, new string[] { "ArtDeco" }, 50000, 150000, 100000, 100000, 4.8, false)]
    public void ComputeMatchScore_GridOfValidInputs_ReturnsScoreBetweenZeroAndOne(
        string[] designerTags, string[] requestTags,
        decimal designerMin, decimal designerMax,
        decimal reqMin, decimal reqMax,
        double? rating, bool isUnderCapacity)
    {
        using var context = CreateInMemoryDbContext();
        var guardMock = new Mock<ICapacityGuardService>();
        var engine = new MatchScoreEngine(context, guardMock.Object);

        var designer = new DesignerProfile
        {
            Id = 10,
            DisplayName = "Grid Test Designer",
            Bio = "Bio",
            StyleTags = designerTags.ToList(),
            PriceRangeMin = designerMin,
            PriceRangeMax = designerMax,
            AverageRating = rating.HasValue ? (decimal)rating.Value : null,
            MaxConcurrentProjects = 5
        };

        var request = new DesignerSearchRequest
        {
            StyleTags = requestTags.ToList(),
            BudgetMin = reqMin,
            BudgetMax = reqMax
        };

        var score = engine.ComputeMatchScore(designer, isUnderCapacity, request);

        Assert.InRange(score, 0.0, 1.0);
    }

    [Theory]
    [Trait("TestCase", "TC-BE-06")]
    [InlineData(2, 3, true)]
    public void IsUnderCapacity_ActiveBelowMaxCapacity_ReturnsTrue(int activeCount, int maxConcurrent, bool expected)
    {
        using var context = CreateInMemoryDbContext();
        var guardService = new CapacityGuardService(context);

        var designer = new DesignerProfile
        {
            Id = 20,
            DisplayName = "Available Designer",
            Bio = "Bio",
            MaxConcurrentProjects = maxConcurrent
        };

        var result = guardService.IsUnderCapacity(designer, activeCount);

        Assert.Equal(expected, result);
    }

    [Theory]
    [Trait("TestCase", "TC-BE-07")]
    [InlineData(3, 3, false)]
    public void IsUnderCapacity_ActiveEqualsMaxCapacity_ReturnsFalse(int activeCount, int maxConcurrent, bool expected)
    {
        using var context = CreateInMemoryDbContext();
        var guardService = new CapacityGuardService(context);

        var designer = new DesignerProfile
        {
            Id = 21,
            DisplayName = "Maxed Out Designer",
            Bio = "Bio",
            MaxConcurrentProjects = maxConcurrent
        };

        var result = guardService.IsUnderCapacity(designer, activeCount);

        Assert.Equal(expected, result);
    }

    [Theory]
    [Trait("TestCase", "TC-BE-08")]
    [InlineData(0, 0, false)]
    public void IsUnderCapacity_ZeroMaxCapacityZeroActive_ReturnsFalse(int activeCount, int maxConcurrent, bool expected)
    {
        using var context = CreateInMemoryDbContext();
        var guardService = new CapacityGuardService(context);

        var designer = new DesignerProfile
        {
            Id = 22,
            DisplayName = "Zero Capacity Designer",
            Bio = "Bio",
            MaxConcurrentProjects = maxConcurrent
        };

        var result = guardService.IsUnderCapacity(designer, activeCount);

        Assert.Equal(expected, result);
    }

    [Fact]
    [Trait("TestCase", "TC-BE-09")]
    public async Task SearchDesignersAsync_ThreeDesignersMixedEligibility_ReturnsOnlyEligibleDesignerRankedByScore()
    {
        using var context = CreateInMemoryDbContext();

        var eligibleUserId = Guid.NewGuid();
        var atCapacityUserId = Guid.NewGuid();
        var suspendedUserId = Guid.NewGuid();

        var eligibleDesigner = new DesignerProfile
        {
            Id = 101,
            UserId = eligibleUserId,
            DisplayName = "Eligible Designer",
            Bio = "Bio",
            ListingStatus = ListingStatus.Published,
            MaxConcurrentProjects = 5,
            StyleTags = new List<string> { "Modern", "Minimalist" },
            PriceRangeMin = 100000m,
            PriceRangeMax = 300000m,
            AverageRating = 4.8m,
            IsAvailable = true
        };

        var atCapacityDesigner = new DesignerProfile
        {
            Id = 102,
            UserId = atCapacityUserId,
            DisplayName = "At Capacity Designer",
            Bio = "Bio",
            ListingStatus = ListingStatus.Published,
            MaxConcurrentProjects = 2,
            StyleTags = new List<string> { "Modern", "Minimalist" },
            PriceRangeMin = 100000m,
            PriceRangeMax = 300000m,
            AverageRating = 5.0m,
            IsAvailable = true
        };

        var suspendedDesigner = new DesignerProfile
        {
            Id = 103,
            UserId = suspendedUserId,
            DisplayName = "Suspended Designer",
            Bio = "Bio",
            ListingStatus = ListingStatus.Suspended,
            MaxConcurrentProjects = 5,
            StyleTags = new List<string> { "Modern", "Minimalist" },
            PriceRangeMin = 100000m,
            PriceRangeMax = 300000m,
            AverageRating = 4.9m,
            IsAvailable = true
        };

        context.DesignerProfiles.AddRange(eligibleDesigner, atCapacityDesigner, suspendedDesigner);
        await context.SaveChangesAsync();

        // Configure Moq for ICapacityGuardService
        var guardMock = new Mock<ICapacityGuardService>();

        // Batch counts: Designer 101 has 1 active project, Designer 102 has 2 active projects
        guardMock
            .Setup(g => g.GetActiveProjectCountsAsync(It.IsAny<IEnumerable<int>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new Dictionary<int, int>
            {
                { 101, 1 },
                { 102, 2 }
            });

        // Designer 101 (active 1 < max 5) -> isUnderCapacity = true
        guardMock
            .Setup(g => g.IsUnderCapacity(It.Is<DesignerProfile>(d => d.Id == 101), 1))
            .Returns(true);

        // Designer 102 (active 2 >= max 2) -> isUnderCapacity = false
        guardMock
            .Setup(g => g.IsUnderCapacity(It.Is<DesignerProfile>(d => d.Id == 102), 2))
            .Returns(false);

        var engine = new MatchScoreEngine(context, guardMock.Object);

        var request = new DesignerSearchRequest
        {
            StyleTags = new List<string> { "Modern", "Minimalist" },
            BudgetMin = 100000m,
            BudgetMax = 300000m
        };

        // Act
        var results = await engine.SearchDesignersAsync(request);

        // Assert
        // 1. Only the eligible designer (Published AND IsUnderCapacity == true) is returned
        Assert.Single(results);
        var returned = Assert.Single(results);
        Assert.Equal(101, returned.DesignerId);
        Assert.Equal("Eligible Designer", returned.DisplayName);
        Assert.True(returned.IsUnderCapacity);
        Assert.True(returned.MatchScore > 0.0);
    }
}
