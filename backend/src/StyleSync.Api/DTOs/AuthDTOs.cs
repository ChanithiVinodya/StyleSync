using System.ComponentModel.DataAnnotations;
using StyleSync.Api.Common.Identity;

namespace StyleSync.Api.DTOs;

public class RegisterRequest
{
    [Required]
    [StringLength(100, MinimumLength = 2)]
    public string Name { get; set; } = string.Empty;

    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    [StringLength(100, MinimumLength = 8, ErrorMessage = "Password must be at least 8 characters.")]
    public string Password { get; set; } = string.Empty;

    [Required]
    [Compare(nameof(Password), ErrorMessage = "Passwords do not match.")]
    public string ConfirmPassword { get; set; } = string.Empty;

    public UserRole? Role { get; set; }
}

public class LoginRequest
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    public string Password { get; set; } = string.Empty;
}

public record UserResponse(
    Guid Id,
    string Name,
    string Email,
    string Role,
    bool IsActive
);

public record LoginResponse(
    string Token,
    DateTime ExpiresAt,
    UserResponse User
);

public class UpdateUserStatusRequest
{
    public bool IsActive { get; set; }
}

public class UpdateUserRoleRequest
{
    public UserRole Role { get; set; }
}

public record ErrorResponse(
    int StatusCode,
    string Message,
    string? TraceId = null
);
