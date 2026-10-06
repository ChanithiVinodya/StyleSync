using System;

namespace StyleSync.Api.Models
{
    /// <summary>
    /// Created once, ONLY when a Quote receives Stage 2 Client Approval.
    /// Never deleted — only transitioned to Cancelled or Completed.
    /// </summary>
    public class Contract
    {
        public Guid Id { get; set; } = Guid.NewGuid();

        public Guid QuoteId { get; set; }
        public Quote? Quote { get; set; }

        public Guid ProjectRequestId { get; set; }
        public Guid DesignerId { get; set; }
        public Guid ClientId { get; set; }

        public ContractStatus Status { get; set; } = ContractStatus.PendingSignature;

        public decimal TotalAmount { get; set; }

        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public DateTime? SignedAt { get; set; }

        public string? TermsSummary { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// Validates state transition according to business rules.
        /// </summary>
        public bool CanTransitionTo(ContractStatus newStatus)
        {
            if (Status == newStatus) return true;
            return (Status, newStatus) switch
            {
                (ContractStatus.PendingSignature, ContractStatus.Active) => true,
                (ContractStatus.PendingSignature, ContractStatus.Cancelled) => true,
                (ContractStatus.Active, ContractStatus.Completed) => true,
                (ContractStatus.Active, ContractStatus.Cancelled) => true,
                _ => false
            };
        }
    }
}
