using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Data;
using StyleSync.Api.DTOs;
using StyleSync.Api.Integrations;
using StyleSync.Api.Models;
using StyleSync.Api.Services;

namespace StyleSync.Api.Controllers
{
    [ApiController]
    [Route("api/quotes")]
    public class QuotesController : ControllerBase
    {
        private readonly AppDbContext _db;
        private readonly IQuotationEngine _quotationEngine;
        private readonly IBudgetGuard _budgetGuard;
        private readonly IScopeSource _scopeSource;
        private readonly IProjectRequestProvider _requestProvider;
        private readonly ICurrentUserContext _userContext;
        private readonly IApprovalGateResumer _gateResumer;
        private readonly IQuoteExportService _exportService;

        public QuotesController(
            AppDbContext db,
            IQuotationEngine quotationEngine,
            IBudgetGuard budgetGuard,
            IScopeSource scopeSource,
            IProjectRequestProvider requestProvider,
            ICurrentUserContext userContext,
            IApprovalGateResumer gateResumer,
            IQuoteExportService exportService)
        {
            _db = db;
            _quotationEngine = quotationEngine;
            _budgetGuard = budgetGuard;
            _scopeSource = scopeSource;
            _requestProvider = requestProvider;
            _userContext = userContext;
            _gateResumer = gateResumer;
            _exportService = exportService;
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

            var query = _db.Quotes
                .Include(q => q.Versions)
                    .ThenInclude(v => v.Items)
                .Include(q => q.Items)
                .Include(q => q.Contract)
                .AsQueryable();

            // Role Scoping: Clients should only see Released / Accepted / Rejected quotes unless they are admin/designer
            if (_userContext.IsInRole("Client"))
            {
                query = query.Where(q => q.Status == QuoteStatus.Stage1Released 
                                      || q.Status == QuoteStatus.Stage2Approved 
                                      || q.Status == QuoteStatus.Stage2ChangesRequested 
                                      || q.Status == QuoteStatus.Stage2Rejected
                                      || q.Status == QuoteStatus.ClientReview
                                      || q.Status == QuoteStatus.Accepted
                                      || q.Status == QuoteStatus.Rejected);
            }
            else if (_userContext.IsInRole("Designer") && _userContext.UserId.HasValue)
            {
                var designerUserGuid = _userContext.UserId.Value;
                query = query.Where(q => q.DesignerId == designerUserGuid || designerId == null || q.DesignerId == designerId);
            }

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
            var quote = await _db.Quotes
                .Include(q => q.Versions)
                    .ThenInclude(v => v.Items)
                .Include(q => q.Items)
                .Include(q => q.Contract)
                .FirstOrDefaultAsync(q => q.Id == id);

            if (quote is null) return NotFound(new { message = $"Quote {id} was not found." });

            // Client Visibility Guard: Clients cannot inspect draft / unreleased quotes
            if (_userContext.IsInRole("Client") && !IsQuoteReleased(quote.Status))
            {
                return Forbid();
            }

            return Ok(ToResponseDto(quote));
        }

        // GET /api/quotes/{id}/versions
        [HttpGet("{id:guid}/versions")]
        public async Task<ActionResult<List<QuoteVersionResponseDto>>> GetVersions(Guid id)
        {
            var quote = await _db.Quotes
                .Include(q => q.Versions)
                    .ThenInclude(v => v.Items)
                .FirstOrDefaultAsync(q => q.Id == id);

            if (quote is null) return NotFound(new { message = $"Quote {id} was not found." });

            var versions = quote.Versions.OrderByDescending(v => v.VersionNumber)
                .Select(ToVersionResponseDto)
                .ToList();

            return Ok(versions);
        }

        // POST /api/quotes/{requestId}
        // SPEC: Create draft quote from AI scope output (runs Quotation Engine & Budget-Guard)
        [HttpPost("{requestId:guid}")]
        public async Task<ActionResult<QuoteResponseDto>> CreateDraftFromAiScope(Guid requestId, CreateDraftFromAiScopeDto dto)
        {
            var requestDetails = await _requestProvider.GetRequestDetailsAsync(requestId);
            var designerId = dto.DesignerId ?? requestDetails.AssignedDesignerId;

            // 1. Quotation Engine computes line items & cost breakdown
            var calcResult = _quotationEngine.Calculate(dto.Items);

            // 2. Budget Guard verification
            var budgetCheck = _budgetGuard.Validate(calcResult, requestDetails.MaxBudget);
            if (!budgetCheck.IsValid)
            {
                return BadRequest(new { message = "Quote failed budget guard validation.", errors = budgetCheck.Errors });
            }

            var quoteId = Guid.NewGuid();
            var quote = new Quote
            {
                Id = quoteId,
                ProjectRequestId = requestId,
                DesignerId = designerId,
                ScopeSummary = dto.ScopeSummary ?? $"{requestDetails.StyleProfile} {requestDetails.RoomType} Scope",
                Notes = dto.Notes,
                IsAiGenerated = true,
                Status = QuoteStatus.Stage1Pending,
                TotalCost = calcResult.TotalCost,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            var version = new QuoteVersion
            {
                Id = Guid.NewGuid(),
                QuoteId = quoteId,
                VersionNumber = 1,
                AuthorId = _userContext.UserId ?? designerId,
                AuthorRole = "System",
                MaterialsSubtotal = calcResult.MaterialsSubtotal,
                LaborSubtotal = calcResult.LaborSubtotal,
                DesignFee = calcResult.DesignFee,
                ContingencyAmount = calcResult.ContingencyAmount,
                TaxAmount = calcResult.TaxAmount,
                TotalCost = calcResult.TotalCost,
                Notes = "Initial AI draft generated from project scope.",
                CreatedAt = DateTime.UtcNow,
                Items = calcResult.Items.Select(i => new QuoteVersionItem
                {
                    Id = Guid.NewGuid(),
                    Description = i.Description,
                    Category = i.Category,
                    Quantity = i.Quantity,
                    UnitCost = i.UnitCost,
                    LineTotal = i.LineTotal
                }).ToList()
            };

            quote.Versions.Add(version);

            // Populate legacy items for backward compatibility
            quote.Items = version.Items.Select(i => new QuoteItem
            {
                Id = Guid.NewGuid(),
                QuoteId = quoteId,
                Description = i.Description,
                Category = i.Category,
                Quantity = i.Quantity,
                UnitCost = i.UnitCost,
                LineTotal = i.LineTotal
            }).ToList();

            _db.Quotes.Add(quote);
            await _db.SaveChangesAsync();

            return CreatedAtAction(nameof(GetById), new { id = quote.Id }, ToResponseDto(quote));
        }

        // POST /api/quotes
        // Designer creating a quote directly
        [HttpPost]
        public async Task<ActionResult<QuoteResponseDto>> Create(CreateQuoteDto dto)
        {
            if (dto.Items.Count == 0)
                return BadRequest(new { message = "A quote needs at least one line item." });

            var requestDetails = await _requestProvider.GetRequestDetailsAsync(dto.ProjectRequestId);
            var designerId = dto.DesignerId ?? requestDetails.AssignedDesignerId;

            var calcResult = _quotationEngine.Calculate(dto.Items);
            var budgetCheck = _budgetGuard.Validate(calcResult, requestDetails.MaxBudget);
            if (!budgetCheck.IsValid)
            {
                return BadRequest(new { message = "Quote exceeds client budget or contains invalid lines.", errors = budgetCheck.Errors });
            }

            var quoteId = Guid.NewGuid();
            var quote = new Quote
            {
                Id = quoteId,
                ProjectRequestId = dto.ProjectRequestId,
                DesignerId = designerId,
                ScopeSummary = dto.ScopeSummary ?? $"{requestDetails.StyleProfile} {requestDetails.RoomType} Scope",
                Notes = dto.Notes,
                IsAiGenerated = dto.IsAiGenerated,
                Status = QuoteStatus.Draft,
                TotalCost = calcResult.TotalCost,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            var version = new QuoteVersion
            {
                Id = Guid.NewGuid(),
                QuoteId = quoteId,
                VersionNumber = 1,
                AuthorId = _userContext.UserId ?? designerId,
                AuthorRole = _userContext.Role ?? "Designer",
                MaterialsSubtotal = calcResult.MaterialsSubtotal,
                LaborSubtotal = calcResult.LaborSubtotal,
                DesignFee = calcResult.DesignFee,
                ContingencyAmount = calcResult.ContingencyAmount,
                TaxAmount = calcResult.TaxAmount,
                TotalCost = calcResult.TotalCost,
                Notes = dto.Notes,
                CreatedAt = DateTime.UtcNow,
                Items = calcResult.Items.Select(i => new QuoteVersionItem
                {
                    Id = Guid.NewGuid(),
                    Description = i.Description,
                    Category = i.Category,
                    Quantity = i.Quantity,
                    UnitCost = i.UnitCost,
                    LineTotal = i.LineTotal
                }).ToList()
            };

            quote.Versions.Add(version);
            quote.Items = version.Items.Select(i => new QuoteItem
            {
                Id = Guid.NewGuid(),
                QuoteId = quoteId,
                Description = i.Description,
                Category = i.Category,
                Quantity = i.Quantity,
                UnitCost = i.UnitCost,
                LineTotal = i.LineTotal
            }).ToList();

            _db.Quotes.Add(quote);
            await _db.SaveChangesAsync();

            return CreatedAtAction(nameof(GetById), new { id = quote.Id }, ToResponseDto(quote));
        }

        // POST /api/quotes/draft-from-agent
        [HttpPost("draft-from-agent")]
        public async Task<ActionResult<QuoteResponseDto>> DraftFromAgent(DraftQuoteFromAgentDto dto)
        {
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

            AgentBudgetScopeResponse agentResult;
            try
            {
                agentResult = await _scopeSource.FetchDraftScopeAsync(agentRequest);
            }
            catch (Exception ex)
            {
                return StatusCode(502, new { message = $"Could not retrieve draft from AI service: {ex.Message}" });
            }

            var requestId = dto.ProjectRequestId != Guid.Empty ? dto.ProjectRequestId : Guid.NewGuid();
            var items = agentResult.Items.Select(i => new QuoteItemDto
            {
                Description = i.Description,
                Category = Enum.TryParse<QuoteItemCategory>(i.Category, true, out var cat) ? cat : QuoteItemCategory.Other,
                Quantity = i.Quantity,
                UnitCost = i.UnitCost
            }).ToList();

            return await CreateDraftFromAiScope(requestId, new CreateDraftFromAiScopeDto
            {
                DesignerId = dto.DesignerId != Guid.Empty ? dto.DesignerId : null,
                ScopeSummary = agentResult.ScopeSummary,
                Notes = $"{agentResult.Notes} (agent source: {agentResult.Source})",
                Items = items
            });
        }

        // POST /api/quotes/draft-preview
        [HttpPost("draft-preview")]
        public async Task<ActionResult<AgentBudgetScopeResponse>> DraftPreview(DraftQuoteFromAgentDto dto)
        {
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

            try
            {
                var result = await _scopeSource.FetchDraftScopeAsync(agentRequest);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(502, new { message = $"Could not preview draft scope: {ex.Message}" });
            }
        }

        // PUT /api/quotes/{id}/revise (and PUT /api/quotes/{id})
        // SPEC: Edit line items, creates NEW immutable QuoteVersion, re-runs budget-guard
        [HttpPut("{id:guid}/revise")]
        [HttpPut("{id:guid}")]
        public async Task<ActionResult<QuoteResponseDto>> Revise(Guid id, ReviseQuoteDto dto)
        {
            if (_userContext.IsInRole("Client"))
            {
                return Forbid("Clients are not permitted to author or revise quotes.");
            }

            var quote = await _db.Quotes
                .Include(q => q.Versions)
                    .ThenInclude(v => v.Items)
                .Include(q => q.Items)
                .FirstOrDefaultAsync(q => q.Id == id);

            if (quote is null) return NotFound(new { message = $"Quote {id} was not found." });

            if (quote.Status is QuoteStatus.Stage2Approved or QuoteStatus.Stage2Rejected or QuoteStatus.Accepted or QuoteStatus.Rejected)
                return BadRequest(new { message = $"A {quote.Status} quote can no longer be edited." });

            var requestDetails = await _requestProvider.GetRequestDetailsAsync(quote.ProjectRequestId);

            // 1. Re-calculate with Quotation Engine
            var calcResult = _quotationEngine.Calculate(dto.Items);

            // 2. Budget Guard: Validate quote total <= client max budget BEFORE edit is accepted
            var budgetCheck = _budgetGuard.Validate(calcResult, requestDetails.MaxBudget);
            if (!budgetCheck.IsValid)
            {
                return BadRequest(new { message = "Revised quote rejected by Budget-Guard.", errors = budgetCheck.Errors });
            }

            if (!string.IsNullOrWhiteSpace(dto.ScopeSummary)) quote.ScopeSummary = dto.ScopeSummary;
            if (dto.Notes is not null) quote.Notes = dto.Notes;

            // 3. Create NEW immutable QuoteVersion (Never overwrite prior versions)
            int nextVersionNum = quote.Versions.Count > 0 ? quote.Versions.Max(v => v.VersionNumber) + 1 : 1;
            var newVersion = new QuoteVersion
            {
                Id = Guid.NewGuid(),
                QuoteId = quote.Id,
                VersionNumber = nextVersionNum,
                AuthorId = _userContext.UserId ?? quote.DesignerId,
                AuthorRole = _userContext.Role ?? "Designer",
                MaterialsSubtotal = calcResult.MaterialsSubtotal,
                LaborSubtotal = calcResult.LaborSubtotal,
                DesignFee = calcResult.DesignFee,
                ContingencyAmount = calcResult.ContingencyAmount,
                TaxAmount = calcResult.TaxAmount,
                TotalCost = calcResult.TotalCost,
                Notes = dto.Notes ?? $"Revision v{nextVersionNum}",
                CreatedAt = DateTime.UtcNow,
                Items = calcResult.Items.Select(i => new QuoteVersionItem
                {
                    Id = Guid.NewGuid(),
                    Description = i.Description,
                    Category = i.Category,
                    Quantity = i.Quantity,
                    UnitCost = i.UnitCost,
                    LineTotal = i.LineTotal
                }).ToList()
            };

            _db.QuoteVersions.Add(newVersion);
            quote.TotalCost = calcResult.TotalCost;
            quote.IsAiGenerated = false; // Human revision clears AI flag
            quote.UpdatedAt = DateTime.UtcNow;

            try
            {
                await _db.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException ex)
            {
                return Conflict(new { message = $"Concurrency conflict on Quote {id}: {ex.Message}" });
            }

            return Ok(ToResponseDto(quote));
        }

        // POST /api/quotes/{id}/stage1-decision
        // SPEC: Admin release / send-for-revision / reject (resumes paused AI workflow)
        [HttpPost("{id:guid}/stage1-decision")]
        public async Task<ActionResult<QuoteResponseDto>> Stage1Decision(Guid id, Stage1DecisionDto dto)
        {
            if (_userContext.IsInRole("Client") || _userContext.IsInRole("Designer"))
            {
                return Forbid("Only Administrators may issue Stage 1 governance decisions.");
            }

            var quote = await _db.Quotes
                .Include(q => q.Versions)
                    .ThenInclude(v => v.Items)
                .Include(q => q.Items)
                .FirstOrDefaultAsync(q => q.Id == id);

            if (quote is null) return NotFound(new { message = $"Quote {id} was not found." });

            quote.Status = dto.Action switch
            {
                Stage1Action.Release => QuoteStatus.Stage1Released,
                Stage1Action.SendForRevision => QuoteStatus.Stage1RevisionRequested,
                Stage1Action.Reject => QuoteStatus.Stage1Rejected,
                _ => quote.Status
            };

            quote.UpdatedAt = DateTime.UtcNow;
            if (!string.IsNullOrWhiteSpace(dto.Notes))
            {
                quote.Notes = $"{quote.Notes}\n[Stage 1 {dto.Action}]: {dto.Notes}".Trim();
            }

            await _gateResumer.ResumeStage1GateAsync(quote.Id, dto.Action, dto.Notes);
            await _db.SaveChangesAsync();

            return Ok(ToResponseDto(quote));
        }

        // POST /api/quotes/{id}/stage2-decision
        // SPEC: Client approve / request-changes / reject; approval creates the Contract exactly once (idempotent)
        [HttpPost("{id:guid}/stage2-decision")]
        [HttpPost("{id:guid}/accept")] // Backward compatibility alias
        public async Task<ActionResult<ContractResponseDto>> Stage2Decision(Guid id, [FromBody] Stage2DecisionDto? dto = null)
        {
            var action = dto?.Action ?? Stage2Action.Approve;

            if (_userContext.IsInRole("Admin") || _userContext.IsInRole("Designer"))
            {
                return Forbid("Only Clients may issue Stage 2 decisions.");
            }

            var quote = await _db.Quotes
                .Include(q => q.Versions)
                    .ThenInclude(v => v.Items)
                .Include(q => q.Items)
                .Include(q => q.Contract)
                .FirstOrDefaultAsync(q => q.Id == id);

            if (quote is null) return NotFound(new { message = $"Quote {id} was not found." });

            // Business Rule: Stage 2 is rejected (403/409) if not Released in Stage 1
            if (!IsQuoteReleased(quote.Status) && quote.Status != QuoteStatus.Stage2Approved && quote.Status != QuoteStatus.Accepted)
            {
                return StatusCode(409, new { message = "Quote must be Released by Admin (Stage 1) before Client can decide." });
            }

            if (action == Stage2Action.Approve)
            {
                // Idempotency: If contract already exists, return existing contract cleanly
                if (quote.Contract != null)
                {
                    return Ok(ToContractResponseDto(quote.Contract));
                }

                quote.Status = QuoteStatus.Stage2Approved;
                quote.UpdatedAt = DateTime.UtcNow;

                var requestDetails = await _requestProvider.GetRequestDetailsAsync(quote.ProjectRequestId);
                Guid resolvedClientId = dto?.ClientId ?? _userContext.UserId ?? requestDetails.ClientId;

                var contract = new Contract
                {
                    Id = Guid.NewGuid(),
                    QuoteId = quote.Id,
                    ProjectRequestId = quote.ProjectRequestId,
                    DesignerId = quote.DesignerId,
                    ClientId = resolvedClientId,
                    TotalAmount = quote.TotalCost,
                    TermsSummary = string.IsNullOrWhiteSpace(quote.ScopeSummary) ? "Official Interior Design Contract" : quote.ScopeSummary,
                    Status = ContractStatus.PendingSignature,
                    Quote = quote,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _db.Contracts.Add(contract);
                await _gateResumer.ResumeStage2GateAsync(quote.Id, Stage2Action.Approve, dto?.Feedback);
                await _db.SaveChangesAsync();

                return CreatedAtAction(
                    nameof(ContractsController.GetById),
                    "Contracts",
                    new { id = contract.Id },
                    ToContractResponseDto(contract));
            }
            else if (action == Stage2Action.RequestChanges)
            {
                quote.Status = QuoteStatus.Stage2ChangesRequested;
                quote.UpdatedAt = DateTime.UtcNow;
                if (!string.IsNullOrWhiteSpace(dto?.Feedback))
                {
                    quote.Notes = $"{quote.Notes}\n[Client Feedback]: {dto.Feedback}".Trim();
                }

                await _gateResumer.ResumeStage2GateAsync(quote.Id, Stage2Action.RequestChanges, dto?.Feedback);
                await _db.SaveChangesAsync();

                return Ok(new { message = "Revision requested from designer.", quote = ToResponseDto(quote) });
            }
            else // Reject
            {
                quote.Status = QuoteStatus.Stage2Rejected;
                quote.UpdatedAt = DateTime.UtcNow;
                await _gateResumer.ResumeStage2GateAsync(quote.Id, Stage2Action.Reject, dto?.Feedback);
                await _db.SaveChangesAsync();

                return Ok(new { message = "Quote rejected.", quote = ToResponseDto(quote) });
            }
        }

        // PATCH /api/quotes/{id}/status
        [HttpPatch("{id:guid}/status")]
        public async Task<ActionResult<QuoteResponseDto>> UpdateStatus(Guid id, UpdateQuoteStatusDto dto)
        {
            var quote = await _db.Quotes
                .Include(q => q.Versions)
                    .ThenInclude(v => v.Items)
                .Include(q => q.Items)
                .FirstOrDefaultAsync(q => q.Id == id);

            if (quote is null) return NotFound(new { message = $"Quote {id} was not found." });

            quote.Status = dto.Status;
            quote.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();

            return Ok(ToResponseDto(quote));
        }

        // GET /api/quotes/{id}/export?format=pdf|csv
        // SPEC: PDF or CSV by line item (Designer, Admin, Client)
        [HttpGet("{id:guid}/export")]
        public async Task<IActionResult> Export(Guid id, [FromQuery] string format = "pdf")
        {
            var quote = await _db.Quotes
                .Include(q => q.Versions)
                    .ThenInclude(v => v.Items)
                .FirstOrDefaultAsync(q => q.Id == id);

            if (quote is null) return NotFound(new { message = $"Quote {id} was not found." });

            var version = quote.CurrentVersion;
            if (version is null)
            {
                return BadRequest(new { message = "Quote does not contain any versions to export." });
            }

            if (format.Equals("csv", StringComparison.OrdinalIgnoreCase))
            {
                var bytes = _exportService.GenerateCsv(quote, version);
                return File(bytes, "text/csv", $"Quote_{quote.Id:N}_v{version.VersionNumber}.csv");
            }
            else
            {
                var bytes = _exportService.GeneratePdf(quote, version);
                return File(bytes, "text/html", $"Quote_{quote.Id:N}_v{version.VersionNumber}.html");
            }
        }

        private static bool IsQuoteReleased(QuoteStatus status)
        {
            return status is QuoteStatus.Stage1Released 
                or QuoteStatus.Stage2Approved 
                or QuoteStatus.Stage2ChangesRequested 
                or QuoteStatus.Stage2Rejected 
                or QuoteStatus.ClientReview 
                or QuoteStatus.Accepted;
        }

        private static QuoteResponseDto ToResponseDto(Quote q)
        {
            var currentVer = q.CurrentVersion;
            return new QuoteResponseDto
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
                CurrentVersion = currentVer == null ? null : ToVersionResponseDto(currentVer),
                Versions = q.Versions.OrderByDescending(v => v.VersionNumber).Select(ToVersionResponseDto).ToList(),
                Items = (currentVer?.Items.Select(i => new QuoteItemResponseDto
                {
                    Id = i.Id,
                    Description = i.Description,
                    Category = i.Category,
                    Quantity = i.Quantity,
                    UnitCost = i.UnitCost,
                    LineTotal = i.LineTotal
                }) ?? q.Items.Select(i => new QuoteItemResponseDto
                {
                    Id = i.Id,
                    Description = i.Description,
                    Category = i.Category,
                    Quantity = i.Quantity,
                    UnitCost = i.UnitCost,
                    LineTotal = i.LineTotal
                })).ToList()
            };
        }

        private static QuoteVersionResponseDto ToVersionResponseDto(QuoteVersion v) => new()
        {
            Id = v.Id,
            VersionNumber = v.VersionNumber,
            AuthorId = v.AuthorId,
            AuthorRole = v.AuthorRole,
            MaterialsSubtotal = v.MaterialsSubtotal,
            LaborSubtotal = v.LaborSubtotal,
            DesignFee = v.DesignFee,
            ContingencyAmount = v.ContingencyAmount,
            TaxAmount = v.TaxAmount,
            TotalCost = v.TotalCost,
            Notes = v.Notes,
            CreatedAt = v.CreatedAt,
            Items = v.Items.Select(i => new QuoteVersionItemResponseDto
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
            UpdatedAt = c.UpdatedAt,
            Quote = c.Quote == null ? null : ToResponseDto(c.Quote)
        };
    }
}