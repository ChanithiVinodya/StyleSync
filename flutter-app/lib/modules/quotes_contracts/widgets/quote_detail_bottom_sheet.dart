import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../theme/qc_theme.dart';
import 'status_badge.dart';

class QuoteDetailBottomSheet extends StatelessWidget {
  final Quote quote;
  final VoidCallback? onEdit;
  final VoidCallback? onSubmit;
  final VoidCallback? onDelete;

  const QuoteDetailBottomSheet({
    super.key,
    required this.quote,
    this.onEdit,
    this.onSubmit,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required Quote quote,
    VoidCallback? onEdit,
    VoidCallback? onSubmit,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuoteDetailBottomSheet(
        quote: quote,
        onEdit: onEdit,
        onSubmit: onSubmit,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusStr = quote.status.toLowerCase();
    final isDraft = statusStr == 'draft';
    final isSubmitted = statusStr == 'submitted' || statusStr == 'clientreview';

    return Container(
      padding: const EdgeInsets.only(top: 12, left: 20, right: 20, bottom: 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: QcTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: QcTheme.border, width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: QcTheme.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Status Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Quote Details', style: QcTheme.serifTitle(fontSize: 20)),
                                const SizedBox(width: 8),
                                StatusBadge(status: quote.status),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              quote.scopeSummary,
                              style: const TextStyle(color: QcTheme.textMain, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: QcTheme.textMuted),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (quote.isAiGenerated) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x1AC48A36),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: QcTheme.primary, width: 0.8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, color: QcTheme.gold, size: 12),
                          SizedBox(width: 6),
                          Text('AI Generated Estimate', style: TextStyle(color: QcTheme.gold, fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (quote.notes != null && quote.notes!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: QcTheme.surfaceSunken,
                        borderRadius: BorderRadius.circular(10),
                        border: const Border(left: BorderSide(color: QcTheme.primary, width: 3.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('NOTES:', style: TextStyle(color: QcTheme.textSubtle, fontSize: 10.5, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(quote.notes!, style: const TextStyle(color: QcTheme.textMuted, fontSize: 12.5, height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Line Items section
                  const Text('Itemized Cost Breakdown', style: TextStyle(color: QcTheme.textMain, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: QcTheme.surfaceSunken,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: QcTheme.border),
                    ),
                    child: Column(
                      children: [
                        ...quote.items.map((item) {
                          final catColor = QcTheme.getCategoryColor(item.category);
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: QcTheme.borderSubtle)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: catColor.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(item.category, style: TextStyle(color: catColor, fontSize: 10, fontWeight: FontWeight.w700)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.description, style: const TextStyle(color: QcTheme.textMain, fontSize: 13, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Qty: ${item.quantity} × ${QcTheme.formatCurrency(item.unitCost)}',
                                        style: const TextStyle(color: QcTheme.textSubtle, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  QcTheme.formatCurrency(item.calculatedTotal),
                                  style: const TextStyle(color: QcTheme.textMain, fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          );
                        }),

                        // Total footer
                        Container(
                          padding: const EdgeInsets.all(14),
                          color: const Color(0x1F2C2723),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Cost:', style: TextStyle(color: QcTheme.textMain, fontSize: 14, fontWeight: FontWeight.w700)),
                              Text(
                                QcTheme.formatCurrency(quote.totalCost),
                                style: const TextStyle(color: QcTheme.gold, fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    children: [
                      if (isDraft && onEdit != null) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onEdit!();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: QcTheme.textMain,
                              backgroundColor: QcTheme.surfaceSunken,
                              side: const BorderSide(color: QcTheme.borderLight),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Edit Quote', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (isDraft && onSubmit != null) ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onSubmit!();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: QcTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Submit Quote', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (isSubmitted && onSubmit != null) ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onSubmit!();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: QcTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Accept Quote', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: QcTheme.textMuted,
                          side: const BorderSide(color: QcTheme.borderLight),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
