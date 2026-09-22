using StyleSync.Api.Common.Identity;
using StyleSync.Api.Common.Shared;

namespace StyleSync.Api.Modules.Designers.Models;

public class DesignerProfile : BaseEntity
{
    public int UserId { get; set; }
    public AppUser User { get; set; } = default!;

    public string DisplayName { get; set; } = default!;
    public string Bio { get; set; } = default!;

    public List<string> StyleTags { get; set; } = new();
    public List<string> ServiceCategories { get; set; } = new();

    public decimal PriceRangeMin { get; set; }
    public decimal PriceRangeMax { get; set; }
    public decimal RatePerSqFt { get; set; }

    public bool IsAvailable { get; set; } = true;
    public int MaxConcurrentProjects { get; set; } = 3;
    public decimal? AverageRating { get; set; }

    public ListingStatus ListingStatus { get; set; } = ListingStatus.Draft;

    public ICollection<PortfolioItem> PortfolioItems { get; set; } = new List<PortfolioItem>();
}
