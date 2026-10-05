using System.Collections.Generic;

namespace StyleSync.Api.Modules.ProjectRequests.Services;

public record PresetPalette(string Id, string Name, string Mood, string[] Colours);

public static class PalettePresetCatalogue
{
    public static readonly List<PresetPalette> All = new()
    {
        new PresetPalette("warm-minimalist", "Warm Minimalist", "Warm Minimalist", new[] { "#F5EFE6", "#E4D5C3", "#C9A98A", "#8C6A4F", "#3E3A36" }),
        new PresetPalette("coastal-calm", "Coastal Calm", "Coastal Calm", new[] { "#EAF4F4", "#BFDDE0", "#7FB3C0", "#3F7C93", "#1F3B4D" }),
        new PresetPalette("scandi-light", "Scandi Light", "Scandi Light", new[] { "#FAF9F6", "#E6E2DD", "#BFC5C9", "#8A9BA8", "#2F3A45" }),
        new PresetPalette("modern-monochrome", "Modern Monochrome", "Modern Monochrome", new[] { "#FFFFFF", "#D9D9D9", "#9A9A9A", "#4D4D4D", "#121212" }),
        new PresetPalette("earthy-boho", "Earthy Boho", "Earthy Boho", new[] { "#F3E5D0", "#D9A66B", "#B5651D", "#7A8B5C", "#4A3B2A" }),
        new PresetPalette("forest-retreat", "Forest Retreat", "Forest Retreat", new[] { "#E8EFE3", "#A9C2A0", "#5E8C61", "#2F5D50", "#1B2E26" }),
        new PresetPalette("industrial-loft", "Industrial Loft", "Industrial Loft", new[] { "#E8E6E3", "#B0AAA4", "#6E6A66", "#3B3A3A", "#B4572F" }),
        new PresetPalette("soft-blush", "Soft Blush", "Soft Blush", new[] { "#FBEFEF", "#F2CFCF", "#D9A1A6", "#A86B78", "#5B3A45" }),
        new PresetPalette("midnight-luxe", "Midnight Luxe", "Midnight Luxe", new[] { "#EDEAF2", "#A9A3C0", "#5B5580", "#2B2850", "#D4AF37" }),
        new PresetPalette("sunny-mediterranean", "Sunny Mediterranean", "Sunny Mediterranean", new[] { "#FFF6E0", "#F4D58D", "#E07A5F", "#3D5A80", "#2A6F97" })
    };
}
