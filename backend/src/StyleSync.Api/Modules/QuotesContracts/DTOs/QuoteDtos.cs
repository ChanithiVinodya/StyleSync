using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using StyleSync.Api.Models;

namespace StyleSync.Api.DTOs
{
    public class QuoteItemDto
    {
        public Guid? Id { get; set; }

        [Required, MaxLength(300)]
        public string Description { get; set; } = string.Empty;

        public QuoteItemCategory Category { get; set; } = QuoteItemCategory.Other;

        [Range(1, int.MaxValue, ErrorMessage = "Quantity must be at least 1.")]
        public int Quantity { get; set; } = 1;

        [Range(0, double.MaxValue, ErrorMessage = "Unit cost cannot be negative.")]
        public decimal UnitCost { get; set; }
    }

    public class CreateQuoteDto
    {
        [Required]
        public Guid ProjectRequestId { get; set; }

        public Guid? DesignerId { get; set; }

        public string? ScopeSummary { get; set; }
        public string? Notes { get; set; }
        public bool IsAiGenerated { get; set; }

        [MinLength(1, ErrorMessage = "A quote needs at least one line item.")]
        public List<QuoteItemDto> Items { get; set; } = new();
    }

    public class CreateDraftFromAiScopeDto
    {
        public Guid? DesignerId { get; set; }
        public string? ScopeSummary { get; set; }
        public string? Notes { get; set; }

        [MinLength(1, ErrorMessage = "AI draft needs at least one line item.")]
        public List<QuoteItemDto> Items { get; set; } = new();
    }

    public class ReviseQuoteDto
    {
        public string? ScopeSummary { get; set; }
        public string? Notes { get; set; }

        [Required, MinLength(1, ErrorMessage = "A quote revision needs at least one line item.")]
        public List<QuoteItemDto> Items { get; set; } = new();
    }

    public class Stage1DecisionDto
    {
        [Required]
        public Stage1Action Action { get; set; }

        public string? Notes { get; set; }
    }

    public class Stage2DecisionDto
    {
        [Required]
        public Stage2Action Action { get; set; }

        public string? Feedback { get; set; }

        public Guid? ClientId { get; set; }
    }

    public class UpdateQuoteStatusDto
    {
        [Required]
        public QuoteStatus Status { get; set; }
    }

    public class QuoteVersionItemResponseDto
    {
        public Guid Id { get; set; }
        public string Description { get; set; } = string.Empty;
        public QuoteItemCategory Category { get; set; }
        public int Quantity { get; set; }
        public decimal UnitCost { get; set; }
        public decimal LineTotal { get; set; }
    }

    public class QuoteVersionResponseDto
    {
        public Guid Id { get; set; }
        public int VersionNumber { get; set; }
        public Guid AuthorId { get; set; }
        public string AuthorRole { get; set; } = string.Empty;
        public decimal MaterialsSubtotal { get; set; }
        public decimal LaborSubtotal { get; set; }
        public decimal DesignFee { get; set; }
        public decimal ContingencyAmount { get; set; }
        public decimal TaxAmount { get; set; }
        public decimal TotalCost { get; set; }
        public string? Notes { get; set; }
        public DateTime CreatedAt { get; set; }
        public List<QuoteVersionItemResponseDto> Items { get; set; } = new();
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
        public QuoteVersionResponseDto? CurrentVersion { get; set; }
        public List<QuoteVersionResponseDto> Versions { get; set; } = new();
        public List<QuoteItemResponseDto> Items { get; set; } = new();
        public Guid? ContractId { get; set; }
    }

    public class PagedResult<T>
    {
        public List<T> Items { get; set; } = new();
        public int Page { get; set; }
        public int PageSize { get; set; }
        public int TotalCount { get; set; }
        public int TotalPages => PageSize == 0 ? 0 : (int)Math.Ceiling(TotalCount / (double)PageSize);
    }
}
