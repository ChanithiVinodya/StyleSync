using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Identity;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.DTOs;

namespace StyleSync.Api.Services;

public class AuthService : IAuthService
{
    private readonly AppDbContext _context;
    private readonly IPasswordHasher<AppUser> _passwordHasher;
    private readonly IJwtService _jwtService;

    public AuthService(
        AppDbContext context,
        IPasswordHasher<AppUser> passwordHasher,
        IJwtService jwtService)
    {
        _context = context;
        _passwordHasher = passwordHasher;
        _jwtService = jwtService;
    }

    public async Task<UserResponse> RegisterAsync(RegisterRequest request)
    {
        // 1. Rule: Public users must NOT be allowed to register as Admin
        if (request.Role == UserRole.Admin)
        {
            throw new BadHttpRequestException("Public registration as Admin is strictly forbidden.");
        }

        // 2. Validate email uniqueness
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();
        var emailExists = await _context.Users.AnyAsync(u => u.Email.ToLower() == normalizedEmail);
        if (emailExists)
        {
            throw new InvalidOperationException("Email address is already registered.");
        }

        // 3. Assign role (Client by default, or Designer if selected)
        var role = request.Role ?? UserRole.Client;

        // 4. Create AppUser instance
        var user = new AppUser
        {
            Id = Guid.NewGuid(),
            Name = request.Name.Trim(),
            Email = normalizedEmail,
            Role = role,
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        // 5. Hash password
        user.PasswordHash = _passwordHasher.HashPassword(user, request.Password);

        // 6. Save to DB
        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        return new UserResponse(
            user.Id,
            user.Name,
            user.Email,
            user.Role.ToString(),
            user.IsActive
        );
    }

    public async Task<LoginResponse> LoginAsync(LoginRequest request)
    {
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == normalizedEmail);

        // Generic error message to prevent email enumeration
        const string invalidCredentialsMsg = "Invalid email or password.";

        if (user == null)
        {
            throw new UnauthorizedAccessException(invalidCredentialsMsg);
        }

        if (!user.IsActive)
        {
            throw new UnauthorizedAccessException("Account is disabled. Please contact system administrator.");
        }

        var verificationResult = _passwordHasher.VerifyHashedPassword(user, user.PasswordHash, request.Password);
        if (verificationResult == PasswordVerificationResult.Failed)
        {
            throw new UnauthorizedAccessException(invalidCredentialsMsg);
        }

        // Generate JWT token
        return _jwtService.GenerateToken(user);
    }

    public async Task<UserResponse> GetMeAsync(Guid userId)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null || !user.IsActive)
        {
            throw new KeyNotFoundException("User not found or inactive.");
        }

        return new UserResponse(
            user.Id,
            user.Name,
            user.Email,
            user.Role.ToString(),
            user.IsActive
        );
    }
}
