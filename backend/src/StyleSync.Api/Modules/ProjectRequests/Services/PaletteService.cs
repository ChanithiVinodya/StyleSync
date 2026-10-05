using System;
using System.Linq;
using System.Collections.Generic;
using StyleSync.Api.Modules.ProjectRequests.DTOs;

namespace StyleSync.Api.Modules.ProjectRequests.Services;

public class PaletteService
{
    public static List<(string Hex, int Position)> Resolve(PaletteSelectionDto selection)
    {
        var result = new List<(string Hex, int Position)>();
        
        if (selection == null) return result;

        if (string.Equals(selection.Mode, "Preset", StringComparison.OrdinalIgnoreCase))
        {
            var preset = PalettePresetCatalogue.All.FirstOrDefault(p => p.Id == selection.PresetId);
            if (preset != null)
            {
                for (int i = 0; i < preset.Colours.Length; i++)
                {
                    result.Add((preset.Colours[i], i));
                }
            }
        }
        else if (string.Equals(selection.Mode, "Generated", StringComparison.OrdinalIgnoreCase))
        {
            if (!string.IsNullOrEmpty(selection.BaseColour))
            {
                var hexes = PaletteGenerator.FromBase(selection.BaseColour);
                for (int i = 0; i < hexes.Length; i++)
                {
                    result.Add((hexes[i], i));
                }
            }
        }

        return result;
    }
}
