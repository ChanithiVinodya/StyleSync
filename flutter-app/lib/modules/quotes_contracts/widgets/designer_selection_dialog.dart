import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../theme/qc_theme.dart';

class DesignerSelectionDialog extends StatefulWidget {
  final Quote quote;
  final Function(String selectedDesignerId) onConfirm;

  const DesignerSelectionDialog({
    super.key,
    required this.quote,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required Quote quote,
    required Function(String selectedDesignerId) onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => DesignerSelectionDialog(
        quote: quote,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<DesignerSelectionDialog> createState() => _DesignerSelectionDialogState();
}

class _DesignerSelectionDialogState extends State<DesignerSelectionDialog> {
  late String _selectedDesignerId;
  final Set<String> _expandedReasons = {};

  @override
  void initState() {
    super.initState();
    if (widget.quote.recommendedDesigners.isNotEmpty) {
      _selectedDesignerId = widget.quote.recommendedDesigners.first.designerId;
    } else {
      _selectedDesignerId = widget.quote.designerId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final designers = widget.quote.recommendedDesigners;

    return Dialog(
      backgroundColor: QcTheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: QcTheme.border, width: 1.5),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 580,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: QcTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.psychology_outlined, color: QcTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select Matched Designer', style: QcTheme.serifTitle(fontSize: 18)),
                        const Text(
                          'AI-ranked candidates with 4-factor compatibility',
                          style: TextStyle(color: QcTheme.textMuted, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: QcTheme.textMuted, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Project context pill
            if (widget.quote.projectReferenceCode != null || widget.quote.description != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: QcTheme.surfaceSunken,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: QcTheme.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.assignment_outlined, size: 14, color: QcTheme.gold),
                        const SizedBox(width: 6),
                        Text(
                          widget.quote.projectReferenceCode ?? 'Project Request',
                          style: const TextStyle(color: QcTheme.gold, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    if (widget.quote.description != null && widget.quote.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.quote.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: QcTheme.textMuted, fontSize: 11.5, height: 1.3),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Designer candidates list
            Flexible(
              child: designers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'Currently assigned designer: ${widget.quote.designerDisplayName ?? "Lead Designer"}',
                          style: const TextStyle(color: QcTheme.textMuted),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: designers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final d = designers[index];
                        final isSelected = _selectedDesignerId == d.designerId;
                        final isExpanded = _expandedReasons.contains(d.designerId);
                        final matchPct = (d.matchScore * 100).round();

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0x1FC48A36) : QcTheme.surfaceSunken,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? QcTheme.primary : QcTheme.border,
                              width: isSelected ? 1.8 : 1.0,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() => _selectedDesignerId = d.designerId);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top row: Radio, Name, Rank, Match badge
                                  Row(
                                    children: [
                                      Radio<String>(
                                        value: d.designerId,
                                        groupValue: _selectedDesignerId,
                                        activeColor: QcTheme.primary,
                                        onChanged: (val) {
                                          if (val != null) setState(() => _selectedDesignerId = val);
                                        },
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    d.displayName,
                                                    style: const TextStyle(
                                                      color: QcTheme.textMain,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (index == 0) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: const Color(0xFF10B981), width: 0.8),
                                                    ),
                                                    child: const Text(
                                                      'TOP MATCH',
                                                      style: TextStyle(
                                                        color: Color(0xFF34D399),
                                                        fontSize: 9.5,
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${d.rating.toStringAsFixed(1)} ★ (${d.reviewCount} reviews) • \$${d.hourlyRate.toStringAsFixed(0)}/hr • ${d.experienceYears} yrs exp',
                                              style: const TextStyle(color: QcTheme.textSubtle, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Match Score Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: matchPct >= 80
                                              ? const Color(0x2E10B981)
                                              : (matchPct >= 60 ? const Color(0x2EF59E0B) : const Color(0x2EEF4444)),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: matchPct >= 80
                                                ? const Color(0xFF10B981)
                                                : (matchPct >= 60 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          '$matchPct% Match',
                                          style: TextStyle(
                                            color: matchPct >= 80
                                                ? const Color(0xFF34D399)
                                                : (matchPct >= 60 ? const Color(0xFFFBBF24) : const Color(0xFFF87171)),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Style tags
                                  if (d.specializations.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: d.specializations.map((spec) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF24201D),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: QcTheme.borderLight, width: 0.8),
                                        ),
                                        child: Text(
                                          spec,
                                          style: const TextStyle(color: QcTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
                                        ),
                                      )).toList(),
                                    ),
                                  ],

                                  // Toggle 4-factor plain English explanations
                                  if (d.factorExplanations.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isExpanded) {
                                            _expandedReasons.remove(d.designerId);
                                          } else {
                                            _expandedReasons.add(d.designerId);
                                          }
                                        });
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isExpanded ? Icons.expand_less : Icons.expand_more,
                                            size: 16,
                                            color: QcTheme.gold,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isExpanded ? 'Hide Match Factors' : 'View 4-Factor Plain-English Breakdown',
                                            style: const TextStyle(
                                              color: QcTheme.gold,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isExpanded) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF191614),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: QcTheme.borderSubtle),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: d.factorExplanations.entries.map((entry) {
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 2.5),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '• ${entry.key}: ',
                                                    style: const TextStyle(
                                                      color: QcTheme.textMain,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      entry.value,
                                                      style: const TextStyle(
                                                        color: QcTheme.textMuted,
                                                        fontSize: 11,
                                                        height: 1.3,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: QcTheme.textMuted,
                      side: const BorderSide(color: QcTheme.borderLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onConfirm(_selectedDesignerId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: QcTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Confirm & Approve Quote',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
