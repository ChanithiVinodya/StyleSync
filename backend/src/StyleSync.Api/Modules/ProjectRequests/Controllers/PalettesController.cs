using System;
using System.Linq;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StyleSync.Api.Modules.ProjectRequests.Services;

namespace StyleSync.Api.Modules.ProjectRequests.Controllers;

[ApiController]
[Route("palettes")]
[Route("api/palettes")]
[Authorize]
public class PalettesController : ControllerBase
{
    /// <summary>
    /// Lists all curated preset palettes.
    /// </summary>
    /// <response code="200">Returns the list of preset palettes.</response>
    [HttpGet("presets")]
    [ProducesResponseType(typeof(System.Collections.Generic.IEnumerable<PresetPalette>), 200)]
    public IActionResult GetPresets()
    {
        return Ok(PalettePresetCatalogue.All);
    }

    /// <summary>
    /// Generates a preview of a 5-colour palette from a base hex colour.
    /// </summary>
    /// <response code="200">Returns the generated palette.</response>
    /// <response code="400">If the base colour is invalid.</response>
    [HttpGet("generate")]
    [ProducesResponseType(200)]
    [ProducesResponseType(typeof(ProblemDetails), 400)]
    public IActionResult Generate([FromQuery] string? baseColour, [FromQuery(Name = "base")] string? baseParam = null)
    {
        baseColour = baseColour ?? baseParam;
        if (string.IsNullOrWhiteSpace(baseColour))
        {
            return BadRequest(new ProblemDetails
            {
                Status = 400,
                Title = "Validation Failed",
                Extensions = { ["errors"] = new[] { new { field = "palette.baseColour", code = "PALETTE_BASE_COLOUR_INVALID", message = "Base colour is invalid." } } }
            });
        }

        baseColour = baseColour.Trim().ToUpperInvariant();
        if (!baseColour.StartsWith("#")) baseColour = "#" + baseColour;

        if (!System.Text.RegularExpressions.Regex.IsMatch(baseColour, "^#[0-9A-F]{6}$"))
        {
            return BadRequest(new ProblemDetails
            {
                Status = 400,
                Title = "Validation Failed",
                Extensions = { ["errors"] = new[] { new { field = "palette.baseColour", code = "PALETTE_BASE_COLOUR_INVALID", message = "Base colour is invalid." } } }
            });
        }

        var hexes = PaletteGenerator.Generate(baseColour);
        var colours = hexes.Select((h, i) => new { hex = h, position = i }).ToList();

        return Ok(new { baseColour, colours });
    }
}
