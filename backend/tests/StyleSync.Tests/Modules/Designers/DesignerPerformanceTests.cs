using System.Diagnostics;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.Designers.DTOs;
using StyleSync.Api.Modules.Designers.Models;
using StyleSync.Api.Modules.Designers.Services;
using Xunit;
using Xunit.Abstractions;

namespace StyleSync.Tests.Modules.Designers;

public class DesignerPerformanceTests
{
    private readonly ITestOutputHelper _output;

    public DesignerPerformanceTests(ITestOutputHelper output)
    {
        _output = output;
    }

    private AppDbContext CreateInMemoryDbContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        return new AppDbContext(options);
    }

    private async Task SeedDesignersAsync(AppDbContext context, int count = 1000)
    {
        var availableStyles = new[]
        {
            "Tropical Modernism", "Minimalist", "Japandi", "Scandinavian", 
            "Boho Chic", "Industrial", "Coastal", "Classic Luxury", "Contemporary", "Biophilic"
        };

        var designers = new List<DesignerProfile>(count);
        var contracts = new List<ContractStub>();

        var random = new Random(42); // deterministic seed

        for (int i = 1; i <= count; i++)
        {
            var styleCount = random.Next(1, 4);
            var styles = availableStyles.OrderBy(_ => random.Next()).Take(styleCount).ToList();
            
            var minPrice = random.Next(50, 400) * 1000m;
            var maxPrice = minPrice + (random.Next(100, 600) * 1000m);
            var maxConcurrent = random.Next(1, 6);
            var isAvailable = random.NextDouble() > 0.15; // 85% available
            var rating = random.NextDouble() > 0.1 ? (decimal)Math.Round(3.5 + (random.NextDouble() * 1.5), 2) : (decimal?)null;
            var status = (i % 20 == 0) ? ListingStatus.Draft 
                       : (i % 50 == 0) ? ListingStatus.Suspended 
                       : (i % 100 == 0) ? ListingStatus.Archived 
                       : ListingStatus.Published;

            var designer = new DesignerProfile
            {
                Id = i,
                UserId = 1000 + i,
                DisplayName = $"Studio Benchmark {i}",
                Bio = $"Architectural & interior studio specializing in bespoke spatial design and custom furniture #{i}.",
                StyleTags = styles,
                ServiceCategories = new() { "Full Home", "Living Room" },
                PriceRangeMin = minPrice,
                PriceRangeMax = maxPrice,
                RatePerSqFt = random.Next(200, 800),
                IsAvailable = isAvailable,
                MaxConcurrentProjects = maxConcurrent,
                AverageRating = rating,
                ListingStatus = status,
                CreatedAtUtc = DateTime.UtcNow.AddDays(-random.Next(1, 365))
            };

            designers.Add(designer);

            // Seed active contracts for some designers to test capacity guarding at scale
            var activeContractsCount = random.Next(0, maxConcurrent + 2);
            for (int c = 1; c <= activeContractsCount; c++)
            {
                contracts.Add(new ContractStub
                {
                    Id = (i * 10) + c,
                    DesignerId = i,
                    Status = (c <= activeContractsCount - 1) ? ContractStatus.Active : ContractStatus.Completed
                });
            }
        }

        context.DesignerProfiles.AddRange(designers);
        context.Contracts.AddRange(contracts);
        await context.SaveChangesAsync();
    }

    [Fact]
    public async Task SearchDesigners_PerformanceCheck_1000Records_ExecutesUnder250Ms()
    {
        using var context = CreateInMemoryDbContext();
        await SeedDesignersAsync(context, 1000);

        var guard = new CapacityGuardService(context);
        var engine = new MatchScoreEngine(context, guard);

        var request = new DesignerSearchRequest
        {
            StyleTags = new() { "Tropical Modernism", "Minimalist" },
            BudgetMin = 150000m,
            BudgetMax = 500000m
        };

        // Warm up JIT
        _ = await engine.SearchDesignersAsync(request);

        // Benchmark timing
        var stopwatch = Stopwatch.StartNew();
        var results = await engine.SearchDesignersAsync(request);
        stopwatch.Stop();

        _output.WriteLine($"[PERF] SearchDesignersAsync over 1,000 seeded designers completed in {stopwatch.ElapsedMilliseconds} ms (Returned {results.Count} ranked candidates).");

        Assert.NotEmpty(results);
        Assert.True(stopwatch.ElapsedMilliseconds < 250, $"Search took {stopwatch.ElapsedMilliseconds}ms, expected < 250ms");

        // Verify results are sorted descending by MatchScore
        for (int i = 0; i < results.Count - 1; i++)
        {
            Assert.True(results[i].MatchScore >= results[i + 1].MatchScore, "Results must be ranked descending by MatchScore");
            Assert.True(results[i].IsUnderCapacity, "All candidates must be strictly under capacity");
        }
    }

    [Fact]
    public async Task GetPublicListings_PerformanceCheck_1000Records_ExecutesUnder100Ms()
    {
        using var context = CreateInMemoryDbContext();
        await SeedDesignersAsync(context, 1000);

        var guard = new CapacityGuardService(context);
        var service = new DesignerService(context, guard);

        var query = new DesignerQueryParameters
        {
            Style = "Tropical Modernism",
            BudgetMin = 100000m,
            BudgetMax = 600000m,
            Available = true,
            Sort = "rating",
            Page = 1,
            PageSize = 20
        };

        // Warm up JIT
        _ = await service.GetPublicListingsAsync(query);

        // Benchmark timing
        var stopwatch = Stopwatch.StartNew();
        var pagedResult = await service.GetPublicListingsAsync(query);
        stopwatch.Stop();

        _output.WriteLine($"[PERF] GetPublicListingsAsync over 1,000 seeded designers completed in {stopwatch.ElapsedMilliseconds} ms (Page {pagedResult.Page} of {pagedResult.TotalPages}, Total matching: {pagedResult.TotalCount}).");

        Assert.NotEmpty(pagedResult.Items);
        Assert.True(pagedResult.Items.Count <= 20);
        Assert.True(stopwatch.ElapsedMilliseconds < 100, $"Listing query took {stopwatch.ElapsedMilliseconds}ms, expected < 100ms");

        // Verify only Published listings returned
        Assert.All(pagedResult.Items, item => Assert.Equal(ListingStatus.Published, item.ListingStatus));
    }
}
