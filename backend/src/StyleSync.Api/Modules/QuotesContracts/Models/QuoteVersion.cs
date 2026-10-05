using System;
using System.Collections.Generic;

namespace StyleSync.Api.Models
{
    /// <summary>
    /// Immutable version snapshot of a quote. Revisions append a new QuoteVersion row (v1, v2, ...).
    /// Business rule: QuoteVersion rows are immutable — no update or delete path exists.
    /// </summary>
    public class QuoteVersion
    {
        public Guid Id { get; set; } = Guid.NewGuid();

        public Guid QuoteId { get; set; }
        public Quote? Quote { get; set; }

        public int VersionNumber { get; set; } = 1;

        public Guid AuthorId { get; set; }
        public string AuthorRole { get; set; } = "Designer"; // "System" | "Designer" | "Admin"

        // Quotation Engine Computed Breakdown (Decimal-safe)
        public decimal MaterialsSubtotal { get; set; }
        public decimal LaborSubtotal { get; set; }
        public decimal DesignFee { get; set; }
        public decimal ContingencyAmount { get; set; }
        public decimal TaxAmount { get; set; }
        public decimal TotalCost { get; set; }

        public string? Notes { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public List<QuoteVersionItem> Items { get; set; } = new();
    }
}
