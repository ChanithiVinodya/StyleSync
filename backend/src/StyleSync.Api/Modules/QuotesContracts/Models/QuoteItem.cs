using System;

namespace StyleSync.Api.Models
{
    // One line of a quote's cost breakdown, e.g. "Lighting fixtures x 6 @ 4,500".
    public class QuoteItem
    {
        public Guid Id { get; set; }

        public Guid QuoteId { get; set; }
        public Quote? Quote { get; set; }

        public string Description { get; set; } = string.Empty;
        public QuoteItemCategory Category { get; set; } = QuoteItemCategory.Other;

        public int Quantity { get; set; } = 1;
        public decimal UnitCost { get; set; }

        // Kept as a stored column (not computed in SQL) so the Validation Agent's
        // "does the cost estimate match the sum of items" check has a concrete
        // value to compare against on both sides.
        public decimal LineTotal { get; set; }
    }
}
