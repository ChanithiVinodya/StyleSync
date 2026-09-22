using System.Security.Claims;

namespace StyleSync.Api.Common.Identity;

public static class ClaimsPrincipalExtensions
{
    public static int? GetUserId(this ClaimsPrincipal principal)
    {
        var claim = principal.FindFirst(ClaimTypes.NameIdentifier) 
                    ?? principal.FindFirst("sub") 
                    ?? principal.FindFirst("userId")
                    ?? principal.FindFirst("id");

        if (claim != null && int.TryParse(claim.Value, out var userId))
        {
            return userId;
        }

        return null;
    }

    public static bool IsAdmin(this ClaimsPrincipal principal)
    {
        return principal.IsInRole(UserRole.Administrator.ToString()) 
               || principal.IsInRole("Administrator") 
               || principal.IsInRole("Admin");
    }

    public static bool IsDesigner(this ClaimsPrincipal principal)
    {
        return principal.IsInRole(UserRole.Designer.ToString()) 
               || principal.IsInRole("Designer");
    }
}
