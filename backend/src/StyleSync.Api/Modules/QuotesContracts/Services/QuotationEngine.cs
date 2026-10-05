using System;
using System.Collections.Generic;
using System.Linq;
using StyleSync.Api.DTOs;
using StyleSync.Api.Models;

namespace StyleSync.Api.Services
{
    public record QuotationCalculationResult(
        decimal MaterialsSubtotal,
        decimal LaborSubtotal,
        decimal DesignFee,
        decimal ContingencyAmount,
        decimal TaxAmount,
        decimal TotalCost,
        List<QuoteVersionItem> Items
    );

    public interface IQuotationEngine
    {
        QuotationCalculationResult Calculate(
            IEnumerable<QuoteItemDto> items,
            decimal designFeeRate = 0.10m,
            decimal contingencyRate = 0.05m,
            decimal taxRate = 0.08m);
    }

    public class QuotationEngine : IQuotationEngine
    {
        public QuotationCalculationResult Calculate(
            IEnumerable<QuoteItemDto> items,
            decimal designFeeRate = 0.10m,
            decimal contingencyRate = 0.05m,
            decimal taxRate = 0.08m)
        {
            var itemList = items.Select(i => new QuoteVersionItem
            {
                Id = i.Id ?? Guid.NewGuid(),
                Description = i.Description.Trim(),
                Category = i.Category,
                Quantity = i.Quantity,
                UnitCost = i.UnitCost,
                LineTotal = Math.Round(i.Quantity * i.UnitCost, 2, MidpointRounding.AwayFromZero)
            }).ToList();

            decimal materialsSubtotal = itemList
                .Where(i => i.Category is QuoteItemCategory.Materials or QuoteItemCategory.Furniture or QuoteItemCategory.Other)
                .Sum(i => i.LineTotal);

            decimal laborSubtotal = itemList
                .Where(i => i.Category is QuoteItemCategory.Labor)
                .Sum(i => i.LineTotal);

            decimal directDesignItems = itemList
                .Where(i => i.Category is QuoteItemCategory.Design)
                .Sum(i => i.LineTotal);

            // If design fee items exist in line items, sum them; otherwise compute percentage
            decimal designFee = directDesignItems > 0 
                ? directDesignItems 
                : Math.Round((materialsSubtotal + laborSubtotal) * designFeeRate, 2, MidpointRounding.AwayFromZero);

            decimal subtotalBeforeContingencyAndTax = materialsSubtotal + laborSubtotal + designFee;
            decimal contingencyAmount = Math.Round(subtotalBeforeContingencyAndTax * contingencyRate, 2, MidpointRounding.AwayFromZero);

            decimal taxableAmount = subtotalBeforeContingencyAndTax + contingencyAmount;
            decimal taxAmount = Math.Round(taxableAmount * taxRate, 2, MidpointRounding.AwayFromZero);

            decimal totalCost = subtotalBeforeContingencyAndTax + contingencyAmount + taxAmount;

            return new QuotationCalculationResult(
                MaterialsSubtotal: materialsSubtotal,
                LaborSubtotal: laborSubtotal,
                DesignFee: designFee,
                ContingencyAmount: contingencyAmount,
                TaxAmount: taxAmount,
                TotalCost: totalCost,
                Items: itemList
            );
        }
    }
}
