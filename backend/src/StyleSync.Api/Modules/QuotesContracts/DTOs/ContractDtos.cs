using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using StyleSync.Api.Models;

namespace StyleSync.Api.DTOs
{
    // Contracts are never created directly through the API — only via
    // POST /api/quotes/{id}/accept — so there is no CreateContractDto.
    // Staff/PM can still update status and dates.
    public class UpdateContractDto
    {
        public ContractStatus? Status { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public string? TermsSummary { get; set; }
    }

    public class SignContractDto
    {
        [Required]
        public DateTime SignedAt { get; set; }
    }

    public class DesignerRecommendationDto
    {
        public Guid UserId { get; set; }
        public int ProfileId { get; set; }
        public string DisplayName { get; set; } = string.Empty;
        public string? Email { get; set; }
        public double MatchScore { get; set; }
        public double StyleTagOverlapPct { get; set; }
        public double BudgetRangeOverlapPct { get; set; }
        public double PastRatingNormalized { get; set; }
        public double AvailabilityBonus { get; set; }
        public decimal? AverageRating { get; set; }
        public List<string> StyleTags { get; set; } = new();
        public decimal PriceRangeMin { get; set; }
        public decimal PriceRangeMax { get; set; }
        public string? FeaturedImageUrl { get; set; }
        public string? Bio { get; set; }
        public string? MatchReason { get; set; }
    }

    public class ContractResponseDto
    {
        public Guid Id { get; set; }
        public Guid QuoteId { get; set; }
        public Guid ProjectRequestId { get; set; }
        public Guid DesignerId { get; set; }
        public Guid ClientId { get; set; }
        public ContractStatus Status { get; set; }
        public decimal TotalAmount { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public DateTime? SignedAt { get; set; }
        public string? TermsSummary { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public QuoteResponseDto? Quote { get; set; }

        public string? DesignerDisplayName { get; set; }
        public string? DesignerEmail { get; set; }
        public string? ClientDisplayName { get; set; }
        public string? ClientEmail { get; set; }
        public string? ProjectReferenceCode { get; set; }
        public string? Description { get; set; }
        public List<DesignerRecommendationDto> RecommendedDesigners { get; set; } = new();
    }
}

