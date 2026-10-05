using StyleSync.Api.Common.Identity;
using StyleSync.Api.DTOs;

namespace StyleSync.Api.Services;

public interface IJwtService
{
    LoginResponse GenerateToken(AppUser user);
}
