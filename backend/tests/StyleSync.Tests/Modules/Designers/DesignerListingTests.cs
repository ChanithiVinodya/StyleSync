using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.Designers.DTOs;
using StyleSync.Api.Modules.Designers.Models;
using StyleSync.Api.Modules.Designers.Services;
using Xunit;

namespace StyleSync.Tests.Modules.Designers;

public class DesignerListingTests
{
    private AppDbContext CreateInMemoryDbContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        return new AppDbContext(options);
    }

    private (DesignerService service, AppDbContext context) SetupTestEnvironment()
    {
        var context = CreateInMemoryDbContext();
        var guard = new CapacityGuardService(context);
        var service = new DesignerService(context, guard);

        // Seed 4 sample designers with diverse traits
        var designer1 = new DesignerProfile
        {
            Id = 1,
            UserId = 101,
            DisplayName = "Studio Alpha",
            Bio = "Minimalist and Japandi specialist",
            StyleTags = new() { "Minimalist", "Japandi" },
            PriceRangeMin = 100000m,
            PriceRangeMax = 300000m,
            RatePerSqFt = 300m,
            AverageRating = 4.9m,
            IsAvailable = true,
            MaxConcurrentProjects = 3,
            ListingStatus = ListingStatus.Published,
            CreatedAtUtc = DateTime.UtcNow.AddDays(-10)
        };

        var designer2 = new DesignerProfile
        {
            Id = 2,
            UserId = 102,
            DisplayName = "Studio Beta",
            Bio = "Industrial & Contemporary spaces",
            StyleTags = new() { "Industrial", "Contemporary" },
            PriceRangeMin = 250000m,
            PriceRangeMax = 600000m,
            RatePerSqFt = 500m,
            AverageRating = 4.5m,
            IsAvailable = true,
            MaxConcurrentProjects = 2,
            ListingStatus = ListingStatus.Published,
            CreatedAtUtc = DateTime.UtcNow.AddDays(-5)
        };

        var designer3 = new DesignerProfile
        {
            Id = 3,
            UserId = 103,
            DisplayName = "Studio Gamma",
            Bio = "Luxury classical estates",
            StyleTags = new() { "Luxury", "Classic" },
            PriceRangeMin = 500000m,
            PriceRangeMax = 1500000m,
            RatePerSqFt = 800m,
            AverageRating = 5.0m,
            IsAvailable = false, // Not available
            MaxConcurrentProjects = 3,
            ListingStatus = ListingStatus.Published,
            CreatedAtUtc = DateTime.UtcNow.AddDays(-1)
        };

        var designer4Draft = new DesignerProfile
        {
            Id = 4,
            UserId = 104,
            DisplayName = "Studio Delta (Draft)",
            Bio = "Not yet published",
            StyleTags = new() { "Minimalist" },
            PriceRangeMin = 80000m,
            PriceRangeMax = 200000m,
            RatePerSqFt = 250m,
            AverageRating = 4.8m,
            IsAvailable = true,
            MaxConcurrentProjects = 3,
            ListingStatus = ListingStatus.Draft, // DRAFT
            CreatedAtUtc = DateTime.UtcNow
        };

        context.DesignerProfiles.AddRange(designer1, designer2, designer3, designer4Draft);

        // Designer 2 is at capacity (2 active contracts / max 2)
        context.Contracts.AddRange(
            new ContractStub { Id = 1, DesignerId = designer2.Id, Status = ContractStatus.Active },
            new ContractStub { Id = 2, DesignerId = designer2.Id, Status = ContractStatus.Active }
        );

        context.SaveChanges();
        return (service, context);
    }

    [Fact]
    public async Task GetPublicListings_OnlyReturnsPublishedDesigners()
    {
        var (service, context) = SetupTestEnvironment();
        using (context)
        {
            var query = new DesignerQueryParameters();
            var result = await service.GetPublicListingsAsync(query);

            // 3 Published, 1 Draft -> TotalCount must be 3
            Assert.Equal(3, result.TotalCount);
            Assert.DoesNotContain(result.Items, d => d.ListingStatus != ListingStatus.Published);
            Assert.DoesNotContain(result.Items, d => d.DisplayName.Contains("Draft"));
        }
    }

    [Fact]
    public async Task GetPublicListings_FiltersByStyleTag()
    {
        var (service, context) = SetupTestEnvironment();
        using (context)
        {
            var query = new DesignerQueryParameters { Style = "Japandi" };
            var result = await service.GetPublicListingsAsync(query);

            Assert.Single(result.Items);
            Assert.Equal("Studio Alpha", result.Items[0].DisplayName);
        }
    }

    [Fact]
    public async Task GetPublicListings_FiltersByBudgetRange()
    {
        var (service, context) = SetupTestEnvironment();
        using (context)
        {
            // High-end budget: min 600,000 LKR
            var query = new DesignerQueryParameters { BudgetMin = 600000m };
            var result = await service.GetPublicListingsAsync(query);

            // Studio Beta (max 600k) and Studio Gamma (max 1.5M) cover 600k
            Assert.Equal(2, result.TotalCount);
            Assert.Contains(result.Items, d => d.DisplayName == "Studio Beta");
            Assert.Contains(result.Items, d => d.DisplayName == "Studio Gamma");
        }
    }

    [Fact]
    public async Task GetPublicListings_FiltersByAvailableTrue_ExcludesUnavailableAndAtCapacityDesigners()
    {
        var (service, context) = SetupTestEnvironment();
        using (context)
        {
            // Designer 1: IsAvailable = true, active = 0/3 (Under capacity) -> Included
            // Designer 2: IsAvailable = true, active = 2/2 (At capacity) -> Excluded
            // Designer 3: IsAvailable = false -> Excluded
            var query = new DesignerQueryParameters { Available = true };
            var result = await service.GetPublicListingsAsync(query);

            Assert.Single(result.Items);
            Assert.Equal("Studio Alpha", result.Items[0].DisplayName);
            Assert.True(result.Items[0].IsUnderCapacity);
        }
    }

    [Fact]
    public async Task GetPublicListings_SortsByRatingDescending()
    {
        var (service, context) = SetupTestEnvironment();
        using (context)
        {
            var query = new DesignerQueryParameters { Sort = "rating" };
            var result = await service.GetPublicListingsAsync(query);

            // Expected order: Studio Gamma (5.0) -> Studio Alpha (4.9) -> Studio Beta (4.5)
            Assert.Equal(3, result.Items.Count);
            Assert.Equal("Studio Gamma", result.Items[0].DisplayName);
            Assert.Equal("Studio Alpha", result.Items[1].DisplayName);
            Assert.Equal("Studio Beta", result.Items[2].DisplayName);
        }
    }

    [Fact]
    public async Task GetPublicListings_SortsByPriceAscending()
    {
        var (service, context) = SetupTestEnvironment();
        using (context)
        {
            var query = new DesignerQueryParameters { Sort = "price_asc" };
            var result = await service.GetPublicListingsAsync(query);

            // Expected order by PriceRangeMin: Alpha (100k) -> Beta (250k) -> Gamma (500k)
            Assert.Equal("Studio Alpha", result.Items[0].DisplayName);
            Assert.Equal("Studio Beta", result.Items[1].DisplayName);
            Assert.Equal("Studio Gamma", result.Items[2].DisplayName);
        }
    }

    [Fact]
    public async Task GetPublicListings_Pagination_ReturnsCorrectPageAndMetadata()
    {
        var (service, context) = SetupTestEnvironment();
        using (context)
        {
            // Page 1, PageSize 2
            var queryPage1 = new DesignerQueryParameters { Page = 1, PageSize = 2, Sort = "rating" };
            var resultPage1 = await service.GetPublicListingsAsync(queryPage1);

            Assert.Equal(2, resultPage1.Items.Count);
            Assert.Equal(3, resultPage1.TotalCount);
            Assert.Equal(2, resultPage1.TotalPages);
            Assert.True(resultPage1.HasNextPage);
            Assert.False(resultPage1.HasPreviousPage);

            // Page 2, PageSize 2
            var queryPage2 = new DesignerQueryParameters { Page = 2, PageSize = 2, Sort = "rating" };
            var resultPage2 = await service.GetPublicListingsAsync(queryPage2);

            Assert.Single(resultPage2.Items);
            Assert.Equal("Studio Beta", resultPage2.Items[0].DisplayName);
            Assert.False(resultPage2.HasNextPage);
            Assert.True(resultPage2.HasPreviousPage);
        }
    }
}
