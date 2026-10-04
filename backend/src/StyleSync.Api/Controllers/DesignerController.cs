using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.DTOs;

namespace StyleSync.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Designer")]
public class DesignerController : ControllerBase
{
    private readonly AppDbContext _context;

    public DesignerController(AppDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Designer-only: Get designer profile.
    /// </summary>
    [HttpGet("profile")]
    [ProducesResponseType(typeof(UserResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetProfile()
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var user = await _context.Users.FindAsync(userId);
        if (user == null) return NotFound();

        return Ok(new UserResponse(user.Id, user.Name, user.Email, user.Role.ToString(), user.IsActive));
    }

    /// <summary>
    /// Designer-only: Retrieve design requests assigned to this designer.
    /// </summary>
    [HttpGet("requests")]
    public IActionResult GetRequests()
    {
        return Ok(new[]
        {
            new { Id = Guid.NewGuid(), Title = "Modern Living Room Makeover", Status = "PendingReview", ClientName = "Sarah Jenkins" },
            new { Id = Guid.NewGuid(), Title = "Minimalist Kitchen Remodel", Status = "InProgress", ClientName = "Mark Taylor" }
        });
    }
}
