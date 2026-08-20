using StyleSync.Api.Common.Shared;

namespace StyleSync.Api.Common.Identity;

/// <summary>
/// Shared user entity. Auth/roles are a compulsory baseline requirement,
/// not one of the 4 owned business components - treat this file as jointly owned.
/// If you need to extend it, add a module-specific "profile" entity (e.g. DesignerProfile)
/// that references UserId, rather than editing this class.
/// </summary>
public class AppUser : BaseEntity
{
    public string Email { get; set; } = default!;
    public string PasswordHash { get; set; } = default!;
    public string FullName { get; set; } = default!;
    public UserRole Role { get; set; }
    public bool IsActive { get; set; } = true;
}

public enum UserRole
{
    Client = 0,
    Designer = 1,
    ProjectManager = 2,
    Administrator = 3
}
