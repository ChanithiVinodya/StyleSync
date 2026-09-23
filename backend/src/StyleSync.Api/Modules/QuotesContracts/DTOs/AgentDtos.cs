using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace StyleSync.Api.DTOs
{
    // What the React form (or Postman) sends to trigger a draft.
    public class DraftQuoteFromAgentDto
    {
        public Guid ProjectRequestId { get; set; }
        public Guid DesignerId { get; set; }
        public string RoomType { get; set; } = string.Empty;
        public double RoomSizeSqft { get; set; }
        public decimal BudgetMin { get; set; }
        public decimal BudgetMax { get; set; }
        public string StyleProfile { get; set; } = string.Empty;
        public double? StyleConfidence { get; set; }
        public string? Preferences { get; set; }
    }

    // Shaped to match the Python service's BudgetScopeRequest field names
    // exactly (snake_case), so JSON serialization lines up without any
    // custom naming policy.
    public class AgentBudgetScopeRequest
    {
        [JsonPropertyName("room_type")] public string RoomType { get; set; } = string.Empty;
        [JsonPropertyName("room_size_sqft")] public double RoomSizeSqft { get; set; }
        [JsonPropertyName("budget_min")] public decimal BudgetMin { get; set; }
        [JsonPropertyName("budget_max")] public decimal BudgetMax { get; set; }
        [JsonPropertyName("style_profile")] public string StyleProfile { get; set; } = string.Empty;
        [JsonPropertyName("style_confidence")] public double? StyleConfidence { get; set; }
        [JsonPropertyName("preferences")] public string? Preferences { get; set; }
    }

    public class AgentQuoteItemDraft
    {
        [JsonPropertyName("description")] public string Description { get; set; } = string.Empty;
        [JsonPropertyName("category")] public string Category { get; set; } = string.Empty;
        [JsonPropertyName("quantity")] public int Quantity { get; set; }
        [JsonPropertyName("unit_cost")] public decimal UnitCost { get; set; }
    }

    public class AgentBudgetScopeResponse
    {
        [JsonPropertyName("scope_summary")] public string ScopeSummary { get; set; } = string.Empty;
        [JsonPropertyName("items")] public List<AgentQuoteItemDraft> Items { get; set; } = new();
        [JsonPropertyName("notes")] public string Notes { get; set; } = string.Empty;
        [JsonPropertyName("estimated_total")] public decimal EstimatedTotal { get; set; }
        [JsonPropertyName("within_budget")] public bool WithinBudget { get; set; }
        [JsonPropertyName("source")] public string Source { get; set; } = string.Empty;
    }
}