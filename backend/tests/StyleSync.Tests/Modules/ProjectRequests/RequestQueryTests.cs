using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.ProjectRequests.DTOs;
using StyleSync.Api.Modules.ProjectRequests.Models.Entities;
using StyleSync.Api.Modules.ProjectRequests.Models.Enums;
using StyleSync.Api.Modules.ProjectRequests.Services;
using StyleSync.Api.Common.Identity;
using Xunit;

namespace StyleSync.Tests.Modules.ProjectRequests;

public class RequestQueryTests
{
    private AppDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        var context = new AppDbContext(options);
        context.Database.EnsureCreated();
        return context;
    }

    [Fact]
    public async Task Client_CanNeverSeeAnotherClientsRows()
    {
        var context = CreateContext();
        var clientA = Guid.NewGuid();
        var clientB = Guid.NewGuid();

        context.Users.Add(new AppUser { Id = clientA, Name = "Client A", Email = "a@a.com", PasswordHash = "test" });
        context.Users.Add(new AppUser { Id = clientB, Name = "Client B", Email = "b@b.com", PasswordHash = "test" });

        context.ProjectRequests.Add(new ProjectRequest { Id = Guid.NewGuid(), ClientId = clientA, ReferenceCode = "TESTA" });
        context.ProjectRequests.Add(new ProjectRequest { Id = Guid.NewGuid(), ClientId = clientB, ReferenceCode = "TESTB" });
        await context.SaveChangesAsync();

        var service = new RequestQueryService(context);
        
        var resultA = await service.GetRequestsAsync(new RequestQueryParameters(), clientA, "Client");
        Assert.Single(resultA.Items);
        Assert.Equal("TESTA", resultA.Items[0].ReferenceCode);
    }

    [Fact]
    public async Task Admin_CanSeeAll_AndGetsClientDisplayName()
    {
        var context = CreateContext();
        var clientA = Guid.NewGuid();
        
        context.Users.Add(new AppUser { Id = clientA, Name = "Client A", Email = "a@a.com", PasswordHash = "test" });
        context.ProjectRequests.Add(new ProjectRequest { Id = Guid.NewGuid(), ClientId = clientA, ReferenceCode = "TESTA" });
        await context.SaveChangesAsync();

        var service = new RequestQueryService(context);
        
        var resultAdmin = await service.GetRequestsAsync(new RequestQueryParameters(), Guid.NewGuid(), "Admin");
        Assert.Single(resultAdmin.Items);
        Assert.Equal("Client A", resultAdmin.Items[0].ClientDisplayName);
    }

    [Fact]
    public async Task Filters_WorkCorrectly()
    {
        var context = CreateContext();
        var clientId = Guid.NewGuid();
        context.Users.Add(new AppUser { Id = clientId, Name = "Client", Email = "a@a.com", PasswordHash = "test" });

        context.ProjectRequests.AddRange(
            new ProjectRequest { Id = Guid.NewGuid(), ClientId = clientId, Budget = 1000, RoomType = RoomType.LivingRoom, Status = RequestStatus.Draft },
            new ProjectRequest { Id = Guid.NewGuid(), ClientId = clientId, Budget = 5000, RoomType = RoomType.Bedroom, Status = RequestStatus.Submitted },
            new ProjectRequest { Id = Guid.NewGuid(), ClientId = clientId, Budget = 10000, RoomType = RoomType.Kitchen, Status = RequestStatus.Completed }
        );
        await context.SaveChangesAsync();

        var service = new RequestQueryService(context);

        // Budget Filter
        var budgetQuery = await service.GetRequestsAsync(new RequestQueryParameters { MinBudget = 2000, MaxBudget = 6000 }, clientId, "Client");
        Assert.Single(budgetQuery.Items);
        Assert.Equal(5000, budgetQuery.Items[0].Budget);

        // RoomType and Status
        var comboQuery = await service.GetRequestsAsync(new RequestQueryParameters 
        { 
            RoomType = new List<RoomType> { RoomType.Kitchen, RoomType.Bedroom },
            Status = new List<RequestStatus> { RequestStatus.Submitted }
        }, clientId, "Client");
        Assert.Single(comboQuery.Items);
        Assert.Equal(RoomType.Bedroom, comboQuery.Items[0].RoomType);
    }

    [Fact]
    public async Task PaginationAndSorting_WorkCorrectly()
    {
        var context = CreateContext();
        var clientId = Guid.NewGuid();
        context.Users.Add(new AppUser { Id = clientId, Name = "Client", Email = "a@a.com", PasswordHash = "test" });

        for (int i = 1; i <= 15; i++)
        {
            context.ProjectRequests.Add(new ProjectRequest 
            { 
                Id = Guid.NewGuid(), ClientId = clientId, Budget = i * 100, CreatedAt = DateTime.UtcNow.AddMinutes(i)
            });
        }
        await context.SaveChangesAsync();

        var service = new RequestQueryService(context);

        var query = await service.GetRequestsAsync(new RequestQueryParameters 
        { 
            Page = 2, 
            PageSize = 5,
            SortBy = "budget",
            SortDir = "desc"
        }, clientId, "Client");

        // Total 15. Budgets: 1500 down to 100
        // Page 1: 1500, 1400, 1300, 1200, 1100
        // Page 2: 1000, 900, 800, 700, 600
        Assert.Equal(5, query.Items.Count);
        Assert.Equal(1000, query.Items[0].Budget);
        Assert.Equal(600, query.Items[4].Budget);
        Assert.Equal(15, query.TotalCount);
        Assert.Equal(3, query.TotalPages);
    }

    [Fact]
    public async Task PageSize_ClampsTo50()
    {
        var context = CreateContext();
        var service = new RequestQueryService(context);

        var query = await service.GetRequestsAsync(new RequestQueryParameters { PageSize = 100 }, Guid.NewGuid(), "Client");
        Assert.Equal(50, query.PageSize);
    }

    [Fact]
    public async Task InvalidRanges_ThrowArgumentException()
    {
        var context = CreateContext();
        var service = new RequestQueryService(context);

        await Assert.ThrowsAsync<ArgumentException>(() => 
            service.GetRequestsAsync(new RequestQueryParameters { MinBudget = 5000, MaxBudget = 1000 }, Guid.NewGuid(), "Client"));

        await Assert.ThrowsAsync<ArgumentException>(() => 
            service.GetRequestsAsync(new RequestQueryParameters { CreatedFrom = DateTime.UtcNow, CreatedTo = DateTime.UtcNow.AddDays(-1) }, Guid.NewGuid(), "Client"));
    }
}
