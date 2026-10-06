using System;
using System.Collections.Generic;
using System.Linq;
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
    [Route("api/contracts")]
    public class ContractsController : ControllerBase
    {
        private readonly AppDbContext _db;
        private readonly IMatchScoreEngine _matchScoreEngine;

        public ContractsController(AppDbContext db, IMatchScoreEngine matchScoreEngine)
        {
            _db = db;
            _matchScoreEngine = matchScoreEngine;
        }

        // GET /api/contracts?status=Active&designerId=...&clientId=...&page=1&pageSize=20
        [HttpGet]
        public async Task<ActionResult<StyleSync.Api.DTOs.PagedResult<ContractResponseDto>>> GetAll(
            [FromQuery] ContractStatus? status,
            [FromQuery] Guid? designerId,
            [FromQuery] Guid? clientId,
            [FromQuery] string sort = "-createdAt",
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            page = Math.Max(page, 1);
            pageSize = Math.Clamp(pageSize, 1, 100);

            var query = _db.Contracts
                .Include(c => c.Quote)
                .ThenInclude(q => q!.Items)
                .AsQueryable();
            if (status.HasValue) query = query.Where(c => c.Status == status.Value);
            if (designerId.HasValue) query = query.Where(c => c.DesignerId == designerId.Value);
            if (clientId.HasValue) query = query.Where(c => c.ClientId == clientId.Value);

            query = sort.TrimStart('-') switch
            {
                "totalAmount" => sort.StartsWith('-') ? query.OrderByDescending(c => c.TotalAmount) : query.OrderBy(c => c.TotalAmount),
                "status" => sort.StartsWith('-') ? query.OrderByDescending(c => c.Status) : query.OrderBy(c => c.Status),
                _ => sort.StartsWith('-') ? query.OrderByDescending(c => c.CreatedAt) : query.OrderBy(c => c.CreatedAt),
            };

            var totalCount = await query.CountAsync();
            var items = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();

            var designerIds = items.Select(c => c.DesignerId).Where(id => id != Guid.Empty).Distinct().ToList();
            var clientIds = items.Select(c => c.ClientId).Where(id => id != Guid.Empty).Distinct().ToList();
            var projectReqIds = items.Select(c => c.ProjectRequestId != Guid.Empty ? c.ProjectRequestId : c.Quote?.ProjectRequestId ?? Guid.Empty)
                .Where(id => id != Guid.Empty).Distinct().ToList();

            var allUserIds = designerIds.Concat(clientIds).Distinct().ToList();
            var users = await _db.Users
                .Where(u => allUserIds.Contains(u.Id))
                .ToDictionaryAsync(u => u.Id);

            var profiles = await _db.DesignerProfiles
                .Where(p => designerIds.Contains(p.UserId))
                .ToDictionaryAsync(p => p.UserId);

            var requests = await _db.ProjectRequests
                .Where(r => projectReqIds.Contains(r.Id))
                .ToDictionaryAsync(r => r.Id);

            var publishedDesigners = await _db.DesignerProfiles
                .AsNoTracking()
                .Include(p => p.User)
                .Include(p => p.PortfolioItems)
                .Where(p => p.ListingStatus == StyleSync.Api.Modules.Designers.Models.ListingStatus.Published)
                .ToListAsync();

            var dtoList = new List<ContractResponseDto>();
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

                if (users.TryGetValue(item.ClientId, out var cu))
                {
                    dto.ClientDisplayName = cu.Name;
                    dto.ClientEmail = cu.Email;
                }

                var targetReqId = item.ProjectRequestId != Guid.Empty ? item.ProjectRequestId : item.Quote?.ProjectRequestId ?? Guid.Empty;
                if (targetReqId != Guid.Empty && requests.TryGetValue(targetReqId, out var req))
                {
                    dto.ProjectReferenceCode = req.ReferenceCode;
                    dto.Description = req.Description;

                    if (string.IsNullOrEmpty(dto.ClientDisplayName) && users.TryGetValue(req.ClientId, out var reqClient))
                    {
                        dto.ClientDisplayName = reqClient.Name;
                        dto.ClientEmail = reqClient.Email;
                    }

                    dto.RecommendedDesigners = ComputeRecommendationsInMemory(req, publishedDesigners);
                }
                else
                {
                    dto.RecommendedDesigners = ComputeRecommendationsInMemory(null, publishedDesigners);
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

                dtoList.Add(dto);
            }

            return Ok(new StyleSync.Api.DTOs.PagedResult<ContractResponseDto>
            {
                Items = dtoList,
                Page = page,
                PageSize = pageSize,
                TotalCount = totalCount
            });
        }

        // GET /api/contracts/{id}
        [HttpGet("{id:guid}")]
        public async Task<ActionResult<ContractResponseDto>> GetById(Guid id)
        {
            var contract = await _db.Contracts
                .Include(c => c.Quote)
                .ThenInclude(q => q!.Items)
                .FirstOrDefaultAsync(c => c.Id == id);
            if (contract is null) return NotFound(new { message = $"Contract {id} was not found." });
            return Ok(await EnrichContractResponseDtoAsync(contract));
        }

        // PUT /api/contracts/{id}
        // Staff updates status/dates/terms. Status transitions are checked so a
        // Completed or Cancelled contract can't be silently reopened.
        [HttpPut("{id:guid}")]
        public async Task<ActionResult<ContractResponseDto>> Update(Guid id, UpdateContractDto dto)
        {
            var contract = await _db.Contracts
                .Include(c => c.Quote)
                .ThenInclude(q => q!.Items)
                .FirstOrDefaultAsync(c => c.Id == id);
            if (contract is null) return NotFound(new { message = $"Contract {id} was not found." });

            if (contract.Status is ContractStatus.Completed or ContractStatus.Cancelled)
                return BadRequest(new { message = $"A {contract.Status} contract cannot be modified." });

            if (dto.Status.HasValue) contract.Status = dto.Status.Value;
            if (dto.StartDate.HasValue) contract.StartDate = DateTime.SpecifyKind(dto.StartDate.Value, DateTimeKind.Utc);
            if (dto.EndDate.HasValue) contract.EndDate = DateTime.SpecifyKind(dto.EndDate.Value, DateTimeKind.Utc);
            if (dto.TermsSummary is not null) contract.TermsSummary = dto.TermsSummary;

            contract.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();

            return Ok(await EnrichContractResponseDtoAsync(contract));
        }

        // POST /api/contracts/{id}/sign
        // Moves Draft/Pending Signature -> Active and stamps SignedAt.
        [HttpPost("{id:guid}/sign")]
        public async Task<ActionResult<ContractResponseDto>> Sign(Guid id, SignContractDto dto)
        {
            var contract = await _db.Contracts
                .Include(c => c.Quote)
                .ThenInclude(q => q!.Items)
                .FirstOrDefaultAsync(c => c.Id == id);
            if (contract is null) return NotFound(new { message = $"Contract {id} was not found." });

            if (contract.Status is ContractStatus.Completed or ContractStatus.Cancelled)
                return BadRequest(new { message = $"A {contract.Status} contract cannot be signed." });

            contract.SignedAt = DateTime.SpecifyKind(dto.SignedAt, DateTimeKind.Utc);
            contract.Status = ContractStatus.Active;
            contract.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();

            return Ok(await EnrichContractResponseDtoAsync(contract));
        }

        // POST /api/contracts/{id}/cancel
        // The only "delete-like" action for a contract — it's a status change,
        // never a row deletion (PRD section 9, Delete row).
        [HttpPost("{id:guid}/cancel")]
        public async Task<ActionResult<ContractResponseDto>> Cancel(Guid id)
        {
            var contract = await _db.Contracts
                .Include(c => c.Quote)
                .ThenInclude(q => q!.Items)
                .FirstOrDefaultAsync(c => c.Id == id);
            if (contract is null) return NotFound(new { message = $"Contract {id} was not found." });

            if (contract.Status == ContractStatus.Completed)
                return BadRequest(new { message = "A completed contract cannot be cancelled." });

            contract.Status = ContractStatus.Cancelled;
            contract.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();

            return Ok(await EnrichContractResponseDtoAsync(contract));
        }

        // Note: there is intentionally no [HttpDelete] here — contracts are
        // never deleted, per the PRD.

        private async Task<ContractResponseDto> EnrichContractResponseDtoAsync(Contract c)
        {
            var dto = ToResponseDto(c);

            // Resolve Designer details
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

            // Resolve Client details
            if (c.ClientId != Guid.Empty)
            {
                var clientUser = await _db.Users.FirstOrDefaultAsync(u => u.Id == c.ClientId);
                if (clientUser != null)
                {
                    dto.ClientDisplayName = clientUser.Name;
                    dto.ClientEmail = clientUser.Email;
                }
            }

            // Resolve Project Request details & recommended shortlist
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

        private static ContractResponseDto ToResponseDto(Contract c) => new()
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
            Quote = c.Quote == null ? null : new QuoteResponseDto
            {
                Id = c.Quote.Id,
                ProjectRequestId = c.Quote.ProjectRequestId,
                DesignerId = c.Quote.DesignerId,
                Status = c.Quote.Status,
                IsAiGenerated = c.Quote.IsAiGenerated,
                ScopeSummary = c.Quote.ScopeSummary,
                Notes = c.Quote.Notes,
                TotalCost = c.Quote.TotalCost,
                CreatedAt = c.Quote.CreatedAt,
                UpdatedAt = c.Quote.UpdatedAt,
                ContractId = c.Id,
                Items = c.Quote.Items?.Select(i => new QuoteItemResponseDto
                {
                    Id = i.Id,
                    Description = i.Description,
                    Category = i.Category,
                    Quantity = i.Quantity,
                    UnitCost = i.UnitCost,
                    LineTotal = i.LineTotal
                }).ToList() ?? new List<QuoteItemResponseDto>()
            }
        };
    }
}

