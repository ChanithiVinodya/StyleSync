using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using StyleSync.Api.DTOs;

namespace StyleSync.Api.Integrations
{
    public interface IScopeSource
    {
        Task<AgentBudgetScopeResponse> FetchDraftScopeAsync(AgentBudgetScopeRequest request);
    }

    public class AiScopeSourceAdapter : IScopeSource
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly string _integrationMode;

        public AiScopeSourceAdapter(IHttpClientFactory httpClientFactory, IConfiguration config)
        {
            _httpClientFactory = httpClientFactory;
            _integrationMode = config["INTEGRATION_MODE"] ?? "stub";
        }

        public async Task<AgentBudgetScopeResponse> FetchDraftScopeAsync(AgentBudgetScopeRequest request)
        {
            // Boundary Schema Validation: Ensure input shape is valid before reaching external component
            if (string.IsNullOrWhiteSpace(request.RoomType))
                throw new ArgumentException("Room type is required for AI scope drafting.");
            if (request.RoomSizeSqft <= 0)
                throw new ArgumentException("Room size (sq ft) must be greater than zero.");

            if (_integrationMode.Equals("real", StringComparison.OrdinalIgnoreCase))
            {
                var client = _httpClientFactory.CreateClient("AiService");
                HttpResponseMessage response;
                try
                {
                    response = await client.PostAsJsonAsync("/agents/budget-scope", request);
                }
                catch (HttpRequestException ex)
                {
                    throw new InvalidOperationException($"Could not connect to AI Service at {client.BaseAddress}: {ex.Message}", ex);
                }

                if (!response.IsSuccessStatusCode)
                {
                    var error = await response.Content.ReadAsStringAsync();
                    throw new InvalidOperationException($"AI Service returned {(int)response.StatusCode}: {error}");
                }

                var result = await response.Content.ReadFromJsonAsync<AgentBudgetScopeResponse>();
                if (result == null || result.Items.Count == 0)
                {
                    throw new InvalidOperationException("AI Service returned an empty or malformed draft scope.");
                }

                return result;
            }

            // Stub Mode: Deterministic mathematical fallback mirroring Budget/Scope Agent specification
            decimal targetBudget = (request.BudgetMin + request.BudgetMax) / 2 > 0
                ? (request.BudgetMin + request.BudgetMax) / 2
                : (decimal)request.RoomSizeSqft * 800m;

            var split = new (string Category, decimal Pct, string Desc)[]
            {
                ("Design", 0.10m, $"Design — {request.StyleProfile.ToLower()} {request.RoomType.ToLower()} concept & planning"),
                ("Labor", 0.30m, $"Labor — {request.StyleProfile.ToLower()} {request.RoomType.ToLower()} installation & craftsmanship"),
                ("Materials", 0.35m, $"Materials — {request.StyleProfile.ToLower()} {request.RoomType.ToLower()} fixtures & finishes"),
                ("Furniture", 0.25m, $"Furniture — {request.StyleProfile.ToLower()} {request.RoomType.ToLower()} curated styling"),
            };

            var items = new List<AgentQuoteItemDraft>();
            foreach (var s in split)
            {
                decimal unitCost = Math.Round((targetBudget * s.Pct) / 100m, 0) * 100m;
                items.Add(new AgentQuoteItemDraft
                {
                    Description = s.Desc,
                    Category = s.Category,
                    Quantity = 1,
                    UnitCost = unitCost
                });
            }

            decimal total = 0;
            foreach (var item in items) total += item.UnitCost * item.Quantity;

            return new AgentBudgetScopeResponse
            {
                ScopeSummary = $"{request.StyleProfile} {request.RoomType.ToLower()} refresh, {request.RoomSizeSqft:0} sq ft.",
                Items = items,
                Notes = "Deterministic estimate — generated via IScopeSource stub adapter with category ratio allocation.",
                EstimatedTotal = total,
                WithinBudget = request.BudgetMax > 0 ? (total >= request.BudgetMin && total <= request.BudgetMax) : true,
                Source = "stub"
            };
        }
    }
}
