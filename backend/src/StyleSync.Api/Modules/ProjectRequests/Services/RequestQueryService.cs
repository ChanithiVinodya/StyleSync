using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.ProjectRequests.DTOs;
using StyleSync.Api.Modules.ProjectRequests.Models.Entities;

namespace StyleSync.Api.Modules.ProjectRequests.Services;

public class RequestQueryService
{
    private readonly AppDbContext _context;

    public RequestQueryService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<PagedResult<RequestSummaryDto>> GetRequestsAsync(RequestQueryParameters query, Guid userId, string role)
    {
        if (query.MinBudget.HasValue && query.MaxBudget.HasValue && query.MinBudget > query.MaxBudget)
        {
            throw new ArgumentException("minBudget cannot be greater than maxBudget.");
        }
        if (query.CreatedFrom.HasValue && query.CreatedTo.HasValue && query.CreatedFrom > query.CreatedTo)
        {
            throw new ArgumentException("createdFrom cannot be after createdTo.");
        }
        if (query.PageSize > 50)
        {
            query.PageSize = 50; // clamp
        }
        if (query.Page < 1)
        {
            query.Page = 1;
        }

        var q = _context.ProjectRequests.AsNoTracking();

        var isAdmin = role == "Admin";
        if (!isAdmin)
        {
            q = q.Where(r => r.ClientId == userId);
        }

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.ToLower();
            if (isAdmin)
            {
                q = q.Where(r => r.ReferenceCode.ToLower().Contains(search) 
                              || r.Description.ToLower().Contains(search)
                              || r.Client.Name.ToLower().Contains(search)
                              || r.Client.Email.ToLower().Contains(search));
            }
            else
            {
                q = q.Where(r => r.ReferenceCode.ToLower().Contains(search) 
                              || r.Description.ToLower().Contains(search));
            }
        }

        if (query.Status != null && query.Status.Any())
        {
            q = q.Where(r => query.Status.Contains(r.Status));
        }
        if (query.RoomType != null && query.RoomType.Any())
        {
            q = q.Where(r => query.RoomType.Contains(r.RoomType));
        }
        if (query.MinBudget.HasValue)
        {
            q = q.Where(r => r.Budget >= query.MinBudget.Value);
        }
        if (query.MaxBudget.HasValue)
        {
            q = q.Where(r => r.Budget <= query.MaxBudget.Value);
        }
        if (query.CreatedFrom.HasValue)
        {
            q = q.Where(r => r.CreatedAt >= query.CreatedFrom.Value);
        }
        if (query.CreatedTo.HasValue)
        {
            q = q.Where(r => r.CreatedAt <= query.CreatedTo.Value);
        }
        if (isAdmin && query.IsFlagged.HasValue)
        {
            q = q.Where(r => r.IsFlagged == query.IsFlagged.Value);
        }

        var sortBy = query.SortBy?.ToLower() ?? "createdat";
        var isDesc = query.SortDir?.ToLower() == "desc" || string.IsNullOrEmpty(query.SortDir);
        
        q = sortBy switch
        {
            "createdat" => isDesc ? q.OrderByDescending(r => r.CreatedAt) : q.OrderBy(r => r.CreatedAt),
            "updatedat" => isDesc ? q.OrderByDescending(r => r.UpdatedAt) : q.OrderBy(r => r.UpdatedAt),
            "budget" => isDesc ? q.OrderByDescending(r => r.Budget) : q.OrderBy(r => r.Budget),
            "status" => isDesc ? q.OrderByDescending(r => r.Status) : q.OrderBy(r => r.Status),
            "roomsize" => isDesc ? q.OrderByDescending(r => r.RoomSizeSqFt) : q.OrderBy(r => r.RoomSizeSqFt),
            _ => throw new ArgumentException($"Invalid sortBy field: {query.SortBy}")
        };

        var totalCount = await q.CountAsync();
        var totalPages = (int)Math.Ceiling(totalCount / (double)query.PageSize);

        var items = await q
            .Skip((query.Page - 1) * query.PageSize)
            .Take(query.PageSize)
            .Select(r => new RequestSummaryDto(
                r.Id,
                r.ReferenceCode,
                r.RoomType,
                r.Budget,
                r.Status,
                r.IsFlagged,
                r.CreatedAt,
                r.UpdatedAt,
                r.RoomPhotoUrl,
                isAdmin ? r.Client.Name : null
            ))
            .ToListAsync();

        return new PagedResult<RequestSummaryDto>(items, query.Page, query.PageSize, totalCount, totalPages);
    }
}
