using System;
using System.Security.Claims;
using Microsoft.AspNetCore.Http;

namespace StyleSync.Api.Integrations
{
    public interface ICurrentUserContext
    {
        Guid? UserId { get; }
        string? Role { get; }
        string? Email { get; }
        bool IsAuthenticated { get; }
        bool IsInRole(string role);
    }

    public class HttpContextUserContext : ICurrentUserContext
    {
        private readonly IHttpContextAccessor _httpContextAccessor;

        public HttpContextUserContext(IHttpContextAccessor httpContextAccessor)
        {
            _httpContextAccessor = httpContextAccessor;
        }

        private ClaimsPrincipal? User => _httpContextAccessor.HttpContext?.User;

        public Guid? UserId
        {
            get
            {
                var idClaim = User?.FindFirst(ClaimTypes.NameIdentifier)?.Value 
                    ?? User?.FindFirst("sub")?.Value
                    ?? _httpContextAccessor.HttpContext?.Request.Headers["X-User-Id"].ToString();

                if (Guid.TryParse(idClaim, out var guid)) return guid;
                return null;
            }
        }

        public string? Role => 
            User?.FindFirst(ClaimTypes.Role)?.Value 
            ?? User?.FindFirst("role")?.Value 
            ?? _httpContextAccessor.HttpContext?.Request.Headers["X-User-Role"].ToString();

        public string? Email => 
            User?.FindFirst(ClaimTypes.Email)?.Value 
            ?? User?.FindFirst("email")?.Value;

        public bool IsAuthenticated => User?.Identity?.IsAuthenticated == true || !string.IsNullOrWhiteSpace(Role);

        public bool IsInRole(string role)
        {
            if (string.IsNullOrWhiteSpace(role)) return false;
            if (User?.IsInRole(role) == true) return true;
            return string.Equals(Role, role, StringComparison.OrdinalIgnoreCase);
        }
    }
}
