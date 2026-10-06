using System;
using System.Globalization;
using System.IO;
using System.Text;
using StyleSync.Api.Models;

namespace StyleSync.Api.Services
{
    public interface IQuoteExportService
    {
        byte[] GenerateCsv(Quote quote, QuoteVersion version);
        byte[] GeneratePdf(Quote quote, QuoteVersion version);
    }

    public class QuoteExportService : IQuoteExportService
    {
        public byte[] GenerateCsv(Quote quote, QuoteVersion version)
        {
            var sb = new StringBuilder();
            sb.AppendLine("StyleSync Official Quotation / FF&E Specification");
            sb.AppendLine($"Quote ID,{quote.Id}");
            sb.AppendLine($"Version,{version.VersionNumber}");
            sb.AppendLine($"Scope Summary,\"{quote.ScopeSummary?.Replace("\"", "\"\"")}\"");
            sb.AppendLine($"Status,{quote.Status}");
            sb.AppendLine($"Date,{version.CreatedAt:yyyy-MM-dd HH:mm:ss UTC}");
            sb.AppendLine();
            sb.AppendLine("Item No,Category,Description,Quantity,Unit Cost (LKR),Line Total (LKR)");

            int index = 1;
            foreach (var item in version.Items)
            {
                sb.AppendLine(string.Format(
                    CultureInfo.InvariantCulture,
                    "{0},{1},\"{2}\",{3},{4:F2},{5:F2}",
                    index++,
                    item.Category,
                    item.Description.Replace("\"", "\"\""),
                    item.Quantity,
                    item.UnitCost,
                    item.LineTotal
                ));
            }

            sb.AppendLine();
            sb.AppendLine(string.Format(CultureInfo.InvariantCulture, ",,,,Materials Subtotal (LKR),{0:F2}", version.MaterialsSubtotal));
            sb.AppendLine(string.Format(CultureInfo.InvariantCulture, ",,,,Labor Subtotal (LKR),{0:F2}", version.LaborSubtotal));
            sb.AppendLine(string.Format(CultureInfo.InvariantCulture, ",,,,Design Fee (LKR),{0:F2}", version.DesignFee));
            sb.AppendLine(string.Format(CultureInfo.InvariantCulture, ",,,,Contingency (LKR),{0:F2}", version.ContingencyAmount));
            sb.AppendLine(string.Format(CultureInfo.InvariantCulture, ",,,,Tax / VAT (LKR),{0:F2}", version.TaxAmount));
            sb.AppendLine(string.Format(CultureInfo.InvariantCulture, ",,,,Total Cost (LKR),{0:F2}", version.TotalCost));

            return Encoding.UTF8.GetBytes(sb.ToString());
        }

        public byte[] GeneratePdf(Quote quote, QuoteVersion version)
        {
            // Generates a well-formatted printable HTML / PDF payload
            var sb = new StringBuilder();
            sb.AppendLine("<!DOCTYPE html><html><head><meta charset='utf-8'><title>StyleSync Quotation</title>");
            sb.AppendLine("<style>");
            sb.AppendLine("body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; color: #1C1917; padding: 40px; }");
            sb.AppendLine(".header { border-bottom: 2px solid #C48A36; padding-bottom: 16px; margin-bottom: 24px; }");
            sb.AppendLine("h1 { margin: 0; color: #1C1917; font-size: 24px; }");
            sb.AppendLine(".meta { display: flex; justify-content: space-between; margin-bottom: 24px; font-size: 13px; color: #57534E; }");
            sb.AppendLine("table { width: 100%; border-collapse: collapse; margin-bottom: 24px; font-size: 13px; }");
            sb.AppendLine("th { background: #F5EFEB; text-align: left; padding: 10px; border-bottom: 1px solid #E7E1D7; }");
            sb.AppendLine("td { padding: 10px; border-bottom: 1px solid #E7E1D7; }");
            sb.AppendLine(".summary-box { width: 320px; margin-left: auto; font-size: 13px; }");
            sb.AppendLine(".summary-row { display: flex; justify-content: space-between; padding: 6px 0; }");
            sb.AppendLine(".total-row { font-weight: bold; font-size: 16px; color: #C48A36; border-top: 2px solid #C48A36; padding-top: 10px; margin-top: 6px; }");
            sb.AppendLine("</style></head><body>");

            sb.AppendLine("<div class='header'>");
            sb.AppendLine("<h1>StyleSync Official Quotation &amp; Specification</h1>");
            sb.AppendLine("<p style='color: #78716C; margin: 4px 0 0 0;'>Architectural &amp; Interior Design Engineering</p>");
            sb.AppendLine("</div>");

            sb.AppendLine("<div class='meta'>");
            sb.AppendLine($"<div><strong>Quote ID:</strong> {quote.Id}<br><strong>Version:</strong> v{version.VersionNumber} ({version.AuthorRole})<br><strong>Status:</strong> {quote.Status}</div>");
            sb.AppendLine($"<div style='text-align: right;'><strong>Date:</strong> {version.CreatedAt:dd MMM yyyy}<br><strong>Project Request:</strong> {quote.ProjectRequestId}</div>");
            sb.AppendLine("</div>");

            sb.AppendLine($"<div style='margin-bottom: 20px; background: #FAF8F5; padding: 12px; border-radius: 8px;'><strong>Scope Summary:</strong> {quote.ScopeSummary}</div>");

            sb.AppendLine("<table>");
            sb.AppendLine("<thead><tr><th>#</th><th>Description</th><th>Category</th><th style='text-align: right;'>Qty</th><th style='text-align: right;'>Unit Cost</th><th style='text-align: right;'>Total</th></tr></thead>");
            sb.AppendLine("<tbody>");
            int idx = 1;
            foreach (var item in version.Items)
            {
                sb.AppendLine($"<tr><td>{idx++}</td><td>{item.Description}</td><td>{item.Category}</td><td style='text-align: right;'>{item.Quantity}</td><td style='text-align: right;'>LKR {item.UnitCost:N2}</td><td style='text-align: right;'>LKR {item.LineTotal:N2}</td></tr>");
            }
            sb.AppendLine("</tbody></table>");

            sb.AppendLine("<div class='summary-box'>");
            sb.AppendLine($"<div class='summary-row'><span>Materials Subtotal:</span><span>LKR {version.MaterialsSubtotal:N2}</span></div>");
            sb.AppendLine($"<div class='summary-row'><span>Labor Subtotal:</span><span>LKR {version.LaborSubtotal:N2}</span></div>");
            sb.AppendLine($"<div class='summary-row'><span>Design Fee:</span><span>LKR {version.DesignFee:N2}</span></div>");
            sb.AppendLine($"<div class='summary-row'><span>Contingency (5%):</span><span>LKR {version.ContingencyAmount:N2}</span></div>");
            sb.AppendLine($"<div class='summary-row'><span>Tax / VAT (8%):</span><span>LKR {version.TaxAmount:N2}</span></div>");
            sb.AppendLine($"<div class='summary-row total-row'><span>Total Cost:</span><span>LKR {version.TotalCost:N2}</span></div>");
            sb.AppendLine("</div>");

            if (!string.IsNullOrWhiteSpace(quote.Notes))
            {
                sb.AppendLine($"<div style='margin-top: 30px; font-size: 12px; color: #78716C; border-top: 1px solid #E7E1D7; padding-top: 12px;'><strong>Notes:</strong> {quote.Notes}</div>");
            }

            sb.AppendLine("</body></html>");
            return Encoding.UTF8.GetBytes(sb.ToString());
        }
    }
}
