using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StyleSync.Api.Common.Identity;
using StyleSync.Api.Modules.Designers.DTOs;
using StyleSync.Api.Modules.Designers.Services;

namespace StyleSync.Api.Modules.Designers.Controllers;

[ApiController]
[Route("api/[controller]")]
public class DesignersController : ControllerBase
{
    private readonly IDesignerService _designerService;

    public DesignersController(IDesignerService designerService)
    {
        _designerService = designerService;
    }

    /// <summary>
    /// Designer creates their own profile.
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "Designer,Administrator")]
    [ProducesResponseType(typeof(DesignerProfileResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> CreateProfile([FromBody] CreateDesignerProfileRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var userId = User.GetUserId();
        if (userId == null)
            return Unauthorized(new { message = "User ID could not be determined from authentication token." });

        try
        {
            var result = await _designerService.CreateProfileAsync(userId.Value, User.IsAdmin(), request);
            return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Public endpoint: returns full profile + portfolio gallery.
    /// </summary>
    [HttpGet("{id:int}")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(DesignerProfileResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(int id)
    {
        var currentUserId = User.GetUserId();
        var isAdmin = User.IsAdmin();

        // Allow owner or admin to view un-published / draft profile
        var result = await _designerService.GetProfileByIdAsync(id, includeUnpublished: isAdmin || currentUserId.HasValue);

        if (result == null)
            return NotFound(new { message = $"Designer profile with ID {id} not found." });

        // If not published and not owner/admin, hide it
        if (result.ListingStatus != Models.ListingStatus.Published && !isAdmin && result.UserId != currentUserId)
            return NotFound(new { message = $"Designer profile with ID {id} not found or not published." });

        return Ok(result);
    }

    /// <summary>
    /// Designer edits own profile; Admin can override ListingStatus and MaxConcurrentProjects.
    /// </summary>
    [HttpPut("{id:int}")]
    [Authorize(Roles = "Designer,Administrator")]
    [ProducesResponseType(typeof(DesignerProfileResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateProfile(int id, [FromBody] UpdateDesignerProfileRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var userId = User.GetUserId();
        if (userId == null)
            return Unauthorized(new { message = "User ID could not be determined from authentication token." });

        try
        {
            var result = await _designerService.UpdateProfileAsync(id, userId.Value, User.IsAdmin(), request);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new { message = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Soft delete only: Administrator sets ListingStatus = Archived.
    /// </summary>
    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Administrator")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ArchiveProfile(int id)
    {
        try
        {
            var archived = await _designerService.ArchiveProfileAsync(id, User.IsAdmin());
            if (!archived)
                return NotFound(new { message = $"Designer profile with ID {id} not found." });

            return NoContent();
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new { message = ex.Message });
        }
    }

    /// <summary>
    /// Designer adds a portfolio item to their own profile.
    /// </summary>
    [HttpPost("{id:int}/portfolio")]
    [Authorize(Roles = "Designer,Administrator")]
    [ProducesResponseType(typeof(PortfolioItemResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> AddPortfolioItem(int id, [FromBody] CreatePortfolioItemRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var userId = User.GetUserId();
        if (userId == null)
            return Unauthorized(new { message = "User ID could not be determined from authentication token." });

        try
        {
            var item = await _designerService.AddPortfolioItemAsync(id, userId.Value, User.IsAdmin(), request);
            return CreatedAtAction(nameof(GetPortfolioItems), new { id }, item);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new { message = ex.Message });
        }
    }

    /// <summary>
    /// List portfolio items for gallery view.
    /// </summary>
    [HttpGet("{id:int}/portfolio")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(List<PortfolioItemResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPortfolioItems(int id)
    {
        var currentUserId = User.GetUserId();
        var isAdmin = User.IsAdmin();

        var items = await _designerService.GetPortfolioItemsAsync(id, publicOnly: !isAdmin && !currentUserId.HasValue);
        return Ok(items);
    }

    /// <summary>
    /// Designer removes their own portfolio item.
    /// </summary>
    [HttpDelete("{id:int}/portfolio/{itemId:int}")]
    [Authorize(Roles = "Designer,Administrator")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeletePortfolioItem(int id, int itemId)
    {
        var userId = User.GetUserId();
        if (userId == null)
            return Unauthorized(new { message = "User ID could not be determined from authentication token." });

        try
        {
            var deleted = await _designerService.DeletePortfolioItemAsync(id, itemId, userId.Value, User.IsAdmin());
            if (!deleted)
                return NotFound(new { message = $"Portfolio item with ID {itemId} not found for designer {id}." });

            return NoContent();
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new { message = ex.Message });
        }
    }
}
