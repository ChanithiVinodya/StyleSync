using System;
using System.Collections.Generic;

namespace StyleSync.Api.Models
{
    // Owned by Student 3. Created either as a draft from the Budget/Scope Agent's
    // output, or directly by a Designer revising that draft.
    public class Quote
    {
        public Guid Id { get; set; }

        // Links back to Student 2's component — the request this quote answers.
        public Guid ProjectRequestId { get; set; }

        // Links back to Student 1's component — the designer this quote is from.
        public Guid DesignerId { get; set; }

        public QuoteStatus Status { get; set; } = QuoteStatus.Draft;

        // True when this quote's items came from the Budget/Scope Agent and
        // haven't been edited by a human yet. Flips to false the moment a
        // designer saves a revision — keeps the audit trail honest.
        public bool IsAiGenerated { get; set; }

        // Short free-text summary the agent (or designer) attaches, e.g.
        // "Wall redesign, lighting upgrade, furniture — modern minimalist".
        public string? ScopeSummary { get; set; }

        // Decimal, never float/double — PRD section 15 data-integrity rule.
        public decimal TotalCost { get; set; }

        public string? Notes { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public List<QuoteItem> Items { get; set; } = new();

        // Null until the client accepts this quote and a contract is created from it.
        public Contract? Contract { get; set; }
    }
}
