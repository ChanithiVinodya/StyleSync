using StyleSync.Api.DTOs;

namespace StyleSync.Api.Services;

public interface IAuthService
{
    Task<UserResponse> RegisterAsync(RegisterRequest request);
    Task<LoginResponse> LoginAsync(LoginRequest request);
    Task<UserResponse> GetMeAsync(Guid userId);
}
