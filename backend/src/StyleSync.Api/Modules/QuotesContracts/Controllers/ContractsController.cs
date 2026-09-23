using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Data;
using StyleSync.Api.DTOs;
using StyleSync.Api.Models;

namespace StyleSync.Api.Controllers
{
    [ApiController]
    [Route("api/contracts")]
    public class ContractsController : ControllerBase
    {
        private readonly AppDbContext _db;

        public ContractsController(AppDbContext db)
        {
            _db = db;
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

            var query = _db.Contracts.AsQueryable();
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
            var contract = await _db.Contracts.FirstOrDefaultAsync(c => c.Id == id);
            if (contract is null) return NotFound(new { message = $"Contract {id} was not found." });
            return Ok(ToResponseDto(contract));
        }

        // PUT /api/contracts/{id}
        // Staff updates status/dates/terms. Status transitions are checked so a
        // Completed or Cancelled contract can't be silently reopened.
        [HttpPut("{id:guid}")]
        public async Task<ActionResult<ContractResponseDto>> Update(Guid id, UpdateContractDto dto)
        {
            var contract = await _db.Contracts.FirstOrDefaultAsync(c => c.Id == id);
            if (contract is null) return NotFound(new { message = $"Contract {id} was not found." });

            if (contract.Status is ContractStatus.Completed or ContractStatus.Cancelled)
                return BadRequest(new { message = $"A {contract.Status} contract cannot be modified." });

            if (dto.Status.HasValue) contract.Status = dto.Status.Value;
            if (dto.StartDate.HasValue) contract.StartDate = dto.StartDate;
            if (dto.EndDate.HasValue) contract.EndDate = dto.EndDate;
            if (dto.TermsSummary is not null) contract.TermsSummary = dto.TermsSummary;

            contract.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();

            return Ok(ToResponseDto(contract));
        }

        // POST /api/contracts/{id}/sign
        // Moves Draft/Pending Signature -> Active and stamps SignedAt.
        [HttpPost("{id:guid}/sign")]
        public async Task<ActionResult<ContractResponseDto>> Sign(Guid id, SignContractDto dto)
        {
            var contract = await _db.Contracts.FirstOrDefaultAsync(c => c.Id == id);
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
        // The only "delete-like" action for a contract — it's a status change,
        // never a row deletion (PRD section 9, Delete row).
        [HttpPost("{id:guid}/cancel")]
        public async Task<ActionResult<ContractResponseDto>> Cancel(Guid id)
        {
            var contract = await _db.Contracts.FirstOrDefaultAsync(c => c.Id == id);
            if (contract is null) return NotFound(new { message = $"Contract {id} was not found." });

            if (contract.Status == ContractStatus.Completed)
                return BadRequest(new { message = "A completed contract cannot be cancelled." });

            contract.Status = ContractStatus.Cancelled;
            contract.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();

            return Ok(ToResponseDto(contract));
        }

        // Note: there is intentionally no [HttpDelete] here — contracts are
        // never deleted, per the PRD.

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
            UpdatedAt = c.UpdatedAt
        };
    }
}
