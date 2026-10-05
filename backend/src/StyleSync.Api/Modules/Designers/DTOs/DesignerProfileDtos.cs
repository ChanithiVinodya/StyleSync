using System;

namespace StyleSync.Api.Modules.Designers.DTOs;

public record DesignerProfileDto(
    Guid Id,
    Guid UserId,
    string Name,
    string Specialty,
    string Location,
    decimal MatchRate,
    decimal Rating,
    int Reviews,
    string About,
    string AvatarUrl,
    string CoverUrl
);

public record CreateDesignerProfileDto(
    Guid UserId,
    string Name,
    string Specialty,
    string Location,
    string About,
    string AvatarUrl,
    string CoverUrl
);

public record UpdateDesignerProfileDto(
    string Name,
    string Specialty,
    string Location,
    string About,
    string AvatarUrl,
    string CoverUrl
);
