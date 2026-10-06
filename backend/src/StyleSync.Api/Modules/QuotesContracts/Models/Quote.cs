using System;
using System.Collections.Generic;
using System.Linq;

namespace StyleSync.Api.Models
{
    public class Quote
    {
        public Guid Id { get; set; } = Guid.NewGuid();

        public Guid ProjectRequestId { get; set; }
        public Guid DesignerId { get; set; }

        public QuoteStatus Status { get; set; } = QuoteStatus.Draft;
        public bool IsAiGenerated { get; set; }

        public string? ScopeSummary { get; set; }
        public string? Notes { get; set; }

        // Cached latest total cost from the most recent QuoteVersion
        public decimal TotalCost { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Legacy items collection (for backward compatibility if queried)
        public List<QuoteItem> Items { get; set; } = new();

        // Immutable Version History
        public List<QuoteVersion> Versions { get; set; } = new();

        // Null until Stage 2 client approval creates the contract
        public Contract? Contract { get; set; }

        public QuoteVersion? CurrentVersion => Versions.OrderByDescending(v => v.VersionNumber).FirstOrDefault();
    }
}
