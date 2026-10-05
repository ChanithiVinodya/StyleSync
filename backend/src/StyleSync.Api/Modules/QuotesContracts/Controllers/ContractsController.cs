using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Data;
using StyleSync.Api.DTOs;
using StyleSync.Api.Integrations;
using StyleSync.Api.Models;

namespace StyleSync.Api.Controllers
{
    [ApiController]
    [Route("api/contracts")]
    public class ContractsController : ControllerBase
    {
        private readonly AppDbContext _db;
        private readonly ICurrentUserContext _userContext;

        public ContractsController(AppDbContext db, ICurrentUserContext userContext)
        {
            _db = db;
            _userContext = userContext;
        }

        // GET /api/contracts?status=Active&designerId=...&clientId=...&page=1&pageSize=20
        [HttpGet]
        public async Task<ActionResult<PagedResult<ContractResponseDto>>> GetAll(
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
                    .ThenInclude(q => q!.Versions)
                        .ThenInclude(v => v.Items)
                .Include(c => c.Quote)
                    .ThenInclude(q => q!.Items)
                .AsQueryable();

            // Role Scoping: Client only sees their own contracts; Designer sees their assigned contracts
            if (_userContext.IsInRole("Client") && _userContext.UserId.HasValue)
            {
                query = query.Where(c => c.ClientId == _userContext.UserId.Value);
            }
            else if (_userContext.IsInRole("Designer") && _userContext.UserId.HasValue)
            {
                query = query.Where(c => c.DesignerId == _userContext.UserId.Value);
            }

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

            return Ok(new PagedResult<ContractResponseDto>
            {
                Items = items.Select(ToResponseDto).ToList(),
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
                    .ThenInclude(q => q!.Versions)
                        .ThenInclude(v => v.Items)
                .Include(c => c.Quote)
                    .ThenInclude(q => q!.Items)
                .FirstOrDefaultAsync(c => c.Id == id);

            if (contract is null) return NotFound(new { message = $"Contract {id} was not found." });

            if (_userContext.IsInRole("Client") && _userContext.UserId.HasValue && contract.ClientId != _userContext.UserId.Value)
            {
                return Forbid();
            }

            return Ok(ToResponseDto(contract));
        }

        // PUT /api/contracts/{id}
        // SPEC: Admin updates contract status (Active / Completed / Cancelled) with validated transitions
        [HttpPut("{id:guid}")]
        public async Task<ActionResult<ContractResponseDto>> Update(Guid id, UpdateContractDto dto)
        {
            if (_userContext.IsInRole("Designer"))
            {
                return Forbid("Designers cannot modify contract statuses.");
            }

            var contract = await _db.Contracts
                .Include(c => c.Quote)
                .FirstOrDefaultAsync(c => c.Id == id);

            if (contract is null) return NotFound(new { message = $"Contract {id} was not found." });

            if (dto.Status.HasValue)
            {
                if (!contract.CanTransitionTo(dto.Status.Value))
                {
                    return BadRequest(new { message = $"Illegal contract status transition from {contract.Status} to {dto.Status.Value}." });
                }
                contract.Status = dto.Status.Value;
            }

            if (dto.StartDate.HasValue) contract.StartDate = dto.StartDate;
            if (dto.EndDate.HasValue) contract.EndDate = dto.EndDate;
            if (dto.TermsSummary is not null) contract.TermsSummary = dto.TermsSummary;

            contract.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();

            return Ok(ToResponseDto(contract));
        }

        // POST /api/contracts/{id}/sign
        // Moves PendingSignature -> Active and stamps SignedAt
        [HttpPost("{id:guid}/sign")]
        public async Task<ActionResult<ContractResponseDto>> Sign(Guid id, SignContractDto dto)
        {
            var contract = await _db.Contracts
                .Include(c => c.Quote)
                .FirstOrDefaultAsync(c => c.Id == id);

            if (contract is null) return NotFound(new { message = $"Contract {id} was not found." });

            if (contract.Status is ContractStatus.Completed or ContractStatus.Cancelled)
                return BadRequest(new { message = $"A {contract.Status} contract cannot be signed." });

            contract.SignedAt = dto.SignedAt;
            contract.Status = ContractStatus.Active;
            contract.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();

            return Ok(ToResponseDto(contract));
        }

        // POST /api/contracts/{id}/cancel
        [HttpPost("{id:guid}/cancel")]
        public async Task<ActionResult<ContractResponseDto>> Cancel(Guid id)
        {
            var contract = await _db.Contracts
                .Include(c => c.Quote)
                .FirstOrDefaultAsync(c => c.Id == id);

            if (contract is null) return NotFound(new { message = $"Contract {id} was not found." });

            if (contract.Status == ContractStatus.Completed)
                return BadRequest(new { message = "A completed contract cannot be cancelled." });

            contract.Status = ContractStatus.Cancelled;
            contract.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();

            return Ok(ToResponseDto(contract));
        }

        private static ContractResponseDto ToResponseDto(Contract c)
        {
            var currentVer = c.Quote?.CurrentVersion;
            return new ContractResponseDto
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
                    CurrentVersion = currentVer == null ? null : new QuoteVersionResponseDto
                    {
                        Id = currentVer.Id,
                        VersionNumber = currentVer.VersionNumber,
                        AuthorId = currentVer.AuthorId,
                        AuthorRole = currentVer.AuthorRole,
                        MaterialsSubtotal = currentVer.MaterialsSubtotal,
                        LaborSubtotal = currentVer.LaborSubtotal,
                        DesignFee = currentVer.DesignFee,
                        ContingencyAmount = currentVer.ContingencyAmount,
                        TaxAmount = currentVer.TaxAmount,
                        TotalCost = currentVer.TotalCost,
                        Notes = currentVer.Notes,
                        CreatedAt = currentVer.CreatedAt,
                        Items = currentVer.Items.Select(i => new QuoteVersionItemResponseDto
                        {
                            Id = i.Id,
                            Description = i.Description,
                            Category = i.Category,
                            Quantity = i.Quantity,
                            UnitCost = i.UnitCost,
                            LineTotal = i.LineTotal
                        }).ToList()
                    },
                    Items = (currentVer?.Items.Select(i => new QuoteItemResponseDto
                    {
                        Id = i.Id,
                        Description = i.Description,
                        Category = i.Category,
                        Quantity = i.Quantity,
                        UnitCost = i.UnitCost,
                        LineTotal = i.LineTotal
                    }) ?? c.Quote.Items.Select(i => new QuoteItemResponseDto
                    {
                        Id = i.Id,
                        Description = i.Description,
                        Category = i.Category,
                        Quantity = i.Quantity,
                        UnitCost = i.UnitCost,
                        LineTotal = i.LineTotal
                    })).ToList()
                }
            };
        }
    }
}
