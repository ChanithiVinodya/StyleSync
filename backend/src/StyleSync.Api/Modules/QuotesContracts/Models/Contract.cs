using System;

namespace StyleSync.Api.Models
{
    // Created once, only when a Quote is Accepted (see QuotesController.Accept).
    // Never deleted — only ever cancelled — to preserve the paper trail
    // (PRD section 9, Student 3 Delete row).
    public class Contract
    {
        public Guid Id { get; set; }

        public Guid QuoteId { get; set; }
        public Quote? Quote { get; set; }

        public Guid ProjectRequestId { get; set; }
        public Guid DesignerId { get; set; }
        public Guid ClientId { get; set; }

        public ContractStatus Status { get; set; } = ContractStatus.Draft;

        public decimal TotalAmount { get; set; }

        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public DateTime? SignedAt { get; set; }

        public string? TermsSummary { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
}
