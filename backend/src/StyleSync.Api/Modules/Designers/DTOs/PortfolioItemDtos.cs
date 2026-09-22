using System.ComponentModel.DataAnnotations;
using StyleSync.Api.Modules.Designers.Models;

namespace StyleSync.Api.Modules.Designers.DTOs;

public class CreatePortfolioItemRequest
{
    [Required(ErrorMessage = "Title is required.")]
    [StringLength(200, ErrorMessage = "Title cannot exceed 200 characters.")]
    public string Title { get; set; } = default!;

    [Required(ErrorMessage = "Description is required.")]
    [StringLength(2000, ErrorMessage = "Description cannot exceed 2000 characters.")]
    public string Description { get; set; } = default!;

    [Required(ErrorMessage = "ImageUrl is required.")]
    [Url(ErrorMessage = "ImageUrl must be a valid URL.")]
    [StringLength(1000, ErrorMessage = "ImageUrl cannot exceed 1000 characters.")]
    public string ImageUrl { get; set; } = default!;

    [Required(ErrorMessage = "BudgetRangeLabel is required.")]
    [StringLength(100, ErrorMessage = "BudgetRangeLabel cannot exceed 100 characters.")]
    public string BudgetRangeLabel { get; set; } = default!;

    [Required(ErrorMessage = "ClientInitials is required.")]
    [StringLength(10, ErrorMessage = "ClientInitials cannot exceed 10 characters.")]
    public string ClientInitials { get; set; } = default!;

    public ListingStatus CompletionStatusBadge { get; set; } = ListingStatus.Published;
}

public class PortfolioItemResponse
{
    public int Id { get; set; }
    public int DesignerProfileId { get; set; }
    public string Title { get; set; } = default!;
    public string Description { get; set; } = default!;
    public string ImageUrl { get; set; } = default!;
    public string BudgetRangeLabel { get; set; } = default!;
    public string ClientInitials { get; set; } = default!;
    public ListingStatus CompletionStatusBadge { get; set; }
    public DateTime CreatedAtUtc { get; set; }
    public DateTime? UpdatedAtUtc { get; set; }
}
