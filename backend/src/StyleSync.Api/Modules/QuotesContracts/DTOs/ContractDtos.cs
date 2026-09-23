using System;
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
    }
}
