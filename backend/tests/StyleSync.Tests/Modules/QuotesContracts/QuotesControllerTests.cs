using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Json;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Controllers;
using StyleSync.Api.Data;
using StyleSync.Api.DTOs;
using StyleSync.Api.Models;
using Xunit;

namespace StyleSync.Tests.Modules.QuotesContracts
{
    public class MockHttpMessageHandler : HttpMessageHandler
    {
        private readonly Func<HttpRequestMessage, Task<HttpResponseMessage>> _handlerFunc;

        public MockHttpMessageHandler(Func<HttpRequestMessage, Task<HttpResponseMessage>> handlerFunc)
        {
            _handlerFunc = handlerFunc;
        }

        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            return _handlerFunc(request);
        }
    }

    public class MockHttpClientFactory : IHttpClientFactory
    {
        private readonly HttpClient _client;

        public MockHttpClientFactory(HttpClient client)
        {
            _client = client;
        }

        public HttpClient CreateClient(string name)
        {
            return _client;
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

        [Fact]
        public async Task DraftFromAgent_WhenAgentReturnsValidDraft_CreatesDraftQuoteAndReturns201()
        {
            // Arrange
            using var db = CreateInMemoryDbContext();
            var controller = new QuotesController(db);

            var agentResponsePayload = new AgentBudgetScopeResponse
            {
                ScopeSummary = "Mid Century Modern Living room refresh, 200 sq ft.",
                Notes = "Fallback estimate - standard split",
                EstimatedTotal = 200000m,
                WithinBudget = true,
                Source = "fallback",
                Items = new List<AgentQuoteItemDraft>
                {
                    new() { Description = "Design - concept", Category = "Design", Quantity = 1, UnitCost = 20000m },
                    new() { Description = "Labor - installation", Category = "Labor", Quantity = 1, UnitCost = 60000m },
                    new() { Description = "Materials - finishes", Category = "Materials", Quantity = 1, UnitCost = 70000m },
                    new() { Description = "Furniture - curated pieces", Category = "Furniture", Quantity = 1, UnitCost = 50000m }
                }
            };

            var mockHandler = new MockHttpMessageHandler(req =>
            {
                Assert.Equal("/agents/budget-scope", req.RequestUri?.AbsolutePath);
                var response = new HttpResponseMessage(HttpStatusCode.OK)
                {
                    Content = JsonContent.Create(agentResponsePayload)
                };
                return Task.FromResult(response);
            });

            var httpClient = new HttpClient(mockHandler)
            {
                BaseAddress = new Uri("http://localhost:8000")
            };
            var factory = new MockHttpClientFactory(httpClient);

            var requestDto = new DraftQuoteFromAgentDto
            {
                RoomType = "Living room",
                RoomSizeSqft = 200,
                BudgetMin = 150000m,
                BudgetMax = 250000m,
                StyleProfile = "Mid Century Modern",
                StyleConfidence = 0.85
            };

            // Act
            var actionResult = await controller.DraftFromAgent(requestDto, factory);

            // Assert
            var createdAtResult = Assert.IsType<CreatedAtActionResult>(actionResult.Result);
            var responseDto = Assert.IsType<QuoteResponseDto>(createdAtResult.Value);

            Assert.Equal(QuoteStatus.Draft, responseDto.Status);
            Assert.True(responseDto.IsAiGenerated);
            Assert.Equal(200000m, responseDto.TotalCost);
            Assert.Equal(4, responseDto.Items.Count);
            Assert.Contains("Mid Century Modern", responseDto.ScopeSummary);

            // Verify persistence in DB
            var savedQuote = await db.Quotes.Include(q => q.Items).FirstOrDefaultAsync(q => q.Id == responseDto.Id);
            Assert.NotNull(savedQuote);
            Assert.Equal(QuoteStatus.Draft, savedQuote.Status);
            Assert.True(savedQuote.IsAiGenerated);
            Assert.Equal(4, savedQuote.Items.Count);
        }

        [Fact]
        public async Task DraftPreview_WhenAgentReturnsValidDraft_ReturnsDraftBreakdownWithoutSavingToDb()
        {
            // Arrange
            using var db = CreateInMemoryDbContext();
            var controller = new QuotesController(db);

            var agentResponsePayload = new AgentBudgetScopeResponse
            {
                ScopeSummary = "Modern Minimalist Kitchen refresh, 150 sq ft.",
                Notes = "Quick estimate",
                EstimatedTotal = 160000m,
                WithinBudget = true,
                Source = "llm",
                Items = new List<AgentQuoteItemDraft>
                {
                    new() { Description = "Design consultation", Category = "Design", Quantity = 1, UnitCost = 16000m },
                    new() { Description = "Cabinetry & Countertops", Category = "Materials", Quantity = 1, UnitCost = 144000m }
                }
            };

            var mockHandler = new MockHttpMessageHandler(req =>
            {
                var response = new HttpResponseMessage(HttpStatusCode.OK)
                {
                    Content = JsonContent.Create(agentResponsePayload)
                };
                return Task.FromResult(response);
            });

            var httpClient = new HttpClient(mockHandler)
            {
                BaseAddress = new Uri("http://localhost:8000")
            };
            var factory = new MockHttpClientFactory(httpClient);

            var requestDto = new DraftQuoteFromAgentDto
            {
                RoomType = "Kitchen",
                RoomSizeSqft = 150,
                BudgetMin = 100000m,
                BudgetMax = 200000m,
                StyleProfile = "Minimalist"
            };

            // Act
            var actionResult = await controller.DraftPreview(requestDto, factory);

            // Assert
            var okResult = Assert.IsType<OkObjectResult>(actionResult.Result);
            var result = Assert.IsType<AgentBudgetScopeResponse>(okResult.Value);

            Assert.Equal(160000m, result.EstimatedTotal);
            Assert.Equal(2, result.Items.Count);

            // Ensure nothing was saved into DB
            var count = await db.Quotes.CountAsync();
            Assert.Equal(0, count);
        }

        [Fact]
        public async Task DraftFromAgent_WhenAiServiceUnreachable_Returns502()
        {
            // Arrange
            using var db = CreateInMemoryDbContext();
            var controller = new QuotesController(db);

            var mockHandler = new MockHttpMessageHandler(req =>
            {
                throw new HttpRequestException("Connection refused");
            });

            var httpClient = new HttpClient(mockHandler)
            {
                BaseAddress = new Uri("http://localhost:8000")
            };
            var factory = new MockHttpClientFactory(httpClient);

            var requestDto = new DraftQuoteFromAgentDto
            {
                RoomType = "Living room",
                RoomSizeSqft = 200,
                BudgetMin = 150000m,
                BudgetMax = 250000m,
                StyleProfile = "Industrial"
            };

            // Act
            var actionResult = await controller.DraftFromAgent(requestDto, factory);

            // Assert
            var statusResult = Assert.IsType<ObjectResult>(actionResult.Result);
            Assert.Equal(502, statusResult.StatusCode);
        }

        [Fact]
        public async Task Update_WhenDesignerRevisesItems_ResetsIsAiGeneratedToFalse()
        {
            // Arrange
            using var db = CreateInMemoryDbContext();
            var controller = new QuotesController(db);

            var quoteId = Guid.NewGuid();
            var initialQuote = new Quote
            {
                Id = quoteId,
                ProjectRequestId = Guid.NewGuid(),
                DesignerId = Guid.NewGuid(),
                Status = QuoteStatus.Draft,
                IsAiGenerated = true,
                ScopeSummary = "AI Draft Scope",
                TotalCost = 100000m,
                Items = new List<QuoteItem>
                {
                    new() { Id = Guid.NewGuid(), QuoteId = quoteId, Description = "AI line item", Category = QuoteItemCategory.Design, Quantity = 1, UnitCost = 100000m, LineTotal = 100000m }
                }
            };
            db.Quotes.Add(initialQuote);
            await db.SaveChangesAsync();

            var updateDto = new UpdateQuoteDto
            {
                ScopeSummary = "Designer Revised Scope",
                Items = new List<QuoteItemDto>
                {
                    new() { Description = "Manual item 1", Category = QuoteItemCategory.Design, Quantity = 1, UnitCost = 60000m },
                    new() { Description = "Manual item 2", Category = QuoteItemCategory.Materials, Quantity = 2, UnitCost = 30000m }
                }
            };

            // Act
            var actionResult = await controller.Update(quoteId, updateDto);

            // Assert
            var okResult = Assert.IsType<OkObjectResult>(actionResult.Result);
            var updatedQuote = Assert.IsType<QuoteResponseDto>(okResult.Value);

            Assert.False(updatedQuote.IsAiGenerated);
            Assert.Equal(120000m, updatedQuote.TotalCost);
            Assert.Equal("Designer Revised Scope", updatedQuote.ScopeSummary);
            Assert.Equal(2, updatedQuote.Items.Count);
        }

        [Fact]
        public async Task AcceptQuote_CreatesContractAndTransitionsStatusToAccepted()
        {
            // Arrange
            using var db = CreateInMemoryDbContext();
            var controller = new QuotesController(db);

            var quoteId = Guid.NewGuid();
            var quote = new Quote
            {
                Id = quoteId,
                ProjectRequestId = Guid.NewGuid(),
                DesignerId = Guid.NewGuid(),
                Status = QuoteStatus.ClientReview,
                ScopeSummary = "Approved Living Room Scope",
                TotalCost = 250000m,
                Items = new List<QuoteItem>
                {
                    new() { Id = Guid.NewGuid(), QuoteId = quoteId, Description = "Full scope", Category = QuoteItemCategory.Design, Quantity = 1, UnitCost = 250000m, LineTotal = 250000m }
                }
            };
            db.Quotes.Add(quote);
            await db.SaveChangesAsync();

            // Act
            var actionResult = await controller.Accept(quoteId);

            // Assert
            var createdResult = Assert.IsType<CreatedAtActionResult>(actionResult.Result);
            var contractDto = Assert.IsType<ContractResponseDto>(createdResult.Value);

            Assert.Equal(quoteId, contractDto.QuoteId);
            Assert.Equal(250000m, contractDto.TotalAmount);
            Assert.Equal(ContractStatus.Draft, contractDto.Status);

            var dbQuote = await db.Quotes.FindAsync(quoteId);
            Assert.NotNull(dbQuote);
            Assert.Equal(QuoteStatus.Accepted, dbQuote.Status);
        }
    }
}
