using StyleSync.Api.Common.Shared;

namespace StyleSync.Api.Modules.Designers.Models;

public class PortfolioItem : BaseEntity
{
    public int DesignerProfileId { get; set; }
    public DesignerProfile DesignerProfile { get; set; } = default!;

    public string Title { get; set; } = default!;
    public string Description { get; set; } = default!;
    public string ImageUrl { get; set; } = default!;
    public string BudgetRangeLabel { get; set; } = default!;
    public string ClientInitials { get; set; } = default!;
    public ListingStatus CompletionStatusBadge { get; set; } = ListingStatus.Published;
}
