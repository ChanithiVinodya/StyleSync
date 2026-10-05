using System.Collections.Generic;
using System.Linq;

namespace StyleSync.Api.Services
{
    public record BudgetGuardResult(
        bool IsValid,
        List<string> Errors
    );

    public interface IBudgetGuard
    {
        BudgetGuardResult Validate(QuotationCalculationResult calculation, decimal maxBudget);
    }

    public class BudgetGuard : IBudgetGuard
    {
        public BudgetGuardResult Validate(QuotationCalculationResult calculation, decimal maxBudget)
        {
            var errors = new List<string>();

            if (maxBudget > 0 && calculation.TotalCost > maxBudget)
            {
                errors.Add($"Quote total (LKR {calculation.TotalCost:N2}) exceeds client max budget (LKR {maxBudget:N2}) by LKR {(calculation.TotalCost - maxBudget):N2}.");
            }

            decimal sumOfLineItems = calculation.Items.Sum(i => i.LineTotal);
            if (sumOfLineItems <= 0)
            {
                errors.Add("Quote must have at least one line item with a positive cost.");
            }

            return new BudgetGuardResult(
                IsValid: errors.Count == 0,
                Errors: errors
            );
        }
    }
}
