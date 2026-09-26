using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.Designers.DTOs;
using StyleSync.Api.Modules.Designers.Models;
using StyleSync.Api.Modules.Designers.Services;
using Xunit;

namespace StyleSync.Tests.Modules.Designers;

public class CapacityGuardTests
{
    private AppDbContext CreateInMemoryDbContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        return new AppDbContext(options);
    }

    [Fact]
    public async Task GetActiveProjectCount_CountsOnlyActiveContractsForDesigner()
    {
        using var context = CreateInMemoryDbContext();
        var guardService = new CapacityGuardService(context);

        var designerId = 1;
        var otherDesignerId = 2;

        context.Contracts.AddRange(
            new ContractStub { Id = 1, DesignerId = designerId, Status = ContractStatus.Active },
            new ContractStub { Id = 2, DesignerId = designerId, Status = ContractStatus.Active },
            new ContractStub { Id = 3, DesignerId = designerId, Status = ContractStatus.Completed },
            new ContractStub { Id = 4, DesignerId = designerId, Status = ContractStatus.Cancelled },
            new ContractStub { Id = 5, DesignerId = otherDesignerId, Status = ContractStatus.Active }
        );
        await context.SaveChangesAsync();

        var activeCount = await guardService.GetActiveProjectCountAsync(designerId);

        Assert.Equal(2, activeCount);
    }

    [Fact]
    public async Task Designer_AtExactlyMaxCapacity_IsExcluded()
    {
        using var context = CreateInMemoryDbContext();
        var guardService = new CapacityGuardService(context);

        var designer = new DesignerProfile
        {
            Id = 1,
            UserId = 101,
            DisplayName = "At-Capacity Designer",
            Bio = "Bio",
            MaxConcurrentProjects = 3,
            IsAvailable = true,
            ListingStatus = ListingStatus.Published
        };
        context.DesignerProfiles.Add(designer);

        // Exactly 3 active contracts
        context.Contracts.AddRange(
            new ContractStub { Id = 1, DesignerId = designer.Id, Status = ContractStatus.Active },
            new ContractStub { Id = 2, DesignerId = designer.Id, Status = ContractStatus.Active },
            new ContractStub { Id = 3, DesignerId = designer.Id, Status = ContractStatus.Active }
        );
        await context.SaveChangesAsync();

        var isUnder = await guardService.IsUnderCapacityAsync(designer.Id);
        var candidates = await guardService.FilterCandidatesUnderCapacityAsync(new[] { designer });

        Assert.False(isUnder);
        Assert.Empty(candidates);
    }

    [Fact]
    public async Task Designer_OneUnderLimit_IsIncluded()
    {
        using var context = CreateInMemoryDbContext();
        var guardService = new CapacityGuardService(context);

        var designer = new DesignerProfile
        {
            Id = 1,
            UserId = 101,
            DisplayName = "Available Designer",
            Bio = "Bio",
            MaxConcurrentProjects = 3,
            IsAvailable = true,
            ListingStatus = ListingStatus.Published
        };
        context.DesignerProfiles.Add(designer);

        // 2 active contracts (one under the limit of 3)
        context.Contracts.AddRange(
            new ContractStub { Id = 1, DesignerId = designer.Id, Status = ContractStatus.Active },
            new ContractStub { Id = 2, DesignerId = designer.Id, Status = ContractStatus.Active },
            new ContractStub { Id = 3, DesignerId = designer.Id, Status = ContractStatus.Completed }
        );
        await context.SaveChangesAsync();

        var isUnder = await guardService.IsUnderCapacityAsync(designer.Id);
        var candidates = await guardService.FilterCandidatesUnderCapacityAsync(new[] { designer });

        Assert.True(isUnder);
        Assert.Single(candidates);
        Assert.Equal(designer.Id, candidates[0].Id);
    }

    [Fact]
    public async Task Designer_IsAvailableTrue_ButAtCapacity_IsHardExcluded()
    {
        using var context = CreateInMemoryDbContext();
        var guardService = new CapacityGuardService(context);

        var designerAtCapacity = new DesignerProfile
        {
            Id = 1,
            UserId = 101,
            DisplayName = "Available But Busy",
            Bio = "Bio",
            MaxConcurrentProjects = 2,
            IsAvailable = true, // toggle is TRUE, but capacity is full!
            ListingStatus = ListingStatus.Published
        };

        var designerFree = new DesignerProfile
        {
            Id = 2,
            UserId = 102,
            DisplayName = "Available And Free",
            Bio = "Bio",
            MaxConcurrentProjects = 3,
            IsAvailable = true,
            ListingStatus = ListingStatus.Published
        };

        context.DesignerProfiles.AddRange(designerAtCapacity, designerFree);

        // Designer 1 has 2 active contracts (Max = 2 => At capacity)
        context.Contracts.AddRange(
            new ContractStub { Id = 1, DesignerId = designerAtCapacity.Id, Status = ContractStatus.Active },
            new ContractStub { Id = 2, DesignerId = designerAtCapacity.Id, Status = ContractStatus.Active }
        );
        await context.SaveChangesAsync();

        var candidates = await guardService.FilterCandidatesUnderCapacityAsync(new[] { designerAtCapacity, designerFree });

        // Designer 1 must be excluded regardless of IsAvailable=true
        Assert.Single(candidates);
        Assert.Equal(designerFree.Id, candidates[0].Id);
    }

    [Fact]
    public async Task AdminCapacityOverride_RaisesLimit_ImmediatelyChangesEligibilityOnNextCheck()
    {
        using var context = CreateInMemoryDbContext();
        var guardService = new CapacityGuardService(context);
        var designerService = new DesignerService(context, guardService);

        var designer = new DesignerProfile
        {
            Id = 1,
            UserId = 101,
            DisplayName = "Designer A",
            Bio = "Bio",
            MaxConcurrentProjects = 2,
            IsAvailable = true,
            ListingStatus = ListingStatus.Published
        };
        context.DesignerProfiles.Add(designer);

        // 2 active contracts -> initially at capacity (2 of 2)
        context.Contracts.AddRange(
            new ContractStub { Id = 1, DesignerId = designer.Id, Status = ContractStatus.Active },
            new ContractStub { Id = 2, DesignerId = designer.Id, Status = ContractStatus.Active }
        );
        await context.SaveChangesAsync();

        // 1. Initial check: at capacity
        var isUnderBefore = await guardService.IsUnderCapacityAsync(designer.Id);
        var candidatesBefore = await guardService.FilterCandidatesUnderCapacityAsync(new[] { designer });
        Assert.False(isUnderBefore);
        Assert.Empty(candidatesBefore);

        // 2. Admin overrides MaxConcurrentProjects to 4
        var updateRequest = new UpdateDesignerProfileRequest
        {
            DisplayName = designer.DisplayName,
            Bio = designer.Bio,
            PriceRangeMin = designer.PriceRangeMin,
            PriceRangeMax = designer.PriceRangeMax,
            RatePerSqFt = designer.RatePerSqFt,
            IsAvailable = true,
            MaxConcurrentProjects = 4 // Admin raises limit
        };

        var updatedProfile = await designerService.UpdateProfileAsync(designer.Id, currentUserId: 999, isAdmin: true, updateRequest);

        // DTO immediately reflects new capacity and under-capacity status
        Assert.Equal(4, updatedProfile.MaxConcurrentProjects);
        Assert.Equal(2, updatedProfile.ActiveProjectCount);
        Assert.Equal(2, updatedProfile.RemainingCapacity);
        Assert.True(updatedProfile.IsUnderCapacity);
        Assert.False(updatedProfile.IsAtCapacity);

        // 3. Next check: immediately eligible
        var isUnderAfter = await guardService.IsUnderCapacityAsync(designer.Id);
        var refreshedDesigner = await context.DesignerProfiles.FindAsync(designer.Id);
        var candidatesAfter = await guardService.FilterCandidatesUnderCapacityAsync(new[] { refreshedDesigner! });

        Assert.True(isUnderAfter);
        Assert.Single(candidatesAfter);
        Assert.Equal(designer.Id, candidatesAfter[0].Id);
    }

    [Fact]
    public async Task GetAvailability_ReturnsExactAvailabilityAndCapacityState()
    {
        using var context = CreateInMemoryDbContext();
        var guardService = new CapacityGuardService(context);
        var designerService = new DesignerService(context, guardService);

        var designer = new DesignerProfile
        {
            Id = 42,
            UserId = 101,
            DisplayName = "Availability Test Designer",
            Bio = "Bio",
            MaxConcurrentProjects = 3,
            IsAvailable = true,
            ListingStatus = ListingStatus.Published
        };
        context.DesignerProfiles.Add(designer);

        context.Contracts.AddRange(
            new ContractStub { Id = 1, DesignerId = 42, Status = ContractStatus.Active },
            new ContractStub { Id = 2, DesignerId = 42, Status = ContractStatus.Completed }
        );
        await context.SaveChangesAsync();

        var availability = await designerService.GetAvailabilityAsync(42);

        Assert.NotNull(availability);
        Assert.True(availability.IsAvailable);
        Assert.True(availability.IsUnderCapacity);
        Assert.Equal(1, availability.ActiveProjectCount);
        Assert.Equal(3, availability.MaxConcurrentProjects);
    }
}
