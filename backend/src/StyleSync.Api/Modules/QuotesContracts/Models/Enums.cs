using System.Text.Json.Serialization;

namespace StyleSync.Api.Models
{
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public enum QuoteStatus
    {
        Draft,
        Stage1Pending,
        Stage1RevisionRequested,
        Stage1Rejected,
        Stage1Released,
        Stage2Approved,
        Stage2ChangesRequested,
        Stage2Rejected,
        // Legacy aliases for backward compatibility with frontend mock badges
        Submitted = Stage1Pending,
        ClientReview = Stage1Released,
        RevisionRequested = Stage2ChangesRequested,
        Accepted = Stage2Approved,
        Rejected = Stage2Rejected
    }

    [JsonConverter(typeof(JsonStringEnumConverter))]
    public enum ContractStatus
    {
        PendingSignature,
        Active,
        Completed,
        Cancelled,
        // Backward compatibility
        Draft = PendingSignature
    }

    [JsonConverter(typeof(JsonStringEnumConverter))]
    public enum QuoteItemCategory
    {
        Materials,
        Labor,
        Design,
        Furniture,
        Carpentry,
        Electrical,
        Painting,
        Plumbing,
        Textiles,
        Other
    }

    [JsonConverter(typeof(JsonStringEnumConverter))]
    public enum Stage1Action
    {
        Release,
        SendForRevision,
        Reject
    }

    [JsonConverter(typeof(JsonStringEnumConverter))]
    public enum Stage2Action
    {
        Approve,
        RequestChanges,
        Reject
    }
}
