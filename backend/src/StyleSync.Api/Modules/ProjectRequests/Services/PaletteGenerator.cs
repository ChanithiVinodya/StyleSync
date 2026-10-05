using System;
using System.Globalization;

namespace StyleSync.Api.Modules.ProjectRequests.Services;

public static class PaletteGenerator
{
    public static string[] FromBase(string baseHex)
    {
        if (string.IsNullOrWhiteSpace(baseHex))
            throw new ArgumentException("Base colour is required.", nameof(baseHex));

        baseHex = baseHex.Trim().ToUpperInvariant();
        if (!baseHex.StartsWith("#"))
        {
            baseHex = "#" + baseHex;
        }

        if (baseHex.Length != 7)
            throw new ArgumentException("Base colour must be 7 characters long including #.");

        var (h, s, l) = HexToHsl(baseHex);

        var hexes = new string[5];
        
        // 0 Base: the input colour, unchanged
        hexes[0] = baseHex;

        // 1 Tint: same H and S, L = min(L + 25, 95)
        hexes[1] = HslToHex(h, s, Math.Min(l + 25, 95));

        // 2 Shade: same H and S, L = max(L - 25, 10)
        hexes[2] = HslToHex(h, s, Math.Max(l - 25, 10));

        // 3 Analogous: H = (H + 30) mod 360, same S and L
        hexes[3] = HslToHex((h + 30) % 360, s, l);

        // 4 Complement: H = (H + 180) mod 360, S = S * 0.8, same L
        hexes[4] = HslToHex((h + 180) % 360, s * 0.8, l);

        return hexes;
    }

    public static string[] Generate(string baseHex) => FromBase(baseHex); // Legacy compatibility if used

    private static (double H, double S, double L) HexToHsl(string hex)
    {
        int r = int.Parse(hex.Substring(1, 2), NumberStyles.HexNumber);
        int g = int.Parse(hex.Substring(3, 2), NumberStyles.HexNumber);
        int b = int.Parse(hex.Substring(5, 2), NumberStyles.HexNumber);

        double rf = r / 255.0;
        double gf = g / 255.0;
        double bf = b / 255.0;

        double max = Math.Max(rf, Math.Max(gf, bf));
        double min = Math.Min(rf, Math.Min(gf, bf));

        double h = 0, s = 0, l = (max + min) / 2.0;

        if (max != min)
        {
            double d = max - min;
            s = l > 0.5 ? d / (2.0 - max - min) : d / (max + min);

            if (max == rf)
                h = (gf - bf) / d + (gf < bf ? 6 : 0);
            else if (max == gf)
                h = (bf - rf) / d + 2;
            else if (max == bf)
                h = (rf - gf) / d + 4;

            h /= 6.0;
        }

        return (h * 360.0, s * 100.0, l * 100.0);
    }

    private static string HslToHex(double h, double s, double l)
    {
        double hNorm = h / 360.0;
        double sNorm = s / 100.0;
        double lNorm = l / 100.0;

        double r, g, b;

        if (sNorm == 0)
        {
            r = g = b = lNorm;
        }
        else
        {
            double q = lNorm < 0.5 ? lNorm * (1 + sNorm) : lNorm + sNorm - lNorm * sNorm;
            double p = 2 * lNorm - q;
            r = HueToRgb(p, q, hNorm + 1.0 / 3.0);
            g = HueToRgb(p, q, hNorm);
            b = HueToRgb(p, q, hNorm - 1.0 / 3.0);
        }

        return $"#{ToHex(r)}{ToHex(g)}{ToHex(b)}";
    }

    private static double HueToRgb(double p, double q, double t)
    {
        if (t < 0) t += 1;
        if (t > 1) t -= 1;
        if (t < 1.0 / 6.0) return p + (q - p) * 6.0 * t;
        if (t < 1.0 / 2.0) return q;
        if (t < 2.0 / 3.0) return p + (q - p) * (2.0 / 3.0 - t) * 6.0;
        return p;
    }

    private static string ToHex(double c)
    {
        int val = (int)Math.Round(c * 255.0, MidpointRounding.AwayFromZero);
        return Math.Clamp(val, 0, 255).ToString("X2");
    }
}
