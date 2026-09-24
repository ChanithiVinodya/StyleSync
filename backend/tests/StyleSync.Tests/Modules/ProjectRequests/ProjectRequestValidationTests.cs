using System.ComponentModel.DataAnnotations;
using StyleSync.Api.Modules.ProjectRequests.DTOs;
using StyleSync.Api.Modules.ProjectRequests.Models;
using Xunit;

namespace StyleSync.Tests.Modules.ProjectRequests;

/// <summary>
/// Unit tests for ProjectRequest DTO validation rules.
/// These tests run without a database or HTTP stack — pure in-process validation.
/// </summary>
public class ProjectRequestValidationTests
{
    // ─── Helper ───────────────────────────────────────────────────────────────

    private static IList<ValidationResult> Validate(object model)
    {
        var ctx = new ValidationContext(model);
        var results = new List<ValidationResult>();
        Validator.TryValidateObject(model, ctx, results, validateAllProperties: true);
        return results;
    }

    // ─── CreateProjectRequestDto ──────────────────────────────────────────────

    [Fact]
    public void CreateDto_ValidPayload_PassesValidation()
    {
        var dto = new CreateProjectRequestDto
        {
            Title = "Modern Living Room Redesign",
            Description = "Complete redesign of a 30 sqm living room with Japandi aesthetic and neutral tones.",
            RoomType = RoomType.LivingRoom,
            BudgetMin = 50_000m,
            BudgetMax = 150_000m
        };

        var errors = Validate(dto);
        Assert.Empty(errors);
    }

    [Fact]
    public void CreateDto_MissingTitle_FailsValidation()
    {
        var dto = new CreateProjectRequestDto
        {
            Title = "",
            Description = "Some description that is long enough to pass the minimum length check here.",
            RoomType = RoomType.Bedroom
        };

        var errors = Validate(dto);
        Assert.Contains(errors, e => e.MemberNames.Contains(nameof(CreateProjectRequestDto.Title)));
    }

    [Fact]
    public void CreateDto_TitleTooShort_FailsValidation()
    {
        var dto = new CreateProjectRequestDto
        {
            Title = "Hi",   // less than 5 chars
            Description = "Some description that is long enough to pass the minimum length check here.",
            RoomType = RoomType.Kitchen
        };

        var errors = Validate(dto);
        Assert.Contains(errors, e => e.MemberNames.Contains(nameof(CreateProjectRequestDto.Title)));
    }

    [Fact]
    public void CreateDto_DescriptionTooShort_FailsValidation()
    {
        var dto = new CreateProjectRequestDto
        {
            Title = "Valid Title Here",
            Description = "Too short",   // less than 20 chars
            RoomType = RoomType.Office
        };

        var errors = Validate(dto);
        Assert.Contains(errors, e => e.MemberNames.Contains(nameof(CreateProjectRequestDto.Description)));
    }

    [Fact]
    public void CreateDto_NegativeBudget_FailsValidation()
    {
        var dto = new CreateProjectRequestDto
        {
            Title = "Coastal Bedroom Transformation",
            Description = "Full coastal bedroom redesign with natural materials and a calming sea-inspired palette.",
            RoomType = RoomType.Bedroom,
            BudgetMin = -1000m
        };

        var errors = Validate(dto);
        Assert.Contains(errors, e => e.MemberNames.Contains(nameof(CreateProjectRequestDto.BudgetMin)));
    }

    // ─── RejectProjectRequestDto ──────────────────────────────────────────────

    [Fact]
    public void RejectDto_EmptyReason_FailsValidation()
    {
        var dto = new RejectProjectRequestDto { RejectionReason = "" };

        var errors = Validate(dto);
        Assert.Contains(errors, e => e.MemberNames.Contains(nameof(RejectProjectRequestDto.RejectionReason)));
    }

    [Fact]
    public void RejectDto_ReasonTooShort_FailsValidation()
    {
        var dto = new RejectProjectRequestDto { RejectionReason = "No" }; // < 10 chars

        var errors = Validate(dto);
        Assert.Contains(errors, e => e.MemberNames.Contains(nameof(RejectProjectRequestDto.RejectionReason)));
    }

    [Fact]
    public void RejectDto_ValidReason_PassesValidation()
    {
        var dto = new RejectProjectRequestDto
        {
            RejectionReason = "The requested budget is insufficient for the scope described."
        };

        var errors = Validate(dto);
        Assert.Empty(errors);
    }
}
