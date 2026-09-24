using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.DTOs;

namespace StyleSync.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Client")]
public class ClientController : ControllerBase
{
    private readonly AppDbContext _context;

    public ClientController(AppDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Client-only: Get client profile.
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
    /// Client-only: Get client requests.
    /// </summary>
    [HttpGet("requests")]
    public IActionResult GetRequests()
    {
        return Ok(new[]
        {
            new { Id = Guid.NewGuid(), RoomType = "Living Room", Budget = 5000, Status = "Open" }
        });
    }

    /// <summary>
    /// Client-only: Create new design request.
    /// </summary>
    [HttpPost("requests")]
    public IActionResult CreateRequest([FromBody] dynamic requestData)
    {
        return Created("", new { Message = "Design request created successfully." });
    }
}
