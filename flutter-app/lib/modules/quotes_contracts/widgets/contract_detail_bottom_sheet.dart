import 'package:flutter/material.dart';
import '../models/contract.dart';
import '../theme/qc_theme.dart';
import 'status_badge.dart';

class ContractDetailBottomSheet extends StatelessWidget {
  final Contract contract;
  final VoidCallback? onSign;
  final VoidCallback? onCancel;

  const ContractDetailBottomSheet({
    super.key,
    required this.contract,
    this.onSign,
    this.onCancel,
  });

  static Future<void> show(
    BuildContext context, {
    required Contract contract,
    VoidCallback? onSign,
    VoidCallback? onCancel,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ContractDetailBottomSheet(
        contract: contract,
        onSign: onSign,
        onCancel: onCancel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusStr = contract.status.toLowerCase();
    final canSign = statusStr == 'draft' || statusStr == 'pendingsignature';
    final canCancel = statusStr != 'completed' && statusStr != 'cancelled';
    final linkedQuote = contract.quote;

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
                  // Title & Status
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
                                Text('Contract Specs', style: QcTheme.serifTitle(fontSize: 20)),
                                const SizedBox(width: 8),
                                StatusBadge(status: contract.status),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Contract ID: #${contract.id}',
                              style: const TextStyle(color: QcTheme.textSubtle, fontSize: 12, fontFamily: 'monospace'),
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
                  const SizedBox(height: 16),

                  // Overview Cards
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: QcTheme.surfaceSunken,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: QcTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('AGREED AMOUNT', style: TextStyle(color: QcTheme.textSubtle, fontSize: 10, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(QcTheme.formatCurrency(contract.totalAmount), style: const TextStyle(color: QcTheme.gold, fontSize: 14, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: QcTheme.surfaceSunken,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: QcTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('SIGNATURE', style: TextStyle(color: QcTheme.textSubtle, fontSize: 10, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(
                                contract.signedAt != null ? '✓ Signed' : 'Pending',
                                style: TextStyle(
                                  color: contract.signedAt != null ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Scope summary
                  const Text('Scope of Work', style: TextStyle(color: QcTheme.textMain, fontSize: 13.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: QcTheme.surfaceSunken,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: QcTheme.border),
                    ),
                    child: Text(
                      contract.termsSummary ?? linkedQuote?.scopeSummary ?? 'Interior Design Contract',
                      style: const TextStyle(color: QcTheme.textMain, fontSize: 13, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Linked Quote Breakdown
                  if (linkedQuote != null && linkedQuote.items.isNotEmpty) ...[
                    const Text('Itemized Specification', style: TextStyle(color: QcTheme.textMain, fontSize: 13.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: QcTheme.surfaceSunken,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: QcTheme.border),
                      ),
                      child: Column(
                        children: linkedQuote.items.map((it) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(it.description, style: const TextStyle(color: QcTheme.textMain, fontSize: 12.5)),
                                ),
                                Text(
                                  QcTheme.formatCurrency(it.calculatedTotal),
                                  style: const TextStyle(color: QcTheme.gold, fontSize: 12.5, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Legal Terms
                  const Text('Contract Legal Agreement', style: TextStyle(color: QcTheme.textMain, fontSize: 13.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: QcTheme.surfaceSunken,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: QcTheme.border),
                    ),
                    child: Text(
                      contract.terms ??
                          'Official StyleSync Binding Agreement. Standard milestone schedule: 50% advance deposit due upon signing, 50% balance upon final room handover inspection. Designer quality guarantee applies.',
                      style: const TextStyle(color: QcTheme.textMuted, fontSize: 12, height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      if (canSign && onSign != null) ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onSign!();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: QcTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Mark Signed', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (canCancel && onCancel != null) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onCancel!();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF87171),
                              backgroundColor: const Color(0x1AEF4444),
                              side: const BorderSide(color: Color(0xFF7F1D1D)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Cancel Contract', style: TextStyle(fontWeight: FontWeight.w600)),
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
