using System.Security.Claims;

namespace StyleSync.Api.Common.Identity;

public static class ClaimsPrincipalExtensions
{
    public static Guid? GetUserId(this ClaimsPrincipal principal)
    {
        var claim = principal.FindFirst(ClaimTypes.NameIdentifier) 
                    ?? principal.FindFirst("sub") 
                    ?? principal.FindFirst("userId")
                    ?? principal.FindFirst("id");

        if (claim != null && Guid.TryParse(claim.Value, out var userId))
        {
            return userId;
        }

        return null;
    }

    public static bool IsAdmin(this ClaimsPrincipal principal)
    {
        return principal.IsInRole(UserRole.Admin.ToString()) 
               || principal.IsInRole("Admin") 
               || principal.IsInRole("Administrator");
    }

    public static bool IsDesigner(this ClaimsPrincipal principal)
    {
        return principal.IsInRole(UserRole.Designer.ToString()) 
               || principal.IsInRole("Designer");
    }
}
