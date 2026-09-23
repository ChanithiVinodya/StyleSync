using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using StyleSync.Api.Models;

namespace StyleSync.Api.DTOs
{
    public class QuoteItemDto
    {
        [Required, MaxLength(300)]
        public string Description { get; set; } = string.Empty;

        public QuoteItemCategory Category { get; set; } = QuoteItemCategory.Other;

        [Range(1, int.MaxValue)]
        public int Quantity { get; set; } = 1;

        [Range(0, double.MaxValue)]
        public decimal UnitCost { get; set; }
    }

    // Used both by the AI-workflow endpoint (system-created draft) and by a
    // Designer creating/revising a quote by hand.
    public class CreateQuoteDto
    {
        [Required]
        public Guid ProjectRequestId { get; set; }

        [Required]
        public Guid DesignerId { get; set; }

        public string? ScopeSummary { get; set; }
        public string? Notes { get; set; }
        public bool IsAiGenerated { get; set; }

        [MinLength(1, ErrorMessage = "A quote needs at least one line item.")]
        public List<QuoteItemDto> Items { get; set; } = new();
    }

    // A designer revising items resets IsAiGenerated to false server-side —
    // that flag is never trusted from the client.
    public class UpdateQuoteDto
    {
        public string? ScopeSummary { get; set; }
        public string? Notes { get; set; }
        public List<QuoteItemDto>? Items { get; set; }
    }

    public class UpdateQuoteStatusDto
    {
        [Required]
        public QuoteStatus Status { get; set; }
    }

    public class QuoteItemResponseDto
    {
        public Guid Id { get; set; }
        public string Description { get; set; } = string.Empty;
        public QuoteItemCategory Category { get; set; }
        public int Quantity { get; set; }
        public decimal UnitCost { get; set; }
        public decimal LineTotal { get; set; }
    }

    public class QuoteResponseDto
    {
        public Guid Id { get; set; }
        public Guid ProjectRequestId { get; set; }
        public Guid DesignerId { get; set; }
        public QuoteStatus Status { get; set; }
        public bool IsAiGenerated { get; set; }
        public string? ScopeSummary { get; set; }
        public string? Notes { get; set; }
        public decimal TotalCost { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public List<QuoteItemResponseDto> Items { get; set; } = new();
        public Guid? ContractId { get; set; }
    }

    // Simple wrapper so list endpoints carry paging info alongside the page of data —
    // required by the "pagination on every component" checklist item.
    public class PagedResult<T>
    {
        public List<T> Items { get; set; } = new();
        public int Page { get; set; }
        public int PageSize { get; set; }
        public int TotalCount { get; set; }
        public int TotalPages => PageSize == 0 ? 0 : (int)Math.Ceiling(TotalCount / (double)PageSize);
    }
}
