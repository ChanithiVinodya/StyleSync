using System;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using StyleSync.Api.Models;

namespace StyleSync.Api.Integrations
{
    public interface IApprovalGateResumer
    {
        Task ResumeStage1GateAsync(Guid quoteId, Stage1Action action, string? notes);
        Task ResumeStage2GateAsync(Guid quoteId, Stage2Action action, string? feedback);
    }

    public class LangGraphApprovalGateResumer : IApprovalGateResumer
    {
        private readonly ILogger<LangGraphApprovalGateResumer> _logger;

        public LangGraphApprovalGateResumer(ILogger<LangGraphApprovalGateResumer> logger)
        {
            _logger = logger;
        }

        public Task ResumeStage1GateAsync(Guid quoteId, Stage1Action action, string? notes)
        {
            _logger.LogInformation(
                "[LangGraph Approval Gate] Stage 1 Decision for Quote {QuoteId}: {Action}. Notes: {Notes}",
                quoteId, action, notes ?? "None");

            // When full LangGraph pipeline is wired, this executes Command(resume=action) on the checkpoint.
            return Task.CompletedTask;
        }

        public Task ResumeStage2GateAsync(Guid quoteId, Stage2Action action, string? feedback)
        {
            _logger.LogInformation(
                "[LangGraph Approval Gate] Stage 2 Decision for Quote {QuoteId}: {Action}. Feedback: {Feedback}",
                quoteId, action, feedback ?? "None");

            // When full LangGraph pipeline is wired, this executes Command(resume=action) on the checkpoint.
            return Task.CompletedTask;
        }
    }
}
