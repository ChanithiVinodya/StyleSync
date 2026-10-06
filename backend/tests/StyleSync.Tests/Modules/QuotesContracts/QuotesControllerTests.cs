using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Json;
using System.Security.Claims;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using StyleSync.Api.Controllers;
using StyleSync.Api.Data;
using StyleSync.Api.DTOs;
using StyleSync.Api.Integrations;
using StyleSync.Api.Models;
using StyleSync.Api.Services;
using Xunit;

namespace StyleSync.Tests.Modules.QuotesContracts
{
    public class MockUserContext : ICurrentUserContext
    {
        public Guid? UserId { get; set; } = Guid.NewGuid();
        public string? Role { get; set; } = "Admin";
        public string? Email { get; set; } = "admin@stylesync.lk";
        public bool IsAuthenticated => true;

        public bool IsInRole(string role)
        {
            return string.Equals(Role, role, StringComparison.OrdinalIgnoreCase);
        }
    }

    public class QuotesControllerTests
    {
        private AppDbContext CreateInMemoryDbContext()
        {
            var options = new DbContextOptionsBuilder<AppDbContext>()
                .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
                .Options;

            return new AppDbContext(options);
        }

        private (QuotesController Controller, AppDbContext Db, StubProjectRequestProvider RequestProvider, MockUserContext UserContext) CreateTestController(
            AppDbContext? db = null,
            string role = "Admin")
        {
            var context = db ?? CreateInMemoryDbContext();
            var engine = new QuotationEngine();
            var guard = new BudgetGuard();
            var inMemoryConfig = new Dictionary<string, string?> { { "INTEGRATION_MODE", "stub" } };
            var config = new ConfigurationBuilder().AddInMemoryCollection(inMemoryConfig).Build();
            var scopeSource = new AiScopeSourceAdapter(new MockHttpClientFactory(new HttpClient()), config);
            var requestProvider = new StubProjectRequestProvider();
            var userContext = new MockUserContext { Role = role };
            var gateResumer = new LangGraphApprovalGateResumer(NullLogger<LangGraphApprovalGateResumer>.Instance);
            var exportService = new QuoteExportService();

            var controller = new QuotesController(
                context,
                engine,
                guard,
                scopeSource,
                requestProvider,
                userContext,
                gateResumer,
                exportService
            );

            return (controller, context, requestProvider, userContext);
        }

        [Fact]
        public void QuotationEngine_CalculatesBreakdown_WithDecimalPrecision()
        {
            var engine = new QuotationEngine();
            var items = new List<QuoteItemDto>
            {
                new() { Description = "Wall Paint", Category = QuoteItemCategory.Materials, Quantity = 2, UnitCost = 25000m }, // 50,000
                new() { Description = "Carpentry Labor", Category = QuoteItemCategory.Labor, Quantity = 1, UnitCost = 30000m }, // 30,000
                new() { Description = "Design Consultation", Category = QuoteItemCategory.Design, Quantity = 1, UnitCost = 15000m } // 15,000
            };

            var result = engine.Calculate(items);

            Assert.Equal(50000m, result.MaterialsSubtotal);
            Assert.Equal(30000m, result.LaborSubtotal);
            Assert.Equal(15000m, result.DesignFee);

            // Subtotal = 50k + 30k + 15k = 95,000
            // Contingency 5% = 4,750
            // Taxable = 99,750
            // Tax 8% = 7,980
            // Total = 107,730
            Assert.Equal(4750m, result.ContingencyAmount);
            Assert.Equal(7980m, result.TaxAmount);
            Assert.Equal(107730m, result.TotalCost);
        }

        [Fact]
        public void BudgetGuard_WhenOverBudget_FailsValidationWithClearError()
        {
            var engine = new QuotationEngine();
            var guard = new BudgetGuard();

            var items = new List<QuoteItemDto>
            {
                new() { Description = "Luxury Marble", Category = QuoteItemCategory.Materials, Quantity = 1, UnitCost = 500000m }
            };

            var calculation = engine.Calculate(items);
            decimal maxBudget = 200000m; // Over budget

            var result = guard.Validate(calculation, maxBudget);

            Assert.False(result.IsValid);
            Assert.NotEmpty(result.Errors);
            Assert.Contains("exceeds client max budget", result.Errors.First());
        }

        [Fact]
        public async Task CreateDraftFromAiScope_CreatesQuoteWithQuoteVersionV1()
        {
            var (controller, db, requestProvider, _) = CreateTestController();
            var requestId = Guid.NewGuid();

            requestProvider.RegisterStubRequest(new ProjectRequestDetails(
                RequestId: requestId,
                ClientId: Guid.NewGuid(),
                ClientName: "Test Client",
                ClientEmail: "client@test.lk",
                MaxBudget: 500000m,
                AssignedDesignerId: Guid.NewGuid(),
                RoomType: "Living room",
                RoomSizeSqft: 200,
                StyleProfile: "Minimalist"
            ));

            var dto = new CreateDraftFromAiScopeDto
            {
                ScopeSummary = "Modern Living Room Concept",
                Items = new List<QuoteItemDto>
                {
                    new() { Description = "Custom Sofa", Category = QuoteItemCategory.Furniture, Quantity = 1, UnitCost = 100000m },
                    new() { Description = "Installation Labor", Category = QuoteItemCategory.Labor, Quantity = 1, UnitCost = 50000m }
                }
            };

            var actionResult = await controller.CreateDraftFromAiScope(requestId, dto);
            var createdResult = Assert.IsType<CreatedAtActionResult>(actionResult.Result);
            var response = Assert.IsType<QuoteResponseDto>(createdResult.Value);

            Assert.Equal(QuoteStatus.Stage1Pending, response.Status);
            Assert.True(response.IsAiGenerated);
            Assert.NotNull(response.CurrentVersion);
            Assert.Equal(1, response.CurrentVersion.VersionNumber);
            Assert.Equal(1, response.Versions.Count);

            // DB verification
            var savedQuote = await db.Quotes.Include(q => q.Versions).FirstOrDefaultAsync(q => q.Id == response.Id);
            Assert.NotNull(savedQuote);
            Assert.Single(savedQuote.Versions);
            Assert.Equal(1, savedQuote.Versions.First().VersionNumber);
        }

        [Fact]
        public async Task Revise_CreatesNewImmutableQuoteVersionAndDoesNotOverwritePrior()
        {
            var (controller, db, requestProvider, _) = CreateTestController(role: "Designer");
            var requestId = Guid.NewGuid();

            requestProvider.RegisterStubRequest(new ProjectRequestDetails(
                RequestId: requestId,
                ClientId: Guid.NewGuid(),
                ClientName: "Client A",
                ClientEmail: "a@test.lk",
                MaxBudget: 600000m,
                AssignedDesignerId: Guid.NewGuid(),
                RoomType: "Bedroom",
                RoomSizeSqft: 150,
                StyleProfile: "Modern"
            ));

            // Create initial quote v1
            var createResult = await controller.CreateDraftFromAiScope(requestId, new CreateDraftFromAiScopeDto
            {
                ScopeSummary = "Initial Scope",
                Items = new List<QuoteItemDto>
                {
                    new() { Description = "Initial Item", Category = QuoteItemCategory.Materials, Quantity = 1, UnitCost = 80000m }
                }
            });

            var initialQuote = (QuoteResponseDto)((CreatedAtActionResult)createResult.Result!).Value!;
            var quoteId = initialQuote.Id;

            // Revise to create v2
            var reviseDto = new ReviseQuoteDto
            {
                ScopeSummary = "Designer Revised Scope",
                Notes = "Added acoustic paneling",
                Items = new List<QuoteItemDto>
                {
                    new() { Description = "Initial Item", Category = QuoteItemCategory.Materials, Quantity = 1, UnitCost = 80000m },
                    new() { Description = "Acoustic Wood Paneling", Category = QuoteItemCategory.Materials, Quantity = 1, UnitCost = 50000m },
                    new() { Description = "Carpentry Labor", Category = QuoteItemCategory.Labor, Quantity = 1, UnitCost = 30000m }
                }
            };

            var reviseResult = await controller.Revise(quoteId, reviseDto);
            var okResult = Assert.IsType<OkObjectResult>(reviseResult.Result);
            var revisedQuote = Assert.IsType<QuoteResponseDto>(okResult.Value);

            Assert.False(revisedQuote.IsAiGenerated);
            Assert.Equal(2, revisedQuote.Versions.Count);
            Assert.Equal(2, revisedQuote.CurrentVersion!.VersionNumber);

            // Verify both v1 and v2 exist in DB immutably
            var dbQuote = await db.Quotes.Include(q => q.Versions).ThenInclude(v => v.Items).FirstOrDefaultAsync(q => q.Id == quoteId);
            Assert.NotNull(dbQuote);
            Assert.Equal(2, dbQuote.Versions.Count);
            var v1 = dbQuote.Versions.First(v => v.VersionNumber == 1);
            var v2 = dbQuote.Versions.First(v => v.VersionNumber == 2);
            Assert.NotEqual(v1.TotalCost, v2.TotalCost);
            Assert.Single(v1.Items);
            Assert.Equal(3, v2.Items.Count);
        }

        [Fact]
        public async Task Stage1Decision_Release_MovesStatusToStage1Released()
        {
            var (controller, db, _, _) = CreateTestController(role: "Admin");
            var quoteId = Guid.NewGuid();

            var quote = new Quote
            {
                Id = quoteId,
                ProjectRequestId = Guid.NewGuid(),
                DesignerId = Guid.NewGuid(),
                Status = QuoteStatus.Stage1Pending,
                ScopeSummary = "Stage 1 Candidate",
                TotalCost = 150000m
            };
            db.Quotes.Add(quote);
            await db.SaveChangesAsync();

            var decisionDto = new Stage1DecisionDto
            {
                Action = Stage1Action.Release,
                Notes = "Approved by Admin for client presentation."
            };

            var result = await controller.Stage1Decision(quoteId, decisionDto);
            var okResult = Assert.IsType<OkObjectResult>(result.Result);
            var response = Assert.IsType<QuoteResponseDto>(okResult.Value);

            Assert.Equal(QuoteStatus.Stage1Released, response.Status);

            var dbQuote = await db.Quotes.FindAsync(quoteId);
            Assert.Equal(QuoteStatus.Stage1Released, dbQuote!.Status);
        }

        [Fact]
        public async Task Stage2Decision_WhenQuoteNotReleased_Returns409Conflict()
        {
            var (controller, db, _, _) = CreateTestController(role: "Client");
            var quoteId = Guid.NewGuid();

            var quote = new Quote
            {
                Id = quoteId,
                ProjectRequestId = Guid.NewGuid(),
                DesignerId = Guid.NewGuid(),
                Status = QuoteStatus.Draft, // Unreleased
                ScopeSummary = "Draft Quote",
                TotalCost = 120000m
            };
            db.Quotes.Add(quote);
            await db.SaveChangesAsync();

            var decisionDto = new Stage2DecisionDto
            {
                Action = Stage2Action.Approve
            };

            var result = await controller.Stage2Decision(quoteId, decisionDto);
            var statusResult = Assert.IsType<ObjectResult>(result.Result);
            Assert.Equal(409, statusResult.StatusCode);
        }

        [Fact]
        public async Task Stage2Decision_ApproveReleasedQuote_CreatesContractInPendingSignature_AndIsIdempotent()
        {
            var (controller, db, _, _) = CreateTestController(role: "Client");
            var quoteId = Guid.NewGuid();

            var quote = new Quote
            {
                Id = quoteId,
                ProjectRequestId = Guid.NewGuid(),
                DesignerId = Guid.NewGuid(),
                Status = QuoteStatus.Stage1Released, // Released
                ScopeSummary = "Released Quote Ready for Approval",
                TotalCost = 250000m
            };
            db.Quotes.Add(quote);
            await db.SaveChangesAsync();

            var decisionDto = new Stage2DecisionDto { Action = Stage2Action.Approve };

            // First call
            var result1 = await controller.Stage2Decision(quoteId, decisionDto);
            var createdResult = Assert.IsType<CreatedAtActionResult>(result1.Result);
            var contractDto = Assert.IsType<ContractResponseDto>(createdResult.Value);

            Assert.Equal(ContractStatus.PendingSignature, contractDto.Status);
            Assert.Equal(250000m, contractDto.TotalAmount);

            // Double submission (idempotency check)
            var result2 = await controller.Stage2Decision(quoteId, decisionDto);
            var okResult = Assert.IsType<OkObjectResult>(result2.Result);
            var contract2 = Assert.IsType<ContractResponseDto>(okResult.Value);

            Assert.Equal(contractDto.Id, contract2.Id);

            // Ensure only 1 contract in DB
            var contractCount = await db.Contracts.CountAsync(c => c.QuoteId == quoteId);
            Assert.Equal(1, contractCount);
        }

        [Fact]
        public async Task Export_ReturnsFormattedCsvFile()
        {
            var (controller, db, _, _) = CreateTestController(role: "Admin");
            var quoteId = Guid.NewGuid();

            var quote = new Quote
            {
                Id = quoteId,
                ProjectRequestId = Guid.NewGuid(),
                DesignerId = Guid.NewGuid(),
                Status = QuoteStatus.Stage1Released,
                ScopeSummary = "Export Test Scope",
                TotalCost = 100000m
            };
            var version = new QuoteVersion
            {
                Id = Guid.NewGuid(),
                QuoteId = quoteId,
                VersionNumber = 1,
                AuthorId = Guid.NewGuid(),
                AuthorRole = "Designer",
                MaterialsSubtotal = 60000m,
                LaborSubtotal = 40000m,
                TotalCost = 100000m,
                Items = new List<QuoteVersionItem>
                {
                    new() { Description = "Oak Flooring", Category = QuoteItemCategory.Materials, Quantity = 1, UnitCost = 60000m, LineTotal = 60000m },
                    new() { Description = "Flooring Labor", Category = QuoteItemCategory.Labor, Quantity = 1, UnitCost = 40000m, LineTotal = 40000m }
                }
            };
            quote.Versions.Add(version);
            db.Quotes.Add(quote);
            await db.SaveChangesAsync();

            var fileResult = await controller.Export(quoteId, "csv");
            var fileContentResult = Assert.IsType<FileContentResult>(fileResult);

            Assert.Equal("text/csv", fileContentResult.ContentType);
            var csvString = Encoding.UTF8.GetString(fileContentResult.FileContents);
            Assert.Contains("Oak Flooring", csvString);
            Assert.Contains("Flooring Labor", csvString);
            Assert.Contains("Materials Subtotal (LKR),60000.00", csvString);
        }
    }

    public class MockHttpClientFactory : IHttpClientFactory
    {
        private readonly HttpClient _client;
        public MockHttpClientFactory(HttpClient client) => _client = client;
        public HttpClient CreateClient(string name) => _client;
    }
}
