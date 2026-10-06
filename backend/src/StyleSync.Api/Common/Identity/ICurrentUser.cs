using System;

namespace StyleSync.Api.Common.Identity;

public interface ICurrentUser
{
    Guid Id { get; }
    string Role { get; }
}
