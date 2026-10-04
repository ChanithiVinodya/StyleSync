using System;
using System.Collections.Generic;

namespace StyleSync.Api.Modules.ProjectRequests.DTOs;

public record CancelRequestDto(string Reason);
public record FlagRequestDto(string Reason, bool IsFlagged);

/// <summary>
/// Contains aggregated analytics for Project Requests.
/// By default, all requests (including Drafts) are included in the averageBudget 
/// unless they are Cancelled.
/// </summary>
public record AnalyticsResponseDto(
    List<StatusCountDto> ByStatus,
    List<RoomTypeCountDto> ByRoomType,
    decimal? AverageBudget,
    List<RoomTypeBudgetDto> AverageBudgetByRoomType,
    int TotalRequests,
    int FlaggedCount
);

public record StatusCountDto(string Status, int Count);
public record RoomTypeCountDto(string RoomType, int Count);
public record RoomTypeBudgetDto(string RoomType, decimal? AverageBudget);
