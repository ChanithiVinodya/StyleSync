namespace StyleSync.Api.Models
{
    // PRD section 14 — Quote status: Draft → Submitted → Client Review → Revision Requested → Accepted / Rejected
    public enum QuoteStatus
    {
        Draft,
        Submitted,
        ClientReview,
        RevisionRequested,
        Accepted,
        Rejected
    }

    // PRD section 14 — Contract status: Draft → Pending Signature → Active → Completed / Cancelled
    public enum ContractStatus
    {
        Draft,
        PendingSignature,
        Active,
        Completed,
        Cancelled
    }

    // Rough categories for a quote line item — keeps the scope breakdown readable
    public enum QuoteItemCategory
    {
        Design,
        Labor,
        Materials,
        Furniture,
        Other
    }
}
