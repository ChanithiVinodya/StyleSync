using StyleSync.Api.Modules.Designers.Models;

namespace StyleSync.Api.Modules.Designers.DTOs;

/// <summary>
/// Query parameters for human-facing public browse/search endpoint (GET /api/designers).
/// </summary>
public class DesignerQueryParameters
{
    /// <summary>
    /// Style tag filter (e.g. "Tropical Modernism", "Minimalist", or comma-separated).
    /// </summary>
    public string? Style { get; set; }

    /// <summary>
    /// Minimum budget filter in LKR.
    /// </summary>
    public decimal? BudgetMin { get; set; }

    /// <summary>
    /// Maximum budget filter in LKR.
    /// </summary>
    public decimal? BudgetMax { get; set; }

    /// <summary>
    /// If true, filters for designers who are available and have free project capacity.
    /// </summary>
    public bool? Available { get; set; }

    /// <summary>
    /// Sort options: "rating", "rating_desc", "price_asc", "price_desc", "newest" (default).
    /// </summary>
    public string? Sort { get; set; }

    /// <summary>
    /// 1-based page number (default 1).
    /// </summary>
    public int Page { get; set; } = 1;

    /// <summary>
    /// Number of items per page (default 10, max 50).
    /// </summary>
    public int PageSize { get; set; } = 10;
}

/// <summary>
/// Summary item for public designer directory listing card.
/// </summary>
public class DesignerListingItemResponse
{
    public int Id { get; set; }
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
    public bool IsAtCapacity { get; set; }
    public decimal? AverageRating { get; set; }
    public ListingStatus ListingStatus { get; set; }
    public int PublishedPortfolioCount { get; set; }
    public string? FeaturedImageUrl { get; set; }
    public DateTime CreatedAtUtc { get; set; }
}

/// <summary>
/// Standard paginated envelope response.
/// </summary>
/// <typeparam name="T">Item type</typeparam>
public class PagedResult<T>
{
    public List<T> Items { get; set; } = new();
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalCount { get; set; }
    public int TotalPages => (int)Math.Ceiling((double)TotalCount / (PageSize > 0 ? PageSize : 10));
    public bool HasNextPage => Page < TotalPages;
    public bool HasPreviousPage => Page > 1;

    public PagedResult() { }

    public PagedResult(List<T> items, int totalCount, int page, int pageSize)
    {
        Items = items;
        TotalCount = totalCount;
        Page = page;
        PageSize = pageSize;
    }
}
