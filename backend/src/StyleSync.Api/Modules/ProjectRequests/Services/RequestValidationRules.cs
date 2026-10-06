using System;
using System.Collections.Generic;
using StyleSync.Api.Modules.ProjectRequests.Configuration;
using StyleSync.Api.Modules.ProjectRequests.Models.Entities;
using StyleSync.Api.Modules.ProjectRequests.Models.Enums;

namespace StyleSync.Api.Modules.ProjectRequests.Services;

public record ValidationError(string Field, string Code, string Message);

public class RequestValidationRules
{
    private readonly RequestRules _rulesConfig;

    public RequestValidationRules(RequestRules rulesConfig)
    {
        _rulesConfig = rulesConfig ?? new RequestRules();
    }

    public List<ValidationError> ValidateDraft(ProjectRequest request)
    {
        var errors = new List<ValidationError>();

        if (!Enum.IsDefined(typeof(RoomType), request.RoomType))
        {
            errors.Add(new ValidationError("RoomType", "ROOM_TYPE_INVALID", "Invalid room type."));
        }

        if (request.Budget < 0)
        {
            errors.Add(new ValidationError("Budget", "BUDGET_NOT_POSITIVE", "Budget must be positive if provided."));
        }

        if (request.RoomSizeSqFt < 0 || request.RoomSizeSqFt > 10000)
        {
            errors.Add(new ValidationError("RoomSizeSqFt", "ROOM_SIZE_INVALID", "Length and width must produce a room size > 0 and <= 10000 sq ft if provided."));
        }

        if (!string.IsNullOrEmpty(request.Description) && request.Description.Length > 2000)
        {
            errors.Add(new ValidationError("Description", "DESCRIPTION_INVALID_LENGTH", "Description cannot exceed 2000 characters."));
        }

        ValidatePalette(request, errors);

        return errors;
    }

    private void ValidatePalette(ProjectRequest request, List<ValidationError> errors)
    {
        if (request.PaletteMode == null && request.PalettePresetId == null && request.PaletteBaseHex == null)
            return;

        if (string.Equals(request.PaletteMode, "Preset", StringComparison.OrdinalIgnoreCase))
        {
            if (string.IsNullOrEmpty(request.PalettePresetId) || !StyleSync.Api.Modules.ProjectRequests.Services.PalettePresetCatalogue.All.Any(p => p.Id == request.PalettePresetId))
            {
                errors.Add(new ValidationError("palette.presetId", "PALETTE_PRESET_UNKNOWN", "Preset ID is invalid or missing."));
            }
        }
        else if (string.Equals(request.PaletteMode, "Generated", StringComparison.OrdinalIgnoreCase))
        {
            if (string.IsNullOrEmpty(request.PaletteBaseHex) || !System.Text.RegularExpressions.Regex.IsMatch(request.PaletteBaseHex, "^#?[0-9A-Fa-f]{6}$"))
            {
                errors.Add(new ValidationError("palette.baseColour", "PALETTE_BASE_COLOUR_INVALID", "Base colour is invalid."));
            }
        }
        else
        {
            errors.Add(new ValidationError("palette.mode", "PALETTE_MODE_INVALID", "Palette mode must be Preset or Generated."));
        }
    }

    public List<ValidationError> ValidateSubmit(ProjectRequest request)
    {
        var errors = new List<ValidationError>();

        if (!Enum.IsDefined(typeof(RoomType), request.RoomType))
        {
            errors.Add(new ValidationError("RoomType", "ROOM_TYPE_REQUIRED", "Room type is required."));
        }

        if (request.RoomSizeSqFt <= 0 || request.RoomSizeSqFt > 10000)
        {
            errors.Add(new ValidationError("RoomSizeSqFt", "ROOM_SIZE_INVALID", "Length, width, and height are required: length and width must produce a room size > 0 and <= 10000 sq ft."));
        }

        if (request.Budget <= 0)
        {
            errors.Add(new ValidationError("Budget", "BUDGET_NOT_POSITIVE", "Budget must be positive."));
        }
        else if (request.Budget < _rulesConfig.MinBudget)
        {
            errors.Add(new ValidationError("Budget", "BUDGET_BELOW_MIN", $"Budget cannot be less than {_rulesConfig.MinBudget}."));
        }
        else if (request.Budget > _rulesConfig.MaxBudget)
        {
            errors.Add(new ValidationError("Budget", "BUDGET_ABOVE_MAX", $"Budget cannot exceed {_rulesConfig.MaxBudget}."));
        }

        if (string.IsNullOrWhiteSpace(request.Description) || request.Description.Length < 10 || request.Description.Length > 2000)
        {
            errors.Add(new ValidationError("Description", "DESCRIPTION_INVALID_LENGTH", "Description must be between 10 and 2000 characters."));
        }

        if (string.IsNullOrWhiteSpace(request.RoomPhotoUrl))
        {
            errors.Add(new ValidationError("RoomPhotoUrl", "ROOM_PHOTO_REQUIRED", "Exactly one room photo is required."));
        }

        return errors;
    }
}
