using System;
using System.Linq;
using StyleSync.Api.Modules.ProjectRequests.Services;
using Xunit;

namespace StyleSync.Tests.Modules.ProjectRequests;

public class PaletteGeneratorTests
{
    [Fact]
    public void FromBase_GoldenCase_Red()
    {
        var result = PaletteGenerator.FromBase("#FF0000");
        Assert.Equal(new[] { "#FF0000", "#FF8080", "#800000", "#FF8000", "#19E5E6" }, result);
    }

    [Fact]
    public void FromBase_GoldenCase_Green()
    {
        var result = PaletteGenerator.FromBase("#00FF00");
        Assert.Equal(new[] { "#00FF00", "#80FF80", "#008000", "#00FF80", "#E619E5" }, result);
    }

    [Fact]
    public void FromBase_GoldenCase_Blue()
    {
        var result = PaletteGenerator.FromBase("#0000FF");
        Assert.Equal(new[] { "#0000FF", "#8080FF", "#000080", "#7F00FF", "#E5E619" }, result);
    }

    [Fact]
    public void FromBase_PropertiesOver100RandomBases()
    {
        var random = new Random(42); // Seeded for determinism

        for (int i = 0; i < 100; i++)
        {
            string hex = $"#{random.Next(0, 256):X2}{random.Next(0, 256):X2}{random.Next(0, 256):X2}";
            
            var result1 = PaletteGenerator.FromBase(hex);
            var result2 = PaletteGenerator.FromBase(hex.ToLowerInvariant());
            var result3 = PaletteGenerator.FromBase(hex.TrimStart('#'));

            Assert.Equal(5, result1.Length);

            for (int j = 0; j < 5; j++)
            {
                Assert.Matches("^#[0-9A-F]{6}$", result1[j]);
                Assert.Equal(result1[j], result2[j]);
                Assert.Equal(result1[j], result3[j]);
            }
        }
    }

    [Fact]
    public void FromBase_Achromatic_DoesNotThrow()
    {
        Assert.Equal(5, PaletteGenerator.FromBase("#000000").Length);
        Assert.Equal(5, PaletteGenerator.FromBase("#FFFFFF").Length);
        Assert.Equal(5, PaletteGenerator.FromBase("#808080").Length);
    }
}
