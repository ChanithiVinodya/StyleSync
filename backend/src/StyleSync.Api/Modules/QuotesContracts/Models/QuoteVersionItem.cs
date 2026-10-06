using System;

namespace StyleSync.Api.Models
{
    /// <summary>
    /// Line item belonging to an immutable QuoteVersion snapshot.
    /// </summary>
    public class QuoteVersionItem
    {
        public Guid Id { get; set; } = Guid.NewGuid();

        public Guid QuoteVersionId { get; set; }
        public QuoteVersion? QuoteVersion { get; set; }

        public string Description { get; set; } = string.Empty;
        public QuoteItemCategory Category { get; set; } = QuoteItemCategory.Other;

        public int Quantity { get; set; } = 1;
        public decimal UnitCost { get; set; }
        public decimal LineTotal { get; set; }
    }
}
