using System.Linq;
using StyleSync.Api.Modules.ProjectRequests.Services;
using Xunit;

namespace StyleSync.Tests.Modules.ProjectRequests;

public class PalettePresetTests
{
    [Fact]
    public void Catalogue_ContainsExactly10Presets()
    {
        Assert.Equal(10, PalettePresetCatalogue.All.Count);
        
        var ids = PalettePresetCatalogue.All.Select(p => p.Id).ToList();
        Assert.Equal(ids.Distinct().Count(), ids.Count);

        foreach (var preset in PalettePresetCatalogue.All)
        {
            Assert.Equal(5, preset.Colours.Length);
            foreach (var col in preset.Colours)
            {
                Assert.Matches("^#[0-9A-F]{6}$", col);
            }
        }
    }
}
