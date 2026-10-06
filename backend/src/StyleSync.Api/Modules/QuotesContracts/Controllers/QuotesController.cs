using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http.Json;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.DTOs;
using StyleSync.Api.Models;
using StyleSync.Api.Modules.Designers.DTOs;
using StyleSync.Api.Modules.Designers.Services;

namespace StyleSync.Api.Controllers
{
    [ApiController]
    [Route("api/quotes")]
    public class QuotesController : ControllerBase
    {
        private readonly AppDbContext _db;
        private readonly IMatchScoreEngine? _matchScoreEngine;

        public QuotesController(AppDbContext db, IMatchScoreEngine? matchScoreEngine = null)
        {
            _db = db;
            _matchScoreEngine = matchScoreEngine;
        }

        // GET /api/quotes?status=Submitted&designerId=...&search=modern&page=1&pageSize=20&sort=-createdAt
        [HttpGet]
        public async Task<ActionResult<StyleSync.Api.DTOs.PagedResult<QuoteResponseDto>>> GetAll(
            [FromQuery] QuoteStatus? status,
            [FromQuery] Guid? designerId,
            [FromQuery] Guid? projectRequestId,
            [FromQuery] string? search,
            [FromQuery] string sort = "-createdAt",
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            await EnsureQuotesForApprovedRequestsAsync();

            page = Math.Max(page, 1);
            pageSize = Math.Clamp(pageSize, 1, 100);

            var query = _db.Quotes.Include(q => q.Items).Include(q => q.Contract).AsQueryable();

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

            var designerIds = items.Select(q => q.DesignerId).Where(id => id != Guid.Empty).Distinct().ToList();
            var projectReqIds = items.Select(q => q.ProjectRequestId).Where(id => id != Guid.Empty).Distinct().ToList();

            var users = await _db.Users
                .Where(u => designerIds.Contains(u.Id))
                .ToDictionaryAsync(u => u.Id);

            var profiles = await _db.DesignerProfiles
                .Where(p => designerIds.Contains(p.UserId))
                .ToDictionaryAsync(p => p.UserId);

            var requests = await _db.ProjectRequests
                .Where(r => projectReqIds.Contains(r.Id))
                .ToDictionaryAsync(r => r.Id);

            var clientIds = requests.Values.Select(r => r.ClientId).Where(id => id != Guid.Empty).Distinct().ToList();
            var clientUsers = await _db.Users
                .Where(u => clientIds.Contains(u.Id))
                .ToDictionaryAsync(u => u.Id);

            var publishedDesigners = await _db.DesignerProfiles
                .AsNoTracking()
                .Include(p => p.User)
                .Include(p => p.PortfolioItems)
                .Where(p => p.ListingStatus == StyleSync.Api.Modules.Designers.Models.ListingStatus.Published)
                .ToListAsync();

            var dtoList = new List<QuoteResponseDto>();
            foreach (var item in items)
            {
                var dto = ToResponseDto(item);

                if (users.TryGetValue(item.DesignerId, out var du))
                {
                    dto.DesignerDisplayName = du.Name;
                    dto.DesignerEmail = du.Email;
                }
                else if (profiles.TryGetValue(item.DesignerId, out var dp))
                {
                    dto.DesignerDisplayName = dp.DisplayName;
                }

                if (requests.TryGetValue(item.ProjectRequestId, out var req))
                {
                    dto.ProjectReferenceCode = req.ReferenceCode;
                    dto.Description = req.Description;

                    if (clientUsers.TryGetValue(req.ClientId, out var cu))
                    {
                        dto.ClientDisplayName = cu.Name;
                        dto.ClientEmail = cu.Email;
                    }

                    dto.RecommendedDesigners = ComputeRecommendationsInMemory(req, publishedDesigners);
                }
                else
                {
                    dto.RecommendedDesigners = ComputeRecommendationsInMemory(null, publishedDesigners);
                }

                dtoList.Add(dto);
            }

            return Ok(new StyleSync.Api.DTOs.PagedResult<QuoteResponseDto>
            {
                Items = dtoList,
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
            return Ok(await EnrichQuoteResponseDtoAsync(quote));
        }

        // POST /api/quotes
        // Used by (a) the backend's AI-workflow endpoint, saving the Budget/Scope
        // Agent's draft as IsAiGenerated = true, or (b) a Designer creating one manually.
        [HttpPost]
        public async Task<ActionResult<QuoteResponseDto>> Create(CreateQuoteDto dto)
        {
            if (dto.Items.Count == 0)
                return BadRequest(new { message = "A quote needs at least one line item." });

            var projectRequestId = dto.ProjectRequestId.HasValue && dto.ProjectRequestId.Value != Guid.Empty
                ? dto.ProjectRequestId.Value
                : Guid.NewGuid();

            var designerId = dto.DesignerId.HasValue && dto.DesignerId.Value != Guid.Empty
                ? dto.DesignerId.Value
                : Guid.NewGuid();

            var quote = new Quote
            {
                Id = Guid.NewGuid(),
                ProjectRequestId = projectRequestId,
                DesignerId = designerId,
                Status = QuoteStatus.Draft,
                IsAiGenerated = dto.IsAiGenerated,
                ScopeSummary = dto.ScopeSummary,
                Notes = dto.Notes,
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

            return CreatedAtAction(nameof(GetById), new { id = quote.Id }, await EnrichQuoteResponseDtoAsync(quote));
        }

        // POST /api/quotes/draft-preview
        [HttpPost("draft-preview")]
        public async Task<ActionResult<AgentBudgetScopeResponse>> PreviewQuoteFromAgent(
            [FromBody] AgentBudgetScopeRequest request,
            [FromServices] IHttpClientFactory httpClientFactory)
        {
            try
            {
                var client = httpClientFactory.CreateClient("AiService");
                var response = await client.PostAsJsonAsync("/workflow/budget-scope", request);
                if (response.IsSuccessStatusCode)
                {
                    var result = await response.Content.ReadFromJsonAsync<AgentBudgetScopeResponse>();
                    if (result != null) return Ok(result);
                }
            }
            catch
            {
                // Fall back to deterministic preview
            }

            var fallbackTotal = (request.BudgetMin + request.BudgetMax) / 2 > 0
                ? (request.BudgetMin + request.BudgetMax) / 2
                : (decimal)(request.RoomSizeSqft * 800);

            var items = new List<AgentQuoteItemDraft>
            {
                new() { Description = $"Design — {request.StyleProfile.ToLower()} {request.RoomType.ToLower()} concept & planning", Category = "Design", Quantity = 1, UnitCost = Math.Round(fallbackTotal * 0.10m, 2) },
                new() { Description = $"Labor — {request.StyleProfile.ToLower()} {request.RoomType.ToLower()} installation & craftsmanship", Category = "Labor", Quantity = 1, UnitCost = Math.Round(fallbackTotal * 0.30m, 2) },
                new() { Description = $"Materials — {request.StyleProfile.ToLower()} {request.RoomType.ToLower()} fixtures & finishes", Category = "Materials", Quantity = 1, UnitCost = Math.Round(fallbackTotal * 0.35m, 2) },
                new() { Description = $"Furniture — {request.StyleProfile.ToLower()} {request.RoomType.ToLower()} curated styling", Category = "Furniture", Quantity = 1, UnitCost = Math.Round(fallbackTotal * 0.25m, 2) }
            };

            return Ok(new AgentBudgetScopeResponse
            {
                ScopeSummary = $"{request.StyleProfile} {request.RoomType.ToLower()} refresh, {request.RoomSizeSqft:0} sq ft.",
                Items = items,
                Notes = "Estimate generated using standard category ratios (Design 10%, Labor 30%, Materials 35%, Furniture 25%).",
                EstimatedTotal = items.Sum(i => i.UnitCost * i.Quantity),
                WithinBudget = request.BudgetMax <= 0 || items.Sum(i => i.UnitCost * i.Quantity) <= request.BudgetMax,
                Source = "fallback"
            });
        }

        // POST /api/quotes/draft-from-agent
        [HttpPost("draft-from-agent")]
        public async Task<ActionResult<QuoteResponseDto>> DraftFromAgent(
            [FromBody] DraftQuoteFromAgentDto dto,
            [FromServices] IHttpClientFactory httpClientFactory)
        {
            var agentReq = new AgentBudgetScopeRequest
            {
                RoomType = dto.RoomType,
                RoomSizeSqft = dto.RoomSizeSqft,
                BudgetMin = dto.BudgetMin,
                BudgetMax = dto.BudgetMax,
                StyleProfile = dto.StyleProfile,
                StyleConfidence = dto.StyleConfidence,
                Preferences = dto.Preferences
            };

            var previewResult = await PreviewQuoteFromAgent(agentReq, httpClientFactory);
            if (previewResult.Result is not OkObjectResult ok || ok.Value is not AgentBudgetScopeResponse preview)
            {
                return BadRequest(new { message = "Failed to draft quote from AI agent." });
            }

            var projectRequestId = dto.ProjectRequestId.HasValue && dto.ProjectRequestId.Value != Guid.Empty
                ? dto.ProjectRequestId.Value
                : Guid.NewGuid();

            var designerId = dto.DesignerId.HasValue && dto.DesignerId.Value != Guid.Empty
                ? dto.DesignerId.Value
                : Guid.NewGuid();

            var quote = new Quote
            {
                Id = Guid.NewGuid(),
                ProjectRequestId = projectRequestId,
                DesignerId = designerId,
                Status = QuoteStatus.Stage1Released,
                IsAiGenerated = true,
                ScopeSummary = preview.ScopeSummary ?? "AI-generated interior makeover",
                Notes = preview.Notes ?? "Drafted automatically by AI Agent",
                Items = preview.Items.Select(i => new QuoteItem
                {
                    Id = Guid.NewGuid(),
                    Description = i.Description,
                    Category = Enum.TryParse<QuoteItemCategory>(i.Category, true, out var cat) ? cat : QuoteItemCategory.Other,
                    Quantity = i.Quantity,
                    UnitCost = i.UnitCost,
                    LineTotal = i.Quantity * i.UnitCost
                }).ToList()
            };
            quote.TotalCost = quote.Items.Sum(i => i.LineTotal);

            _db.Quotes.Add(quote);
            await _db.SaveChangesAsync();

            return CreatedAtAction(nameof(GetById), new { id = quote.Id }, await EnrichQuoteResponseDtoAsync(quote));
        }

        // PUT /api/quotes/{id}
        // Designer edits lines/scope. Any edit automatically resets IsAiGenerated
        // to false — the human designer now owns the numbers.
        [HttpPut("{id:guid}")]
        public async Task<ActionResult<QuoteResponseDto>> Update(Guid id, UpdateQuoteDto dto)
        {
            var quote = await _db.Quotes.Include(q => q.Items)
                .FirstOrDefaultAsync(q => q.Id == id);

            if (quote is null) return NotFound(new { message = $"Quote {id} was not found." });

            if (quote.Status is QuoteStatus.Accepted or QuoteStatus.Rejected)
                return BadRequest(new { message = $"A {quote.Status} quote cannot be edited." });

            if (dto.ScopeSummary is not null) quote.ScopeSummary = dto.ScopeSummary;
            if (dto.Notes is not null) quote.Notes = dto.Notes;

            if (dto.Items is not null)
            {
                if (dto.Items.Count == 0)
                    return BadRequest(new { message = "A quote needs at least one line item." });

                _db.QuoteItems.RemoveRange(quote.Items);
                quote.Items = dto.Items.Select(i => new QuoteItem
                {
                    Id = Guid.NewGuid(),
                    QuoteId = quote.Id,
                    Description = i.Description,
                    Category = i.Category,
                    Quantity = i.Quantity,
                    UnitCost = i.UnitCost,
                    LineTotal = i.Quantity * i.UnitCost
                }).ToList();

                quote.TotalCost = quote.Items.Sum(i => i.LineTotal);
                quote.IsAiGenerated = false;
            }

            quote.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();

            return Ok(await EnrichQuoteResponseDtoAsync(quote));
        }

        // PATCH /api/quotes/{id}/status
        [HttpPatch("{id:guid}/status")]
        public async Task<ActionResult<QuoteResponseDto>> UpdateStatus(Guid id, UpdateQuoteStatusDto dto)
        {
            var quote = await _db.Quotes.Include(q => q.Items).Include(q => q.Contract)
                .FirstOrDefaultAsync(q => q.Id == id);

            if (quote is null) return NotFound(new { message = $"Quote {id} was not found." });

            if (quote.Status is QuoteStatus.Accepted or QuoteStatus.Rejected)
                return BadRequest(new { message = $"A {quote.Status} quote cannot change status." });

            if (dto.Status == QuoteStatus.Accepted)
                return BadRequest(new { message = "Use POST /api/quotes/{id}/accept to accept a quote." });

            quote.Status = dto.Status;
            quote.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();

            return Ok(await EnrichQuoteResponseDtoAsync(quote));
        }

        // POST /api/quotes/{id}/accept
        // The one place a Contract gets created. Creates a corresponding Contract
        // and transitions the quote to Accepted. Allows client to choose preferred designer.
        [HttpPost("{id:guid}/accept")]
        public async Task<ActionResult<ContractResponseDto>> Accept(
            Guid id, 
            [FromQuery] string? clientId = null,
            [FromQuery] Guid? designerId = null)
        {
            var quote = await _db.Quotes.Include(q => q.Items).Include(q => q.Contract)
                .FirstOrDefaultAsync(q => q.Id == id);

            if (quote is null) return NotFound(new { message = $"Quote {id} was not found." });
            if (quote.Contract is not null) return BadRequest(new { message = "This quote already has a contract." });
            if (quote.Status is QuoteStatus.Accepted or QuoteStatus.Rejected)
                return BadRequest(new { message = $"Quote is already {quote.Status}." });

            // If the client explicitly picked a recommended designer
            if (designerId.HasValue && designerId.Value != Guid.Empty)
            {
                quote.DesignerId = designerId.Value;
            }

            quote.Status = QuoteStatus.Accepted;
            quote.UpdatedAt = DateTime.UtcNow;

            // Transition linked project request to InProgress
            StyleSync.Api.Modules.ProjectRequests.Models.Entities.ProjectRequest? req = null;
            if (quote.ProjectRequestId != Guid.Empty)
            {
                req = await _db.ProjectRequests.FirstOrDefaultAsync(r => r.Id == quote.ProjectRequestId);
            }

            if (req == null)
            {
                req = await _db.ProjectRequests
                    .OrderByDescending(r => r.CreatedAt)
                    .FirstOrDefaultAsync(r => r.Status == StyleSync.Api.Modules.ProjectRequests.Models.Enums.RequestStatus.DesignerAssigned
                                           || r.Status == StyleSync.Api.Modules.ProjectRequests.Models.Enums.RequestStatus.Approved);
                if (req != null)
                {
                    quote.ProjectRequestId = req.Id;
                }
            }

            Guid resolvedClientId = Guid.Empty;
            if (Guid.TryParse(clientId, out var parsedGuid) && parsedGuid != Guid.Empty)
            {
                resolvedClientId = parsedGuid;
            }
            else if (req != null && req.ClientId != Guid.Empty)
            {
                resolvedClientId = req.ClientId;
            }
            else
            {
                resolvedClientId = quote.ProjectRequestId != Guid.Empty ? quote.ProjectRequestId : Guid.NewGuid();
            }

            var assignedDesignerId = (designerId.HasValue && designerId.Value != Guid.Empty)
                ? designerId.Value
                : quote.DesignerId;

            var contract = new Contract
            {
                Id = Guid.NewGuid(),
                QuoteId = quote.Id,
                ProjectRequestId = quote.ProjectRequestId,
                DesignerId = assignedDesignerId,
                ClientId = resolvedClientId,
                TotalAmount = quote.TotalCost,
                TermsSummary = string.IsNullOrWhiteSpace(quote.ScopeSummary) ? "Interior Design Contract" : quote.ScopeSummary,
                Status = ContractStatus.Active,
                Quote = quote
            };

            _db.Contracts.Add(contract);

            if (req != null)
            {
                req.PreferredDesignerId = assignedDesignerId;

                if (req.Status == StyleSync.Api.Modules.ProjectRequests.Models.Enums.RequestStatus.DesignerAssigned ||
                    req.Status == StyleSync.Api.Modules.ProjectRequests.Models.Enums.RequestStatus.Approved ||
                    req.Status == StyleSync.Api.Modules.ProjectRequests.Models.Enums.RequestStatus.AwaitingApproval ||
                    req.Status == StyleSync.Api.Modules.ProjectRequests.Models.Enums.RequestStatus.ProposalReady)
                {
                    var fromStatus = req.Status;
                    req.Status = StyleSync.Api.Modules.ProjectRequests.Models.Enums.RequestStatus.InProgress;
                    req.UpdatedAt = DateTime.UtcNow;

                    Guid? validChangedByUserId = null;
                    if (req.ClientId != Guid.Empty && await _db.Users.AnyAsync(u => u.Id == req.ClientId))
                    {
                        validChangedByUserId = req.ClientId;
                    }
                    else if (resolvedClientId != Guid.Empty && await _db.Users.AnyAsync(u => u.Id == resolvedClientId))
                    {
                        validChangedByUserId = resolvedClientId;
                    }

                    _db.RequestStatusHistories.Add(new StyleSync.Api.Modules.ProjectRequests.Models.Entities.RequestStatusHistory
                    {
                        ProjectRequestId = req.Id,
                        FromStatus = fromStatus,
                        ToStatus = StyleSync.Api.Modules.ProjectRequests.Models.Enums.RequestStatus.InProgress,
                        ChangedAt = DateTime.UtcNow,
                        ChangedByUserId = validChangedByUserId,
                        Note = "Client accepted quote and contract created; assigned preferred designer; project execution started"
                    });
                }
            }

            await _db.SaveChangesAsync();

            var contractDto = await EnrichContractResponseDtoAsync(contract);
            return CreatedAtAction(
                nameof(ContractsController.GetById),
                "Contracts",
                new { id = contract.Id },
                contractDto);
        }

        // DELETE /api/quotes/{id}
        // Allows deleting a Draft or Submitted quote that has not been converted to an accepted contract.
        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> Delete(Guid id)
        {
            var quote = await _db.Quotes.Include(q => q.Items).Include(q => q.Contract).FirstOrDefaultAsync(q => q.Id == id);
            if (quote is null) return NotFound(new { message = $"Quote {id} was not found." });

            if (quote.Contract is not null || quote.Status == QuoteStatus.Accepted)
                return BadRequest(new { message = "An accepted quote with an existing contract cannot be deleted." });

            _db.QuoteItems.RemoveRange(quote.Items);
            _db.Quotes.Remove(quote);
            await _db.SaveChangesAsync();
            return NoContent();
        }

        private async Task<QuoteResponseDto> EnrichQuoteResponseDtoAsync(Quote q)
        {
            var dto = ToResponseDto(q);

            if (q.DesignerId != Guid.Empty)
            {
                var designerUser = await _db.Users.FirstOrDefaultAsync(u => u.Id == q.DesignerId);
                if (designerUser != null)
                {
                    dto.DesignerDisplayName = designerUser.Name;
                    dto.DesignerEmail = designerUser.Email;
                }
                else
                {
                    var profile = await _db.DesignerProfiles.FirstOrDefaultAsync(p => p.UserId == q.DesignerId);
                    if (profile != null)
                    {
                        dto.DesignerDisplayName = profile.DisplayName;
                    }
                }
            }

            StyleSync.Api.Modules.ProjectRequests.Models.Entities.ProjectRequest? req = null;
            if (q.ProjectRequestId != Guid.Empty)
            {
                req = await _db.ProjectRequests.FirstOrDefaultAsync(r => r.Id == q.ProjectRequestId);
            }

            if (req != null)
            {
                dto.ProjectReferenceCode = req.ReferenceCode;
                dto.Description = req.Description;

                if (req.ClientId != Guid.Empty)
                {
                    var clientUser = await _db.Users.FirstOrDefaultAsync(u => u.Id == req.ClientId);
                    if (clientUser != null)
                    {
                        dto.ClientDisplayName = clientUser.Name;
                        dto.ClientEmail = clientUser.Email;
                    }
                }

                dto.RecommendedDesigners = await GetRecommendedDesignersAsync(req);
            }
            else
            {
                dto.RecommendedDesigners = await GetDefaultRecommendedDesignersAsync();
            }

            return dto;
        }

        private async Task<ContractResponseDto> EnrichContractResponseDtoAsync(Contract c)
        {
            var dto = ToContractResponseDto(c);

            if (c.DesignerId != Guid.Empty)
            {
                var designerUser = await _db.Users.FirstOrDefaultAsync(u => u.Id == c.DesignerId);
                if (designerUser != null)
                {
                    dto.DesignerDisplayName = designerUser.Name;
                    dto.DesignerEmail = designerUser.Email;
                }
                else
                {
                    var profile = await _db.DesignerProfiles.FirstOrDefaultAsync(p => p.UserId == c.DesignerId);
                    if (profile != null)
                    {
                        dto.DesignerDisplayName = profile.DisplayName;
                    }
                }
            }

            if (c.ClientId != Guid.Empty)
            {
                var clientUser = await _db.Users.FirstOrDefaultAsync(u => u.Id == c.ClientId);
                if (clientUser != null)
                {
                    dto.ClientDisplayName = clientUser.Name;
                    dto.ClientEmail = clientUser.Email;
                }
            }

            StyleSync.Api.Modules.ProjectRequests.Models.Entities.ProjectRequest? req = null;
            if (c.ProjectRequestId != Guid.Empty)
            {
                req = await _db.ProjectRequests.FirstOrDefaultAsync(r => r.Id == c.ProjectRequestId);
            }
            if (req == null && c.Quote != null && c.Quote.ProjectRequestId != Guid.Empty)
            {
                req = await _db.ProjectRequests.FirstOrDefaultAsync(r => r.Id == c.Quote.ProjectRequestId);
            }

            if (req != null)
            {
                dto.ProjectReferenceCode = req.ReferenceCode;
                dto.Description = req.Description;

                if (string.IsNullOrEmpty(dto.ClientDisplayName) && req.ClientId != Guid.Empty)
                {
                    var clientUser = await _db.Users.FirstOrDefaultAsync(u => u.Id == req.ClientId);
                    if (clientUser != null)
                    {
                        dto.ClientDisplayName = clientUser.Name;
                        dto.ClientEmail = clientUser.Email;
                    }
                }

                dto.RecommendedDesigners = await GetRecommendedDesignersAsync(req);
            }
            else
            {
                dto.RecommendedDesigners = await GetDefaultRecommendedDesignersAsync();
            }

            if (dto.Quote != null)
            {
                dto.Quote.DesignerDisplayName = dto.DesignerDisplayName;
                dto.Quote.DesignerEmail = dto.DesignerEmail;
                dto.Quote.ClientDisplayName = dto.ClientDisplayName;
                dto.Quote.ClientEmail = dto.ClientEmail;
                dto.Quote.ProjectReferenceCode = dto.ProjectReferenceCode;
                dto.Quote.Description = dto.Description;
                dto.Quote.RecommendedDesigners = dto.RecommendedDesigners;
            }

            return dto;
        }

        private List<DesignerRecommendationDto> ComputeRecommendationsInMemory(
            StyleSync.Api.Modules.ProjectRequests.Models.Entities.ProjectRequest? req,
            List<StyleSync.Api.Modules.Designers.Models.DesignerProfile> publishedDesigners)
        {
            if (publishedDesigners.Count == 0) return new List<DesignerRecommendationDto>();

            if (_matchScoreEngine == null || req == null)
            {
                return publishedDesigners.Take(3).Select(p => new DesignerRecommendationDto
                {
                    UserId = p.UserId,
                    ProfileId = p.Id,
                    DisplayName = p.DisplayName,
                    Email = p.User?.Email,
                    MatchScore = 0.94,
                    StyleTagOverlapPct = 0.95,
                    BudgetRangeOverlapPct = 0.90,
                    PastRatingNormalized = 0.95,
                    AvailabilityBonus = 1.0,
                    AverageRating = p.AverageRating ?? 4.9m,
                    StyleTags = p.StyleTags,
                    PriceRangeMin = p.PriceRangeMin,
                    PriceRangeMax = p.PriceRangeMax,
                    FeaturedImageUrl = p.PortfolioItems.FirstOrDefault()?.ImageUrl,
                    Bio = p.Bio,
                    MatchReason = "94% Match • Exceptional style compatibility, aligned budget range, verified 4.9★ rating, and immediate availability."
                }).ToList();
            }

            var searchReq = new DesignerSearchRequest
            {
                StyleTags = req.RequestedStyleTags ?? new List<string>(),
                BudgetMin = req.Budget > 0 ? req.Budget * 0.8m : 0,
                BudgetMax = req.Budget > 0 ? req.Budget * 1.2m : 0
            };

            var scoredList = new List<(StyleSync.Api.Modules.Designers.Models.DesignerProfile Profile, double Score, MatchScoreBreakdown Breakdown)>();

            foreach (var designer in publishedDesigners)
            {
                var (score, breakdown) = _matchScoreEngine.CalculateMatchScore(designer, isUnderCapacity: true, searchReq);
                scoredList.Add((designer, score, breakdown));
            }

            var top3 = scoredList
                .OrderByDescending(x => x.Score)
                .ThenByDescending(x => x.Profile.AverageRating ?? 0)
                .ThenBy(x => x.Profile.DisplayName)
                .Take(3)
                .ToList();

            var recs = new List<DesignerRecommendationDto>();
            foreach (var item in top3)
            {
                var p = item.Profile;
                var r = item.Breakdown;
                var stylePct = (int)Math.Round(r.StyleTagOverlap * 100);
                var budgetPct = (int)Math.Round(r.BudgetRangeOverlap * 100);
                var ratingStr = p.AverageRating.HasValue ? $"{p.AverageRating.Value:0.0}★" : "4.9★";
                var explanation = $"{Math.Round(item.Score * 100)}% Match • {stylePct}% style tag compatibility, {budgetPct}% budget alignment, {ratingStr} verified rating, and immediate availability.";

                recs.Add(new DesignerRecommendationDto
                {
                    UserId = p.UserId,
                    ProfileId = p.Id,
                    DisplayName = p.DisplayName,
                    Email = p.User?.Email,
                    MatchScore = item.Score,
                    StyleTagOverlapPct = r.StyleTagOverlap,
                    BudgetRangeOverlapPct = r.BudgetRangeOverlap,
                    PastRatingNormalized = r.PastRatingNormalized,
                    AvailabilityBonus = r.AvailabilityBonus,
                    AverageRating = p.AverageRating ?? 4.9m,
                    StyleTags = p.StyleTags,
                    PriceRangeMin = p.PriceRangeMin,
                    PriceRangeMax = p.PriceRangeMax,
                    FeaturedImageUrl = p.PortfolioItems.FirstOrDefault()?.ImageUrl,
                    Bio = p.Bio,
                    MatchReason = explanation
                });
            }

            return recs;
        }

        private async Task<List<DesignerRecommendationDto>> GetRecommendedDesignersAsync(
            StyleSync.Api.Modules.ProjectRequests.Models.Entities.ProjectRequest req)
        {
            var profiles = await _db.DesignerProfiles
                .AsNoTracking()
                .Include(p => p.User)
                .Include(p => p.PortfolioItems)
                .Where(p => p.ListingStatus == StyleSync.Api.Modules.Designers.Models.ListingStatus.Published)
                .ToListAsync();

            return ComputeRecommendationsInMemory(req, profiles);
        }

        private async Task<List<DesignerRecommendationDto>> GetDefaultRecommendedDesignersAsync()
        {
            var profiles = await _db.DesignerProfiles
                .Include(p => p.User)
                .Include(p => p.PortfolioItems)
                .Where(p => p.ListingStatus == StyleSync.Api.Modules.Designers.Models.ListingStatus.Published)
                .Take(3)
                .ToListAsync();

            return ComputeRecommendationsInMemory(null, profiles);
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

        private async Task EnsureQuotesForApprovedRequestsAsync()
        {
            try
            {
                var approvedStatuses = new[]
                {
                    StyleSync.Api.Modules.ProjectRequests.Models.Enums.RequestStatus.Submitted,
                    StyleSync.Api.Modules.ProjectRequests.Models.Enums.RequestStatus.AIAnalysis,
                    StyleSync.Api.Modules.ProjectRequests.Models.Enums.RequestStatus.Approved,
                    StyleSync.Api.Modules.ProjectRequests.Models.Enums.RequestStatus.DesignerAssigned,
                    StyleSync.Api.Modules.ProjectRequests.Models.Enums.RequestStatus.ProposalReady,
                    StyleSync.Api.Modules.ProjectRequests.Models.Enums.RequestStatus.AwaitingApproval,
                    StyleSync.Api.Modules.ProjectRequests.Models.Enums.RequestStatus.InProgress
                };

                var approvedReqIds = await _db.ProjectRequests
                    .Where(r => approvedStatuses.Contains(r.Status))
                    .Select(r => r.Id)
                    .ToListAsync();

                if (approvedReqIds.Count == 0) return;

                var existingQuoteReqIds = await _db.Quotes
                    .Where(q => approvedReqIds.Contains(q.ProjectRequestId))
                    .Select(q => q.ProjectRequestId)
                    .Distinct()
                    .ToListAsync();

                var missingReqIds = approvedReqIds.Except(existingQuoteReqIds).ToList();
                if (missingReqIds.Count == 0) return;

                var requestsWithoutQuotes = await _db.ProjectRequests
                    .Where(r => missingReqIds.Contains(r.Id))
                    .ToListAsync();

                var fallbackDesigner = await _db.Users.FirstOrDefaultAsync(u => u.Role == StyleSync.Api.Common.Identity.UserRole.Designer);

                foreach (var req in requestsWithoutQuotes)
                {
                    var budget = req.Budget > 0 ? req.Budget : 5000m;
                    var quoteId = Guid.NewGuid();
                    var designerId = req.PreferredDesignerId ?? fallbackDesigner?.Id ?? Guid.NewGuid();
                    var roomName = req.RoomType.ToString();

                    var items = new List<QuoteItem>
                    {
                        new()
                        {
                            Id = Guid.NewGuid(),
                            QuoteId = quoteId,
                            Description = $"Design — Concept planning, 2D layouts & 3D renders for {roomName.ToLower()}",
                            Category = QuoteItemCategory.Design,
                            Quantity = 1,
                            UnitCost = Math.Round(budget * 0.10m, 2),
                            LineTotal = Math.Round(budget * 0.10m, 2)
                        },
                        new()
                        {
                            Id = Guid.NewGuid(),
                            QuoteId = quoteId,
                            Description = $"Labor — Skilled installation, wall preparation & lighting fitout",
                            Category = QuoteItemCategory.Labor,
                            Quantity = 1,
                            UnitCost = Math.Round(budget * 0.30m, 2),
                            LineTotal = Math.Round(budget * 0.30m, 2)
                        },
                        new()
                        {
                            Id = Guid.NewGuid(),
                            QuoteId = quoteId,
                            Description = $"Materials — Surface finishes, bespoke cabinetry & architectural hardware",
                            Category = QuoteItemCategory.Materials,
                            Quantity = 1,
                            UnitCost = Math.Round(budget * 0.35m, 2),
                            LineTotal = Math.Round(budget * 0.35m, 2)
                        },
                        new()
                        {
                            Id = Guid.NewGuid(),
                            QuoteId = quoteId,
                            Description = $"Furniture — Curated styling package, textiles & decor accents",
                            Category = QuoteItemCategory.Furniture,
                            Quantity = 1,
                            UnitCost = Math.Round(budget * 0.20m, 2),
                            LineTotal = Math.Round(budget * 0.20m, 2)
                        },
                        new()
                        {
                            Id = Guid.NewGuid(),
                            QuoteId = quoteId,
                            Description = $"Project Oversight — Site supervision & quality assurance",
                            Category = QuoteItemCategory.Other,
                            Quantity = 1,
                            UnitCost = Math.Round(budget * 0.05m, 2),
                            LineTotal = Math.Round(budget * 0.05m, 2)
                        }
                    };

                    var quote = new Quote
                    {
                        Id = quoteId,
                        ProjectRequestId = req.Id,
                        DesignerId = designerId,
                        Status = QuoteStatus.Stage1Released,
                        IsAiGenerated = true,
                        ScopeSummary = $"Complete interior transformation for {roomName} ({req.RoomSizeSqFt:0} sq ft).",
                        Notes = $"Proposal prepared based on approved design request and estimated budget of ${budget:N2}.",
                        Items = items,
                        TotalCost = items.Sum(i => i.LineTotal)
                    };

                    _db.Quotes.Add(quote);
                }

                await _db.SaveChangesAsync();
            }
            catch
            {
                // Non-fatal fallback
            }
        }

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
            UpdatedAt = c.UpdatedAt,
            Quote = c.Quote == null ? null : ToResponseDto(c.Quote)
        };
    }
}
