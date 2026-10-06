using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Identity;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.ProjectRequests.DTOs;
using StyleSync.Api.Modules.ProjectRequests.Models.Entities;
using StyleSync.Api.Modules.ProjectRequests.Models.Enums;
using StyleSync.Api.Modules.ProjectRequests.Services;
using StyleSync.Api.Common.Storage;

namespace StyleSync.Api.Modules.ProjectRequests.Controllers;

[ApiController]
[Route("requests")]
[Route("api/requests")]
[Authorize]
public class ProjectRequestsController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly RequestValidationRules _validationRules;
    private readonly RequestStatusService _statusService;
    private readonly RequestQueryService _queryService;
    private readonly ICurrentUser _currentUser;

    public ProjectRequestsController(
        AppDbContext context, 
        RequestValidationRules validationRules, 
        RequestStatusService statusService, 
        RequestQueryService queryService,
        ICurrentUser currentUser)
    {
        _context = context;
        _validationRules = validationRules;
        _statusService = statusService;
        _queryService = queryService;
        _currentUser = currentUser;
    }

    /// <summary>
    /// Gets a paginated list of project requests.
    /// </summary>
    /// <response code="200">Returns the paginated list.</response>
    /// <response code="400">If the query parameters are invalid.</response>
    [HttpGet]
    [ProducesResponseType(typeof(PagedResult<RequestSummaryDto>), 200)]
    [ProducesResponseType(typeof(ProblemDetails), 400)]
    public async Task<IActionResult> GetRequests([FromQuery] RequestQueryParameters query)
    {
        try
        {
            var result = await _queryService.GetRequestsAsync(query, _currentUser.Id, _currentUser.Role);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new ProblemDetails
            {
                Status = 400,
                Title = "Invalid Query",
                Detail = ex.Message
            });
        }
    }

    /// <summary>
    /// Creates a new draft project request.
    /// </summary>
    /// <response code="201">Returns the created draft.</response>
    /// <response code="400">If validation fails.</response>
    [HttpPost]
    [ProducesResponseType(typeof(RequestDetailDto), 201)]
    [ProducesResponseType(typeof(ProblemDetails), 400)]
    [Authorize(Roles = "Client")]
    public async Task<IActionResult> CreateDraft([FromBody] CreateRequestDto dto)
    {
        var initialDesc = dto.Description ?? string.Empty;
        if (dto.RequestedStyleTags != null && dto.RequestedStyleTags.Any())
        {
            var styleTag = $"[Styles: {string.Join(", ", dto.RequestedStyleTags)}]";
            if (!initialDesc.Contains("[Styles:"))
            {
                initialDesc = string.IsNullOrEmpty(initialDesc) ? styleTag : $"{initialDesc}\n\n{styleTag}";
            }
        }

        var request = new ProjectRequest
        {
            ClientId = _currentUser.Id,
            RoomType = dto.RoomType ?? RoomType.LivingRoom,
            RoomSizeSqFt = dto.RoomSizeSqFt ?? dto.RoomSizeSqM ?? 0m,
            Budget = dto.Budget ?? 0m,
            Description = initialDesc,
            RequestedStyleTags = dto.RequestedStyleTags ?? new List<string>(),
            PreferredDesignerId = dto.PreferredDesignerId,
            Status = RequestStatus.Draft,
            ReferenceCode = $"REQ-{new Random().Next(100000, 999999)}"
        };

        ApplyPaletteSelection(request, dto.Palette);

        var errors = _validationRules.ValidateDraft(request);
        if (errors.Any())
        {
            var problemDetails = new ProblemDetails
            {
                Status = 400,
                Title = "Validation Failed",
                Type = "https://tools.ietf.org/html/rfc7231#section-6.5.1"
            };
            problemDetails.Extensions["errors"] = errors.Select(e => new { field = e.Field, code = e.Code, message = e.Message }).ToArray();
            return BadRequest(problemDetails);
        }

        _context.ProjectRequests.Add(request);
        
        var history = new RequestStatusHistory
        {
            ProjectRequestId = request.Id,
            FromStatus = null,
            ToStatus = RequestStatus.Draft,
            ChangedAt = DateTime.UtcNow,
            ChangedByUserId = _currentUser.Id,
            Note = "Initial Draft created"
        };
        _context.RequestStatusHistories.Add(history);
        
        await _context.SaveChangesAsync();

        // We need to fetch it back to load the history properly for the response
        var requestWithNavs = await _context.ProjectRequests
            .Include(r => r.MoodboardImages)
            .Include(r => r.SuggestedPalettes)
            .Include(r => r.StatusHistories)
            .FirstAsync(r => r.Id == request.Id);

        return StatusCode(201, MapToDetailDto(requestWithNavs));
    }

    /// <summary>
    /// Gets a project request by its unique identifier.
    /// </summary>
    /// <response code="200">Returns the request details.</response>
    /// <response code="404">If the request is not found.</response>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(RequestDetailDto), 200)]
    [ProducesResponseType(typeof(ProblemDetails), 404)]
    public async Task<IActionResult> GetById(Guid id)
    {
        var request = await _context.ProjectRequests
            .Include(r => r.MoodboardImages)
            .Include(r => r.SuggestedPalettes)
            .Include(r => r.StatusHistories)
            .Include(r => r.PreferredDesigner)
            .FirstOrDefaultAsync(r => r.Id == id);

        if (request == null)
            return NotFound(new { message = "Request not found." });

        if (_currentUser.Role == "Client" && request.ClientId != _currentUser.Id)
            return NotFound(new { message = "Request not found." });

        if (request.Status == RequestStatus.DesignerAssigned)
        {
            var hasAcceptedQuoteOrContract = await _context.Contracts.AnyAsync(c => c.ProjectRequestId == request.Id)
                || await _context.Quotes.AnyAsync(q => q.ProjectRequestId == request.Id && q.Status == StyleSync.Api.Models.QuoteStatus.Accepted);
            
            if (hasAcceptedQuoteOrContract)
            {
                request.Status = RequestStatus.InProgress;
                request.UpdatedAt = DateTime.UtcNow;
                _context.RequestStatusHistories.Add(new RequestStatusHistory
                {
                    ProjectRequestId = request.Id,
                    FromStatus = RequestStatus.DesignerAssigned,
                    ToStatus = RequestStatus.InProgress,
                    ChangedAt = DateTime.UtcNow,
                    Note = "Client accepted quote and contract created; project execution started"
                });
                await _context.SaveChangesAsync();
            }
        }

        var detailDto = MapToDetailDto(request);
        return Ok(detailDto);
    }

    /// <summary>
    /// Updates an existing draft project request.
    /// </summary>
    /// <response code="204">If the update is successful.</response>
    /// <response code="400">If validation fails.</response>
    /// <response code="404">If the request is not found.</response>
    /// <response code="409">If the request is not a Draft.</response>
    [HttpPut("{id:guid}")]
    [ProducesResponseType(204)]
    [ProducesResponseType(typeof(ProblemDetails), 400)]
    [Authorize(Roles = "Client")]
    public async Task<IActionResult> UpdateDraft(Guid id, [FromBody] UpdateRequestDto dto)
    {
        var request = await _context.ProjectRequests
            .Include(r => r.MoodboardImages)
            .Include(r => r.SuggestedPalettes)
            .Include(r => r.StatusHistories)
            .FirstOrDefaultAsync(r => r.Id == id);

        if (request == null || request.ClientId != _currentUser.Id)
            return NotFound(new { message = "Request not found." });

        if (request.Status != RequestStatus.Draft)
            return Conflict(new { message = "Only drafts can be edited." });

        request.RoomType = dto.RoomType ?? request.RoomType;
        request.RoomSizeSqFt = dto.RoomSizeSqFt ?? dto.RoomSizeSqM ?? request.RoomSizeSqFt;
        request.Budget = dto.Budget ?? request.Budget;
        request.Description = dto.Description ?? request.Description;
        if (dto.PreferredDesignerId.HasValue)
        {
            request.PreferredDesignerId = dto.PreferredDesignerId.Value;
        }
        if (dto.RequestedStyleTags != null && dto.RequestedStyleTags.Any())
        {
            request.RequestedStyleTags = dto.RequestedStyleTags;
            var styleTag = $"[Styles: {string.Join(", ", dto.RequestedStyleTags)}]";
            if (!string.IsNullOrEmpty(request.Description) && !request.Description.Contains("[Styles:"))
            {
                request.Description = $"{request.Description}\n\n{styleTag}";
            }
            else if (string.IsNullOrEmpty(request.Description))
            {
                request.Description = styleTag;
            }
        }
        request.UpdatedAt = DateTime.UtcNow;

        ApplyPaletteSelection(request, dto.Palette);

        var errors = _validationRules.ValidateDraft(request);
        if (errors.Any())
        {
            var problemDetails = new ProblemDetails
            {
                Status = 400,
                Title = "Validation Failed",
                Type = "https://tools.ietf.org/html/rfc7231#section-6.5.1"
            };
            problemDetails.Extensions["errors"] = errors.Select(e => new { field = e.Field, code = e.Code, message = e.Message }).ToArray();
            return BadRequest(problemDetails);
        }

        await _context.SaveChangesAsync();

        return Ok(MapToDetailDto(request));
    }

    /// <summary>
    /// Deletes a draft project request.
    /// </summary>
    /// <response code="204">If deletion is successful.</response>
    /// <response code="404">If the request is not found.</response>
    /// <response code="409">If the request is not a Draft.</response>
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(204)]
    [ProducesResponseType(typeof(ProblemDetails), 404)]
    [Authorize(Roles = "Client")]
    public async Task<IActionResult> DeleteDraft(Guid id, [FromServices] IFileStorage fileStorage)
    {
        var request = await _context.ProjectRequests
            .Include(r => r.MoodboardImages)
            .FirstOrDefaultAsync(r => r.Id == id);

        if (request == null || request.ClientId != _currentUser.Id)
            return NotFound(new { message = "Request not found." });

        if (request.Status != RequestStatus.Draft)
            return Conflict(new { message = "Only drafts can be deleted." });

        if (!string.IsNullOrEmpty(request.RoomPhotoStorageKey))
        {
            await fileStorage.DeleteAsync(request.RoomPhotoStorageKey);
        }

        foreach (var mb in request.MoodboardImages)
        {
            await fileStorage.DeleteAsync(mb.StorageKey);
        }

        _context.ProjectRequests.Remove(request);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    /// <summary>
    /// Submits a draft project request for processing.
    /// </summary>
    /// <response code="200">If submission is successful.</response>
    /// <response code="400">If strict submit validation fails.</response>
    /// <response code="404">If the request is not found.</response>
    /// <response code="409">If the request is not a Draft.</response>
    [HttpPost("{id:guid}/submit")]
    [ProducesResponseType(200)]
    [ProducesResponseType(typeof(ProblemDetails), 400)]
    [Authorize(Roles = "Client")]
    public async Task<IActionResult> SubmitDraft(Guid id, [FromServices] IWorkflowStarter workflowStarter, [FromServices] Microsoft.Extensions.Logging.ILogger<ProjectRequestsController> logger)
    {
        var request = await _context.ProjectRequests
            .Include(r => r.StatusHistories)
            .Include(r => r.MoodboardImages)
            .Include(r => r.SuggestedPalettes)
            .FirstOrDefaultAsync(r => r.Id == id);

        if (request == null || request.ClientId != _currentUser.Id)
            return NotFound(new { message = "Request not found." });

        if (request.Status != RequestStatus.Draft)
        {
            return Conflict(new ProblemDetails
            {
                Status = 409,
                Title = "Conflict",
                Extensions = { ["code"] = "REQUEST_NOT_DRAFT" }
            });
        }

        var errors = _validationRules.ValidateSubmit(request);
        if (errors.Any())
        {
            var problemDetails = new ProblemDetails
            {
                Status = 400,
                Title = "Validation Failed",
                Type = "https://tools.ietf.org/html/rfc7231#section-6.5.1"
            };
            problemDetails.Extensions["errors"] = errors.Select(e => new { field = e.Field, code = e.Code, message = e.Message }).ToArray();
            return BadRequest(problemDetails);
        }

        request.SubmittedAt = DateTime.UtcNow;

        try
        {
            await _statusService.TransitionAsync(request.Id, RequestStatus.Submitted, _currentUser.Id, "Submitted by client");
        }
        catch (DbUpdateConcurrencyException)
        {
            return Conflict(new ProblemDetails
            {
                Status = 409,
                Title = "Conflict",
                Extensions = { ["code"] = "REQUEST_NOT_DRAFT" }
            });
        }
        catch (StyleSync.Api.Modules.ProjectRequests.Services.IllegalStatusTransitionException)
        {
            return Conflict(new ProblemDetails
            {
                Status = 409,
                Title = "Conflict",
                Extensions = { ["code"] = "REQUEST_NOT_DRAFT" }
            });
        }

        try
        {
            _ = Task.Run(async () =>
            {
                try
                {
                    await workflowStarter.StartAsync(request.Id);
                }
                catch (Exception ex)
                {
                    logger.LogError(ex, "Background AI workflow for request {id} failed", request.Id);
                }
            });

            var updatedRequest = await _context.ProjectRequests
                .Include(r => r.StatusHistories)
                .Include(r => r.MoodboardImages)
                .Include(r => r.SuggestedPalettes)
                .AsNoTracking()
                .FirstOrDefaultAsync(r => r.Id == id);
            return Ok(MapToDetailDto(updatedRequest ?? request));
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "workflow start requested for {id} failed", request.Id);
            return Ok(MapToDetailDto(request));
        }
    }

    /// <summary>
    /// Cancels an active project request. (Admin only)
    /// </summary>
    /// <response code="200">If cancellation is successful.</response>
    /// <response code="400">If the reason is invalid.</response>
    /// <response code="404">If the request is not found.</response>
    /// <response code="409">If the request is in a terminal state.</response>
    [HttpPost("{id:guid}/cancel")]
    [ProducesResponseType(200)]
    [ProducesResponseType(typeof(ProblemDetails), 400)]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> CancelRequest(Guid id, [FromBody] CancelRequestDto dto)
    {
        if (dto == null || string.IsNullOrWhiteSpace(dto.Reason) || dto.Reason.Length < 5 || dto.Reason.Length > 500)
            return BadRequest(new { message = "Reason must be between 5 and 500 characters." });

        var request = await _context.ProjectRequests.FirstOrDefaultAsync(r => r.Id == id);
        if (request == null)
            return NotFound(new { message = "Request not found." });

        request.CancelReason = dto.Reason;
        
        _context.RequestAuditLogs.Add(new RequestAuditLog
        {
            ActorId = _currentUser.Id,
            Action = "REQUEST_CANCELLED",
            EntityId = request.Id,
            Reason = dto.Reason,
            Timestamp = DateTime.UtcNow
        });

        try
        {
            await _statusService.TransitionAsync(request.Id, RequestStatus.Cancelled, _currentUser.Id, dto.Reason);
        }
        catch (StyleSync.Api.Modules.ProjectRequests.Services.IllegalStatusTransitionException)
        {
            return Conflict(new { message = "Cannot cancel from a terminal state." });
        }

        return Ok(new { message = "Request cancelled successfully." });
    }

    /// <summary>
    /// Flags or unflags a project request for review. (Admin only)
    /// </summary>
    /// <response code="200">If flagging/unflagging is successful.</response>
    /// <response code="400">If the reason is invalid.</response>
    /// <response code="404">If the request is not found.</response>
    [HttpPost("{id:guid}/flag")]
    [ProducesResponseType(200)]
    [ProducesResponseType(typeof(ProblemDetails), 400)]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> FlagRequest(Guid id, [FromBody] FlagRequestDto dto)
    {
        if (dto == null || string.IsNullOrWhiteSpace(dto.Reason) || dto.Reason.Length < 5 || dto.Reason.Length > 500)
            return BadRequest(new { message = "Reason must be between 5 and 500 characters." });

        var request = await _context.ProjectRequests.FirstOrDefaultAsync(r => r.Id == id);
        if (request == null)
            return NotFound(new { message = "Request not found." });

        request.IsFlagged = dto.IsFlagged;
        if (dto.IsFlagged)
        {
            request.FlagReason = dto.Reason;
            request.FlaggedAt = DateTime.UtcNow;
            request.FlaggedByUserId = _currentUser.Id;
        }
        else
        {
            request.FlagReason = null;
            request.FlaggedAt = null;
            request.FlaggedByUserId = null;
        }

        _context.RequestAuditLogs.Add(new RequestAuditLog
        {
            ActorId = _currentUser.Id,
            Action = dto.IsFlagged ? "REQUEST_FLAGGED" : "REQUEST_UNFLAGGED",
            EntityId = request.Id,
            Reason = dto.Reason,
            Timestamp = DateTime.UtcNow
        });

        await _context.SaveChangesAsync();
        return Ok(new { message = dto.IsFlagged ? "Request flagged." : "Request unflagged." });
    }

    /// <summary>
    /// Approves a project request. (Admin only)
    /// </summary>
    /// <response code="200">If approval is successful.</response>
    /// <response code="404">If the request is not found.</response>
    /// <response code="409">If the request is not in AwaitingApproval state.</response>
    [HttpPost("{id:guid}/approve")]
    [ProducesResponseType(200)]
    [ProducesResponseType(typeof(ProblemDetails), 400)]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ApproveRequest(Guid id)
    {
        var request = await _context.ProjectRequests.FirstOrDefaultAsync(r => r.Id == id);
        if (request == null)
            return NotFound(new { message = "Request not found." });

        if (request.Status != RequestStatus.AwaitingApproval)
        {
            return Conflict(new ProblemDetails
            {
                Status = 409,
                Title = "Conflict",
                Detail = "Only requests in AwaitingApproval status can be approved."
            });
        }

        var actorId = (_currentUser.Id != Guid.Empty) 
            ? _currentUser.Id 
            : (await _context.Users.FirstOrDefaultAsync(u => u.Email == "admin@stylesync.com" || u.Role == StyleSync.Api.Common.Identity.UserRole.Admin))?.Id ?? request.ClientId;

        _context.RequestAuditLogs.Add(new RequestAuditLog
        {
            ActorId = actorId,
            Action = "REQUEST_APPROVED",
            EntityId = request.Id,
            Reason = "Admin approved the request",
            Timestamp = DateTime.UtcNow
        });

        try
        {
            var adminUserId = (_currentUser.Id != Guid.Empty) ? (Guid?)_currentUser.Id : (Guid?)actorId;
            await _statusService.TransitionAsync(request.Id, RequestStatus.Approved, adminUserId, "Admin approved the request");

            // If a designer is assigned (preferred or via AI quote or first available designer), advance to DesignerAssigned
            var quote = await _context.Quotes.Include(q => q.Items).FirstOrDefaultAsync(q => q.ProjectRequestId == request.Id);
            var assignedDesignerId = request.PreferredDesignerId ?? quote?.DesignerId;
            if (!assignedDesignerId.HasValue)
            {
                var fallbackDesigner = await _context.Users.FirstOrDefaultAsync(u => u.Role == StyleSync.Api.Common.Identity.UserRole.Designer);
                if (fallbackDesigner != null)
                {
                    assignedDesignerId = fallbackDesigner.Id;
                }
            }

            if (assignedDesignerId.HasValue)
            {
                request.PreferredDesignerId = assignedDesignerId.Value;
            }

            // Ensure an itemized quote exists for the client upon approval
            if (quote == null)
            {
                var budget = request.Budget > 0 ? request.Budget : 5000m;
                var quoteId = Guid.NewGuid();
                var designerId = assignedDesignerId ?? Guid.NewGuid();
                var roomName = request.RoomType.ToString();

                var items = new List<StyleSync.Api.Models.QuoteItem>
                {
                    new()
                    {
                        Id = Guid.NewGuid(),
                        QuoteId = quoteId,
                        Description = $"Design — Concept planning, 2D layouts & 3D renders for {roomName.ToLower()}",
                        Category = StyleSync.Api.Models.QuoteItemCategory.Design,
                        Quantity = 1,
                        UnitCost = Math.Round(budget * 0.10m, 2),
                        LineTotal = Math.Round(budget * 0.10m, 2)
                    },
                    new()
                    {
                        Id = Guid.NewGuid(),
                        QuoteId = quoteId,
                        Description = $"Labor — Skilled installation, wall preparation & lighting fitout",
                        Category = StyleSync.Api.Models.QuoteItemCategory.Labor,
                        Quantity = 1,
                        UnitCost = Math.Round(budget * 0.30m, 2),
                        LineTotal = Math.Round(budget * 0.30m, 2)
                    },
                    new()
                    {
                        Id = Guid.NewGuid(),
                        QuoteId = quoteId,
                        Description = $"Materials — Surface finishes, bespoke cabinetry & architectural hardware",
                        Category = StyleSync.Api.Models.QuoteItemCategory.Materials,
                        Quantity = 1,
                        UnitCost = Math.Round(budget * 0.35m, 2),
                        LineTotal = Math.Round(budget * 0.35m, 2)
                    },
                    new()
                    {
                        Id = Guid.NewGuid(),
                        QuoteId = quoteId,
                        Description = $"Furniture — Curated styling package, textiles & decor accents",
                        Category = StyleSync.Api.Models.QuoteItemCategory.Furniture,
                        Quantity = 1,
                        UnitCost = Math.Round(budget * 0.20m, 2),
                        LineTotal = Math.Round(budget * 0.20m, 2)
                    },
                    new()
                    {
                        Id = Guid.NewGuid(),
                        QuoteId = quoteId,
                        Description = $"Project Oversight — Site supervision & quality assurance",
                        Category = StyleSync.Api.Models.QuoteItemCategory.Other,
                        Quantity = 1,
                        UnitCost = Math.Round(budget * 0.05m, 2),
                        LineTotal = Math.Round(budget * 0.05m, 2)
                    }
                };

                quote = new StyleSync.Api.Models.Quote
                {
                    Id = quoteId,
                    ProjectRequestId = request.Id,
                    DesignerId = designerId,
                    Status = StyleSync.Api.Models.QuoteStatus.Stage1Released,
                    IsAiGenerated = true,
                    ScopeSummary = $"Complete interior transformation for {roomName} ({request.RoomSizeSqFt:0} sq ft).",
                    Notes = $"Proposal prepared based on approved design request and estimated budget of ${budget:N2}.",
                    Items = items,
                    TotalCost = items.Sum(i => i.LineTotal)
                };

                _context.Quotes.Add(quote);
            }
            else if (quote.Status == StyleSync.Api.Models.QuoteStatus.Draft || quote.Status == StyleSync.Api.Models.QuoteStatus.Stage1Pending)
            {
                quote.Status = StyleSync.Api.Models.QuoteStatus.Stage1Released;
            }

            await _context.SaveChangesAsync();

            if (assignedDesignerId.HasValue)
            {
                await _statusService.TransitionAsync(request.Id, RequestStatus.DesignerAssigned, adminUserId, "Designer assigned to approved request");
            }
        }
        catch (StyleSync.Api.Modules.ProjectRequests.Services.IllegalStatusTransitionException)
        {
            return Conflict(new { message = "Cannot approve from the current state." });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "An error occurred while approving the request: " + ex.Message });
        }

        return Ok(new { message = "Request approved successfully." });
    }

    /// <summary>
    /// Assigns a designer to an approved project request. (Admin only)
    /// </summary>
    /// <response code="200">If assignment is successful.</response>
    /// <response code="400">If designer is invalid.</response>
    /// <response code="404">If request is not found.</response>
    [HttpPost("{id:guid}/assign-designer")]
    [ProducesResponseType(200)]
    [ProducesResponseType(typeof(ProblemDetails), 400)]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> AssignDesigner(Guid id, [FromBody] AssignDesignerDto dto)
    {
        var request = await _context.ProjectRequests.FirstOrDefaultAsync(r => r.Id == id);
        if (request == null)
            return NotFound(new { message = "Request not found." });

        var designer = await _context.Users.FirstOrDefaultAsync(u => u.Id == dto.DesignerId && u.Role == StyleSync.Api.Common.Identity.UserRole.Designer);
        if (designer == null)
            return BadRequest(new { message = "Selected user is not a valid designer." });

        request.PreferredDesignerId = designer.Id;
        await _context.SaveChangesAsync();

        if (request.Status == RequestStatus.Approved)
        {
            await _statusService.TransitionAsync(request.Id, RequestStatus.DesignerAssigned, _currentUser.Id, $"Designer {designer.Name} assigned by admin");
        }

        return Ok(new { message = $"Designer {designer.Name} assigned successfully." });
    }

    /// <summary>
    /// Starts project execution (DesignerAssigned -> InProgress).
    /// </summary>
    /// <response code="200">If transition is successful.</response>
    /// <response code="404">If request is not found.</response>
    /// <response code="409">If request cannot transition to InProgress.</response>
    [HttpPost("{id:guid}/start-execution")]
    [HttpPost("{id:guid}/in-progress")]
    [ProducesResponseType(200)]
    [ProducesResponseType(typeof(ProblemDetails), 400)]
    [Authorize]
    public async Task<IActionResult> StartExecution(Guid id)
    {
        var request = await _context.ProjectRequests.FirstOrDefaultAsync(r => r.Id == id);
        if (request == null)
            return NotFound(new { message = "Request not found." });

        if (request.Status != RequestStatus.DesignerAssigned && request.Status != RequestStatus.Approved)
        {
            return Conflict(new ProblemDetails
            {
                Status = 409,
                Title = "Conflict",
                Detail = $"Cannot transition request in {request.Status} status to InProgress."
            });
        }

        var actorId = (_currentUser.Id != Guid.Empty) 
            ? _currentUser.Id 
            : (await _context.Users.FirstOrDefaultAsync(u => u.Email == "admin@stylesync.com" || u.Role == StyleSync.Api.Common.Identity.UserRole.Admin))?.Id;

        if (request.Status == RequestStatus.Approved)
        {
            await _statusService.TransitionAsync(request.Id, RequestStatus.DesignerAssigned, actorId, "Designer assigned to request");
        }

        await _statusService.TransitionAsync(request.Id, RequestStatus.InProgress, actorId, "Project execution started");

        return Ok(new { message = "Project request is now In Progress." });
    }

    /// <summary>
    /// Gets aggregated analytics for project requests. (Admin only)
    /// </summary>
    /// <response code="200">Returns the analytics data.</response>
    [HttpGet("analytics")]
    [ProducesResponseType(typeof(AnalyticsResponseDto), 200)]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAnalytics([FromQuery] DateTime? createdFrom, [FromQuery] DateTime? createdTo)
    {
        var query = _context.ProjectRequests.AsQueryable();

        if (createdFrom.HasValue)
            query = query.Where(r => r.CreatedAt >= createdFrom.Value);
        if (createdTo.HasValue)
            query = query.Where(r => r.CreatedAt <= createdTo.Value);

        var totalRequests = await query.CountAsync();
        var flaggedCount = await query.CountAsync(r => r.IsFlagged);

        var byStatus = await query
            .GroupBy(r => r.Status)
            .Select(g => new StatusCountDto(g.Key.ToString(), g.Count()))
            .ToListAsync();

        var byRoomType = await query
            .GroupBy(r => r.RoomType)
            .Select(g => new RoomTypeCountDto(g.Key.ToString(), g.Count()))
            .ToListAsync();

        var budgetQuery = query.Where(r => r.Status != RequestStatus.Cancelled);
        var averageBudget = await budgetQuery.AnyAsync() ? await budgetQuery.AverageAsync(r => (decimal?)r.Budget) : null;

        var averageBudgetByRoomType = await budgetQuery
            .GroupBy(r => r.RoomType)
            .Select(g => new RoomTypeBudgetDto(g.Key.ToString(), (decimal?)g.Average(r => (decimal?)r.Budget)))
            .ToListAsync();

        // Fill in zero-count statuses and room types
        var allStatuses = Enum.GetNames<RequestStatus>();
        foreach (var status in allStatuses)
        {
            if (!byStatus.Any(s => s.Status == status))
                byStatus.Add(new StatusCountDto(status, 0));
        }

        var allRoomTypes = Enum.GetNames<RoomType>();
        foreach (var rt in allRoomTypes)
        {
            if (!byRoomType.Any(s => s.RoomType == rt))
                byRoomType.Add(new RoomTypeCountDto(rt, 0));
            
            if (!averageBudgetByRoomType.Any(s => s.RoomType == rt))
                averageBudgetByRoomType.Add(new RoomTypeBudgetDto(rt, null));
        }

        return Ok(new AnalyticsResponseDto(
            byStatus,
            byRoomType,
            averageBudget,
            averageBudgetByRoomType,
            totalRequests,
            flaggedCount
        ));
    }

    private RequestDetailDto MapToDetailDto(ProjectRequest request)
    {
        var styles = request.RequestedStyleTags ?? new List<string>();
        if (!styles.Any() && !string.IsNullOrEmpty(request.Description))
        {
            var match = System.Text.RegularExpressions.Regex.Match(request.Description, @"\[Styles:\s*([^\]]+)\]");
            if (match.Success)
            {
                styles = match.Groups[1].Value.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries).ToList();
            }
        }

        return new RequestDetailDto(
            Id: request.Id,
            ReferenceCode: request.ReferenceCode,
            ClientId: request.ClientId,
            RoomType: request.RoomType,
            RoomSizeSqFt: request.RoomSizeSqFt,
            Budget: request.Budget,
            Description: request.Description,
            Status: request.Status,
            IsFlagged: request.IsFlagged,
            FlagReason: request.FlagReason,
            RoomPhotoUrl: request.RoomPhotoUrl,
            Moodboards: request.MoodboardImages?.Select(m => new MoodboardImageDto(m.Id, m.Url, m.SortOrder)).ToList() ?? new(),
            Palette: request.SuggestedPalettes?.Select(p => new SuggestedPaletteDto(p.Id, p.Hex, p.Position, p.Source)).ToList() ?? new(),
            StatusHistory: request.StatusHistories?.OrderBy(h => h.ChangedAt).Select(h => new RequestStatusHistoryDto(h.Id, h.FromStatus, h.ToStatus, h.ChangedAt, h.Note)).ToList() ?? new(),
            CreatedAt: request.CreatedAt,
            UpdatedAt: request.UpdatedAt,
            PaletteMode: request.PaletteMode,
            PalettePresetId: request.PalettePresetId,
            PaletteBaseHex: request.PaletteBaseHex,
            RequestedStyleTags: styles,
            PreferredDesignerId: request.PreferredDesignerId,
            DesignerDisplayName: request.PreferredDesigner?.Name ?? (request.PreferredDesignerId.HasValue ? _context.Users.FirstOrDefault(u => u.Id == request.PreferredDesignerId.Value)?.Name : null),
            DesignerEmail: request.PreferredDesigner?.Email ?? (request.PreferredDesignerId.HasValue ? _context.Users.FirstOrDefault(u => u.Id == request.PreferredDesignerId.Value)?.Email : null)
        );
    }

    private void ApplyPaletteSelection(ProjectRequest request, PaletteSelectionDto? selection)
    {
        if (request.SuggestedPalettes != null && request.SuggestedPalettes.Count > 0)
        {
            _context.SuggestedPalettes.RemoveRange(request.SuggestedPalettes);
            request.SuggestedPalettes.Clear();
        }

        if (selection == null)
        {
            request.PaletteMode = null;
            request.PalettePresetId = null;
            request.PaletteBaseHex = null;
            return;
        }

        var isPreset = string.Equals(selection.Mode, "Preset", StringComparison.OrdinalIgnoreCase);
        var isGenerated = string.Equals(selection.Mode, "Generated", StringComparison.OrdinalIgnoreCase);

        request.PaletteMode = isPreset ? "Preset" : isGenerated ? "Generated" : selection.Mode;
        request.PalettePresetId = isPreset ? selection.PresetId : null;
        request.PaletteBaseHex = isGenerated ? selection.BaseColour : null;

        request.SuggestedPalettes ??= new();
        var resolved = PaletteService.Resolve(selection);
        foreach (var (hex, pos) in resolved)
        {
            var palette = new SuggestedPalette
            {
                Id = Guid.NewGuid(),
                ProjectRequestId = request.Id,
                Hex = hex,
                Position = pos,
                Source = request.PaletteMode ?? selection.Mode
            };
            request.SuggestedPalettes.Add(palette);
            _context.Entry(palette).State = EntityState.Added;
        }
    }
}
