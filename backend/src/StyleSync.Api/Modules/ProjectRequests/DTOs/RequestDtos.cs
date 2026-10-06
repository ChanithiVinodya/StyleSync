using System;
using System.Collections.Generic;
using StyleSync.Api.Modules.ProjectRequests.Models.Enums;

namespace StyleSync.Api.Modules.ProjectRequests.DTOs;

public record PaletteSelectionDto(string Mode, string? PresetId, string? BaseColour);

public record CreateRequestDto(
    RoomType? RoomType,
    decimal? RoomSizeSqFt,
    decimal? Budget,
    string? Description,
    PaletteSelectionDto? Palette,
    decimal? RoomSizeSqM = null,
    List<string>? RequestedStyleTags = null,
    Guid? PreferredDesignerId = null
);

public record UpdateRequestDto(
    RoomType? RoomType,
    decimal? RoomSizeSqFt,
    decimal? Budget,
    string? Description,
    PaletteSelectionDto? Palette,
    decimal? RoomSizeSqM = null,
    List<string>? RequestedStyleTags = null,
    Guid? PreferredDesignerId = null
);

public record RequestSummaryDto(
    Guid Id,
    string ReferenceCode,
    RoomType RoomType,
    decimal Budget,
    RequestStatus Status,
    bool IsFlagged,
    DateTime CreatedAt,
    DateTime UpdatedAt,
    string? RoomPhotoUrl,
    string? ClientDisplayName
);

public record MoodboardImageDto(Guid Id, string Url, int SortOrder);
public record SuggestedPaletteDto(Guid Id, string Hex, int Position, string Source);
public record RequestStatusHistoryDto(Guid Id, RequestStatus? FromStatus, RequestStatus ToStatus, DateTime ChangedAt, string? Note);

public record RequestDetailDto(
    Guid Id,
    string ReferenceCode,
    Guid ClientId,
    RoomType RoomType,
    decimal RoomSizeSqFt,
    decimal Budget,
    string Description,
    RequestStatus Status,
    bool IsFlagged,
    string? FlagReason,
    string? RoomPhotoUrl,
    List<MoodboardImageDto> Moodboards,
    List<SuggestedPaletteDto> Palette,
    List<RequestStatusHistoryDto> StatusHistory,
    DateTime CreatedAt,
    DateTime UpdatedAt,
    string? PaletteMode,
    string? PalettePresetId,
    string? PaletteBaseHex,
    List<string> RequestedStyleTags,
    Guid? PreferredDesignerId,
    string? DesignerDisplayName = null,
    string? DesignerEmail = null
);

public record AssignDesignerDto(Guid DesignerId);

public record PagedResult<T>(
    List<T> Items,
    int Page,
    int PageSize,
    int TotalCount,
    int TotalPages
);
