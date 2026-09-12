using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Moq;
using StyleSync.Backend.Data;
using StyleSync.Backend.Domain.Enums;
using StyleSync.Backend.DTOs;
using StyleSync.Backend.Services;
using Xunit;

namespace StyleSync.Backend.Tests;

public class ProjectRequestServiceTests
{
    private StyleSyncDbContext GetInMemoryDbContext()
    {
        var options = new DbContextOptionsBuilder<StyleSyncDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
        return new StyleSyncDbContext(options);
    }

    [Fact]
    public async Task CreateRequestAsync_ShouldSaveDraftRequest_Successfully()
    {
        // Arrange
        var db = GetInMemoryDbContext();
        var mockStorage = new Mock<IPhotoStorageService>();
        var mockAi = new Mock<IAIServiceClient>();
        var mockLogger = new Mock<ILogger<ProjectRequestService>>();

        var service = new ProjectRequestService(db, mockStorage.Object, mockAi.Object, mockLogger.Object);

        var dto = new CreateProjectRequestDto(
            RoomType: "Bedroom",
            LengthFeet: 15,
            WidthFeet: 12,
            HeightFeet: 10,
            BudgetLkr: 250000,
            PreferredStyles: new List<string> { "Modern", "Minimalist" },
            Description: "Simple and light colors",
            SubmitImmediately: false
        );

        // Act
        var result = await service.CreateRequestAsync(dto, "client-nimali");

        // Assert
        Assert.NotNull(result);
        Assert.Equal("Bedroom", result.RoomType);
        Assert.Equal(250000, result.BudgetLkr);
        Assert.Equal("Draft", result.Status);
        Assert.Equal("client-nimali", result.ClientId);
    }

    [Fact]
    public async Task SubmitRequestForAIAnalysisAsync_ShouldInvokeAIClient_AndUpdateStatusToProposalReady()
    {
        // Arrange
        var db = GetInMemoryDbContext();
        var mockStorage = new Mock<IPhotoStorageService>();
        var mockAi = new Mock<IAIServiceClient>();
        var mockLogger = new Mock<ILogger<ProjectRequestService>>();

        mockAi.Setup(a => a.AnalyzeStyleAsync(It.IsAny<AIStyleAnalysisRequestDto>()))
            .ReturnsAsync(new AIStyleAnalysisResponseDto(
                PrimaryStyle: "Modern",
                SecondaryStyle: "Minimalist",
                ConfidenceScore: 92.5,
                RecommendedColors: new List<string> { "White", "Light Brown" },
                DetectedFeatures: new List<string> { "Clean Lines", "Spacious Layout" },
                AnalysisSummary: "Modern minimalist design matches perfectly.",
                ConceptRenderUrl: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=1000&auto=format&fit=crop"
            ));

        var service = new ProjectRequestService(db, mockStorage.Object, mockAi.Object, mockLogger.Object);

        var dto = new CreateProjectRequestDto("Living Room", 20, 15, 10, 350000, new List<string> { "Modern" }, "Spacious living room", false);
        var created = await service.CreateRequestAsync(dto, "client-1");

        // Act
        var result = await service.SubmitRequestForAIAnalysisAsync(created.Id);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("ProposalReady", result.Status);
        Assert.NotNull(result.StyleAnalysis);
        Assert.Equal("Modern", result.StyleAnalysis.PrimaryStyle);
        Assert.Equal(92.5, result.StyleAnalysis.ConfidenceScore);
        // Node 2 (generate_concept_render_node) output: verify concept_render_url is returned
        Assert.NotNull(result.StyleAnalysis.ConceptRenderUrl);
        Assert.NotEmpty(result.StyleAnalysis.ConceptRenderUrl);
        Assert.StartsWith("http", result.StyleAnalysis.ConceptRenderUrl);
    }

    [Fact]
    public async Task UpdateRequestAsync_ShouldThrowInvalidOperationException_WhenStatusIsNotDraft()
    {
        // Arrange
        var db = GetInMemoryDbContext();
        var mockStorage = new Mock<IPhotoStorageService>();
        var mockAi = new Mock<IAIServiceClient>();
        var mockLogger = new Mock<ILogger<ProjectRequestService>>();

        mockAi.Setup(a => a.AnalyzeStyleAsync(It.IsAny<AIStyleAnalysisRequestDto>()))
            .ReturnsAsync(new AIStyleAnalysisResponseDto("Modern", "Minimalist", 90, new(), new(), "Summary", "https://example.com/c.jpg"));

        var service = new ProjectRequestService(db, mockStorage.Object, mockAi.Object, mockLogger.Object);

        var dto = new CreateProjectRequestDto("Bedroom", 10, 10, 8, 150000, new List<string> { "Luxury" }, "Luxury room", true);
        var created = await service.CreateRequestAsync(dto, "client-1");

        // Act & Assert (Status is ProposalReady after immediate submit)
        var updateDto = new UpdateProjectRequestDto("Master Bedroom", 12, 12, 9, 200000, new List<string> { "Luxury" }, "Updated");
        var ex = await Assert.ThrowsAsync<InvalidOperationException>(() => service.UpdateRequestAsync(created.Id, updateDto, "client-1"));
        Assert.Contains("Only Draft requests can be modified", ex.Message);
    }

    [Fact]
    public async Task DeleteRequestAsync_ShouldThrowInvalidOperationException_WhenStatusIsNotDraft()
    {
        // Arrange
        var db = GetInMemoryDbContext();
        var mockStorage = new Mock<IPhotoStorageService>();
        var mockAi = new Mock<IAIServiceClient>();
        var mockLogger = new Mock<ILogger<ProjectRequestService>>();

        mockAi.Setup(a => a.AnalyzeStyleAsync(It.IsAny<AIStyleAnalysisRequestDto>()))
            .ReturnsAsync(new AIStyleAnalysisResponseDto("Modern", "Minimalist", 90, new(), new(), "Summary", "https://example.com/c.jpg"));

        var service = new ProjectRequestService(db, mockStorage.Object, mockAi.Object, mockLogger.Object);

        var dto = new CreateProjectRequestDto("Kitchen", 12, 10, 9, 180000, new List<string> { "Industrial" }, "Kitchen redesign", true);
        var created = await service.CreateRequestAsync(dto, "client-1");

        // Act & Assert (Status is ProposalReady after immediate submit)
        var ex = await Assert.ThrowsAsync<InvalidOperationException>(() => service.DeleteRequestAsync(created.Id, "client-1"));
        Assert.Contains("Only Draft requests can be deleted", ex.Message);
    }

    [Fact]
    public async Task DeleteRequestAsync_ShouldSuccessfullySoftDelete_WhenStatusIsDraft()
    {
        // Arrange
        var db = GetInMemoryDbContext();
        var mockStorage = new Mock<IPhotoStorageService>();
        var mockAi = new Mock<IAIServiceClient>();
        var mockLogger = new Mock<ILogger<ProjectRequestService>>();

        var service = new ProjectRequestService(db, mockStorage.Object, mockAi.Object, mockLogger.Object);

        var dto = new CreateProjectRequestDto("Home Office", 10, 10, 8, 120000, new List<string> { "Modern" }, "Work space", false);
        var created = await service.CreateRequestAsync(dto, "client-1");

        // Act
        var deleted = await service.DeleteRequestAsync(created.Id, "client-1");

        // Assert
        Assert.True(deleted);
        var fetched = await service.GetRequestByIdAsync(created.Id);
        Assert.Null(fetched); // Query filter excludes deleted requests
    }
}
