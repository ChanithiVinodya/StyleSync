using System;
using System.Linq;
using System.Net.Http.Json;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Data;
using StyleSync.Api.DTOs;
using StyleSync.Api.Models;

namespace StyleSync.Api.Controllers
{
    [ApiController]
    [Route("api/quotes")]
    public class QuotesController : ControllerBase
    {
        private readonly AppDbContext _db;

        public QuotesController(AppDbContext db)
        {
            _db = db;
        }

        // GET /api/quotes?status=Submitted&designerId=...&search=modern&page=1&pageSize=20&sort=-createdAt
        [HttpGet]
        public async Task<ActionResult<PagedResult<QuoteResponseDto>>> GetAll(
            [FromQuery] QuoteStatus? status,
            [FromQuery] Guid? designerId,
            [FromQuery] Guid? projectRequestId,
            [FromQuery] string? search,
            [FromQuery] string sort = "-createdAt",
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            page = Math.Max(page, 1);
            pageSize = Math.Clamp(pageSize, 1, 100);

            var query = _db.Quotes.Include(q => q.Items).AsQueryable();

            if (status.HasValue) query = query.Where(q => q.Status == status.Value);
            if (designerId.HasValue) query = query.Where(q => q.DesignerId == designerId.Value);
            if (projectRequestId.HasValue) query = query.Where(q => q.ProjectRequestId == projectRequestId.Value);
            if (!string.IsNullOrWhiteSpace(search))
            {
                var term = search.Trim().ToLower();
                query = query.Where(q => q.ScopeSummary != null && q.ScopeSummary.ToLower().Contains(term));
            }

            query = sort.TrimStart('-') switch
            {
                "totalCost" => sort.StartsWith('-') ? query.OrderByDescending(q => q.TotalCost) : query.OrderBy(q => q.TotalCost),
                "status" => sort.StartsWith('-') ? query.OrderByDescending(q => q.Status) : query.OrderBy(q => q.Status),
                _ => sort.StartsWith('-') ? query.OrderByDescending(q => q.CreatedAt) : query.OrderBy(q => q.CreatedAt),
            };

            var totalCount = await query.CountAsync();
            var items = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();

            return Ok(new PagedResult<QuoteResponseDto>
            {
                Items = items.Select(ToResponseDto).ToList(),
                Page = page,
                PageSize = pageSize,
                TotalCount = totalCount
            });
        }

        // GET /api/quotes/{id}
        [HttpGet("{id:guid}")]
        public async Task<ActionResult<QuoteResponseDto>> GetById(Guid id)
        {
            var quote = await _db.Quotes.Include(q => q.Items).Include(q => q.Contract)
                .FirstOrDefaultAsync(q => q.Id == id);

            if (quote is null) return NotFound(new { message = $"Quote {id} was not found." });
            return Ok(ToResponseDto(quote));
        }

        // POST /api/quotes
        // Used by (a) the backend's AI-workflow endpoint, saving the Budget/Scope
        // Agent's draft as IsAiGenerated = true, or (b) a Designer creating one manually.
        [HttpPost]
        public async Task<ActionResult<QuoteResponseDto>> Create(CreateQuoteDto dto)
        {
            if (dto.Items.Count == 0)
                return BadRequest(new { message = "A quote needs at least one line item." });

            var quote = new Quote
            {
                Id = Guid.NewGuid(),
                ProjectRequestId = dto.ProjectRequestId,
                DesignerId = dto.DesignerId,
                ScopeSummary = dto.ScopeSummary,
                Notes = dto.Notes,
                IsAiGenerated = dto.IsAiGenerated,
                Status = QuoteStatus.Draft,
                Items = dto.Items.Select(i => new QuoteItem
                {
                    Id = Guid.NewGuid(),
                    Description = i.Description,
                    Category = i.Category,
                    Quantity = i.Quantity,
                    UnitCost = i.UnitCost,
                    LineTotal = i.Quantity * i.UnitCost
                }).ToList()
            };
            quote.TotalCost = quote.Items.Sum(i => i.LineTotal);

            _db.Quotes.Add(quote);
            await _db.SaveChangesAsync();

            return CreatedAtAction(nameof(GetById), new { id = quote.Id }, ToResponseDto(quote));
        }

        // POST /api/quotes/draft-from-agent
        // Step 7's bridge: calls the Python Budget/Scope Agent, then saves its
        // output as a normal Draft quote with IsAiGenerated = true — exactly what
        // a real LangGraph node would hand off to this component once the full
        // pipeline exists.
        [HttpPost("draft-from-agent")]
        public async Task<ActionResult<QuoteResponseDto>> DraftFromAgent(
            DraftQuoteFromAgentDto dto,
            [FromServices] IHttpClientFactory httpClientFactory)
        {
            var client = httpClientFactory.CreateClient("AiService");

            var agentRequest = new AgentBudgetScopeRequest
            {
                RoomType = dto.RoomType,
                RoomSizeSqft = dto.RoomSizeSqft,
                BudgetMin = dto.BudgetMin,
                BudgetMax = dto.BudgetMax,
                StyleProfile = dto.StyleProfile,
                StyleConfidence = dto.StyleConfidence,
                Preferences = dto.Preferences
            };

            HttpResponseMessage agentHttpResponse;
            try
            {
                agentHttpResponse = await client.PostAsJsonAsync("/agents/budget-scope", agentRequest);
            }
            catch (HttpRequestException)
            {
                return StatusCode(502, new { message = "Couldn't reach the AI service. Is it running on port 8001?" });
            }

            if (!agentHttpResponse.IsSuccessStatusCode)
                return StatusCode(502, new { message = $"AI service returned {(int)agentHttpResponse.StatusCode}." });

            var agentResult = await agentHttpResponse.Content.ReadFromJsonAsync<AgentBudgetScopeResponse>();
            if (agentResult is null || agentResult.Items.Count == 0)
                return StatusCode(502, new { message = "AI service returned an empty draft." });

            var quote = new Quote
            {
                Id = Guid.NewGuid(),
                ProjectRequestId = dto.ProjectRequestId,
                DesignerId = dto.DesignerId,
                Status = QuoteStatus.Draft,
                IsAiGenerated = true,
                ScopeSummary = agentResult.ScopeSummary,
                Notes = $"{agentResult.Notes} (agent source: {agentResult.Source})",
                Items = agentResult.Items.Select(i => new QuoteItem
                {
                    Id = Guid.NewGuid(),
                    Description = i.Description,
                    Category = Enum.TryParse<QuoteItemCategory>(i.Category, out var cat) ? cat : QuoteItemCategory.Other,
                    Quantity = i.Quantity,
                    UnitCost = i.UnitCost,
                    LineTotal = i.Quantity * i.UnitCost
                }).ToList()
            };
            quote.TotalCost = quote.Items.Sum(i => i.LineTotal);

            _db.Quotes.Add(quote);
            await _db.SaveChangesAsync();

            return CreatedAtAction(nameof(GetById), new { id = quote.Id }, ToResponseDto(quote));
        }

        // PUT /api/quotes/{id}
        // A Designer revising line items before client approval (PRD section 9, Update row).
        // Revising a quote always clears IsAiGenerated — once a human touches the
        // numbers it's no longer purely the agent's draft.
        [HttpPut("{id:guid}")]
        public async Task<ActionResult<QuoteResponseDto>> Update(Guid id, UpdateQuoteDto dto)
        {
            var quote = await _db.Quotes.Include(q => q.Items).FirstOrDefaultAsync(q => q.Id == id);
            if (quote is null) return NotFound(new { message = $"Quote {id} was not found." });

            if (quote.Status is QuoteStatus.Accepted or QuoteStatus.Rejected)
                return BadRequest(new { message = $"A {quote.Status} quote can no longer be edited." });

            if (dto.ScopeSummary is not null) quote.ScopeSummary = dto.ScopeSummary;
            if (dto.Notes is not null) quote.Notes = dto.Notes;

            if (dto.Items is not null)
            {
                if (dto.Items.Count == 0)
                    return BadRequest(new { message = "A quote needs at least one line item." });

                _db.QuoteItems.RemoveRange(quote.Items);
                quote.Items.Clear();

                foreach (var i in dto.Items)
                {
                    quote.Items.Add(new QuoteItem
                    {
                        Id = Guid.NewGuid(),
                        QuoteId = quote.Id,
                        Description = i.Description,
                        Category = i.Category,
                        Quantity = i.Quantity,
                        UnitCost = i.UnitCost,
                        LineTotal = i.Quantity * i.UnitCost
                    });
                }

                quote.TotalCost = quote.Items.Sum(i => i.LineTotal);
                quote.IsAiGenerated = false;
            }

            quote.UpdatedAt = DateTime.UtcNow;

            // Two overlapping saves for the same quote (e.g. a double-click, or a
            // retry after a dropped connection) can race here: the second save's
            // snapshot goes stale mid-flight once the first one commits. Catch it
            // and return a clean 409 instead of an unhandled 500.
            try
            {
                await _db.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                return Conflict(new { message = "This quote was just updated elsewhere. Please refresh and try again." });
            }

            return Ok(ToResponseDto(quote));
        }

        // PATCH /api/quotes/{id}/status
        // Drives Draft → Submitted → Client Review → Revision Requested → Accepted/Rejected.
        // Acceptance is handled by the dedicated /accept endpoint below, not this one,
        // because acceptance has a side effect (creating a Contract).
        [HttpPatch("{id:guid}/status")]
        public async Task<ActionResult<QuoteResponseDto>> UpdateStatus(Guid id, UpdateQuoteStatusDto dto)
        {
            if (dto.Status == QuoteStatus.Accepted)
                return BadRequest(new { message = "Use POST /api/quotes/{id}/accept to accept a quote — it also creates the contract." });

            var quote = await _db.Quotes.Include(q => q.Items).FirstOrDefaultAsync(q => q.Id == id);
            if (quote is null) return NotFound(new { message = $"Quote {id} was not found." });

            quote.Status = dto.Status;
            quote.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();

            return Ok(ToResponseDto(quote));
        }

        // POST /api/quotes/{id}/accept
        // The one place a Contract gets created. clientId is passed in because,
        // in the full modular monolith, it comes from Student 2's ProjectRequest —
        // this controller doesn't own that table, so it's supplied by the caller
        // (the shared "submit approval decision" endpoint from PRD section 8).
        [HttpPost("{id:guid}/accept")]
        public async Task<ActionResult<ContractResponseDto>> Accept(Guid id, [FromQuery] Guid clientId)
        {
            var quote = await _db.Quotes.Include(q => q.Items).Include(q => q.Contract)
                .FirstOrDefaultAsync(q => q.Id == id);

            if (quote is null) return NotFound(new { message = $"Quote {id} was not found." });
            if (quote.Contract is not null) return BadRequest(new { message = "This quote already has a contract." });
            if (quote.Status is QuoteStatus.Accepted or QuoteStatus.Rejected)
                return BadRequest(new { message = $"Quote is already {quote.Status}." });

            quote.Status = QuoteStatus.Accepted;
            quote.UpdatedAt = DateTime.UtcNow;

            var contract = new Contract
            {
                Id = Guid.NewGuid(),
                QuoteId = quote.Id,
                ProjectRequestId = quote.ProjectRequestId,
                DesignerId = quote.DesignerId,
                ClientId = clientId,
                TotalAmount = quote.TotalCost,
                Status = ContractStatus.Draft
            };

            _db.Contracts.Add(contract);
            await _db.SaveChangesAsync();

            return CreatedAtAction(
                nameof(ContractsController.GetById),
                "Contracts",
                new { id = contract.Id },
                ToContractResponseDto(contract));
        }

        // DELETE /api/quotes/{id}
        // Only a Draft (never-submitted) quote can be deleted (PRD section 9, Delete row).
        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> Delete(Guid id)
        {
            var quote = await _db.Quotes.FirstOrDefaultAsync(q => q.Id == id);
            if (quote is null) return NotFound(new { message = $"Quote {id} was not found." });

            if (quote.Status != QuoteStatus.Draft)
                return BadRequest(new { message = "Only a Draft quote can be deleted." });

            _db.Quotes.Remove(quote);
            await _db.SaveChangesAsync();
            return NoContent();
        }

        private static QuoteResponseDto ToResponseDto(Quote q) => new()
        {
            Id = q.Id,
            ProjectRequestId = q.ProjectRequestId,
            DesignerId = q.DesignerId,
            Status = q.Status,
            IsAiGenerated = q.IsAiGenerated,
            ScopeSummary = q.ScopeSummary,
            Notes = q.Notes,
            TotalCost = q.TotalCost,
            CreatedAt = q.CreatedAt,
            UpdatedAt = q.UpdatedAt,
            ContractId = q.Contract?.Id,
            Items = q.Items.Select(i => new QuoteItemResponseDto
            {
                Id = i.Id,
                Description = i.Description,
                Category = i.Category,
                Quantity = i.Quantity,
                UnitCost = i.UnitCost,
                LineTotal = i.LineTotal
            }).ToList()
        };

        private static ContractResponseDto ToContractResponseDto(Contract c) => new()
        {
            Id = c.Id,
            QuoteId = c.QuoteId,
            ProjectRequestId = c.ProjectRequestId,
            DesignerId = c.DesignerId,
            ClientId = c.ClientId,
            Status = c.Status,
            TotalAmount = c.TotalAmount,
            StartDate = c.StartDate,
            EndDate = c.EndDate,
            SignedAt = c.SignedAt,
            TermsSummary = c.TermsSummary,
            CreatedAt = c.CreatedAt,
            UpdatedAt = c.UpdatedAt
        };
    }
}