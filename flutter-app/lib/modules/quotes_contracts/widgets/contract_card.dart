import 'package:flutter/material.dart';
import '../models/contract.dart';
import '../theme/qc_theme.dart';
import 'status_badge.dart';

class ContractCard extends StatelessWidget {
  final Contract contract;
  final VoidCallback? onCancel;
  final VoidCallback? onSign;
  final VoidCallback? onTap;

  const ContractCard({
    super.key,
    required this.contract,
    this.onCancel,
    this.onSign,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusStr = contract.status.toLowerCase();
    final isCancelled = statusStr == 'cancelled';
    final isSigned = contract.signedAt != null;
    final canCancel = !isCancelled && statusStr != 'completed';
    final canSign = statusStr == 'draft' || statusStr == 'pendingsignature';

    final shortId = contract.id.length > 8 ? '#${contract.id.substring(0, 6)}' : '#${contract.id}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: QcTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QcTheme.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Status Badge & Contract ID
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatusBadge(status: contract.status),
                    Text(
                      shortId,
                      style: const TextStyle(
                        color: QcTheme.textSubtle,
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title (termsSummary or quote scopeSummary)
                Text(
                  contract.termsSummary ?? contract.quote?.scopeSummary ?? 'Interior Design Agreement',
                  style: const TextStyle(
                    color: QcTheme.textMain,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),

                // AMOUNT & SIGNED Row
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AMOUNT',
                            style: TextStyle(
                              color: QcTheme.textSubtle,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            QcTheme.formatCurrency(contract.totalAmount),
                            style: const TextStyle(
                              color: QcTheme.textMain,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SIGNED',
                            style: TextStyle(
                              color: QcTheme.textSubtle,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isSigned ? QcTheme.formatDate(contract.signedAt) : '—',
                            style: TextStyle(
                              color: isSigned ? const Color(0xFF34D399) : QcTheme.textSubtle,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // UPDATED Row
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'UPDATED',
                      style: TextStyle(
                        color: QcTheme.textSubtle,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      QcTheme.formatDate(contract.updatedAt ?? contract.createdAt),
                      style: const TextStyle(
                        color: QcTheme.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action Buttons
                if (canCancel || canSign) ...[
                  Row(
                    children: [
                      if (canSign) ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onSign,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: QcTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Mark signed', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (canCancel) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onCancel,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF87171),
                              backgroundColor: const Color(0x1AEF4444),
                              side: const BorderSide(color: Color(0xFF7F1D1D), width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Cancel contract',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFFF87171),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
