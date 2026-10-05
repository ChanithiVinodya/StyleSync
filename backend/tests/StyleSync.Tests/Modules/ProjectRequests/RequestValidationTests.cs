using System.Collections.Generic;
using System.Linq;
using StyleSync.Api.Modules.ProjectRequests.Configuration;
using StyleSync.Api.Modules.ProjectRequests.Models.Entities;
using StyleSync.Api.Modules.ProjectRequests.Models.Enums;
using StyleSync.Api.Modules.ProjectRequests.Services;
using Xunit;

namespace StyleSync.Tests.Modules.ProjectRequests;

public class RequestValidationTests
{
    private readonly RequestValidationRules _rules;
    private readonly RequestRules _config;

    public RequestValidationTests()
    {
        _config = new RequestRules { MinBudget = 10000, MaxBudget = 10000000 };
        _rules = new RequestValidationRules(_config);
    }

    private ProjectRequest CreateValidSubmitRequest()
    {
        return new ProjectRequest
        {
            RoomType = RoomType.LivingRoom,
            RoomSizeSqFt = 500,
            Budget = 50000,
            Description = "Valid description",
            RoomPhotoUrl = "http://example.com/photo.jpg"
        };
    }

    [Theory]
    [InlineData(0, "BUDGET_NOT_POSITIVE")]
    [InlineData(-1, "BUDGET_NOT_POSITIVE")]
    [InlineData(9999, "BUDGET_BELOW_MIN")]
    [InlineData(10000001, "BUDGET_ABOVE_MAX")]
    public void ValidateSubmit_Budget_InvalidValues(decimal budget, string expectedErrorCode)
    {
        var request = CreateValidSubmitRequest();
        request.Budget = budget;

        var errors = _rules.ValidateSubmit(request);

        Assert.Contains(errors, e => e.Field == "Budget" && e.Code == expectedErrorCode);
    }

    [Theory]
    [InlineData(10000)]
    [InlineData(10000000)]
    [InlineData(50000)]
    public void ValidateSubmit_Budget_ValidValues(decimal budget)
    {
        var request = CreateValidSubmitRequest();
        request.Budget = budget;

        var errors = _rules.ValidateSubmit(request);

        Assert.DoesNotContain(errors, e => e.Field == "Budget");
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-5)]
    [InlineData(10001)]
    public void ValidateSubmit_RoomSize_InvalidValues(decimal size)
    {
        var request = CreateValidSubmitRequest();
        request.RoomSizeSqFt = size;

        var errors = _rules.ValidateSubmit(request);

        Assert.Contains(errors, e => e.Field == "RoomSizeSqFt" && e.Code == "ROOM_SIZE_INVALID");
    }

    [Theory]
    [InlineData(10000)]
    [InlineData(500)]
    public void ValidateSubmit_RoomSize_ValidValues(decimal size)
    {
        var request = CreateValidSubmitRequest();
        request.RoomSizeSqFt = size;

        var errors = _rules.ValidateSubmit(request);

        Assert.DoesNotContain(errors, e => e.Field == "RoomSizeSqFt");
    }

    [Fact]
    public void ValidateSubmit_SeveralProblems_ReturnsAllFailures()
    {
        var request = new ProjectRequest
        {
            RoomType = (RoomType)999,
            RoomSizeSqFt = 0,
            Budget = -10,
            Description = "short",
            RoomPhotoUrl = ""
        };

        var errors = _rules.ValidateSubmit(request);

        Assert.Contains(errors, e => e.Field == "RoomType" && e.Code == "ROOM_TYPE_REQUIRED");
        Assert.Contains(errors, e => e.Field == "RoomSizeSqFt" && e.Code == "ROOM_SIZE_INVALID");
        Assert.Contains(errors, e => e.Field == "Budget" && e.Code == "BUDGET_NOT_POSITIVE");
        Assert.Contains(errors, e => e.Field == "Description" && e.Code == "DESCRIPTION_INVALID_LENGTH");
        Assert.Contains(errors, e => e.Field == "RoomPhotoUrl" && e.Code == "ROOM_PHOTO_REQUIRED");

        Assert.True(errors.Count >= 5, "Expected at least 5 validation errors");
    }
}
