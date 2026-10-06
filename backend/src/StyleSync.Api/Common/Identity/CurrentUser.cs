using System;
using System.Security.Claims;
using Microsoft.AspNetCore.Http;

namespace StyleSync.Api.Common.Identity;

public class CurrentUser : ICurrentUser
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public CurrentUser(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public Guid Id 
    {
        get
        {
            var user = _httpContextAccessor.HttpContext?.User;
            var idClaim = user?.FindFirst(ClaimTypes.NameIdentifier)?.Value
                ?? user?.FindFirst("sub")?.Value
                ?? user?.FindFirst("id")?.Value
                ?? user?.FindFirst("userId")?.Value;

            if (idClaim != null && Guid.TryParse(idClaim, out var guid))
            {
                return guid;
            }
            return Guid.Empty;
        }
    }
    
    public string Role
    {
        get
        {
            var user = _httpContextAccessor.HttpContext?.User;
            return user?.FindFirst(ClaimTypes.Role)?.Value 
                ?? user?.FindFirst("role")?.Value 
                ?? string.Empty;
        }
    }
}
