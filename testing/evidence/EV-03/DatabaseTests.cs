using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Models;
using Xunit;

namespace StyleSync.Api.Tests.QuotesContracts;

public class DatabaseTests
{
    private AppDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AppDbContext(options);
    }

    [Fact]
    public async Task Quote_WithItems_IsSaved()
    {
        using var db = CreateDb();

        var quote = new Quote
        {
            Id = Guid.NewGuid(),
            ProjectRequestId = Guid.NewGuid(),
            DesignerId = Guid.NewGuid(),
            ScopeSummary = "Living room redesign",
            Status = QuoteStatus.Draft,
            Items = new List<QuoteItem>
            {
                new QuoteItem
                {
                    Id = Guid.NewGuid(),
                    Description = "Sofa",
                    Quantity = 1,
                    UnitCost = 100000,
                    LineTotal = 100000
                }
            }
        };

        db.Quotes.Add(quote);
        await db.SaveChangesAsync();

        var saved = await db.Quotes
            .Include(q => q.Items)
            .FirstAsync();

        Assert.Single(saved.Items);
        Assert.Equal(100000, saved.Items.First().LineTotal);
    }
}