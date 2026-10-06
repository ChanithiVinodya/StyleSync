import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../theme/qc_theme.dart';
import 'status_badge.dart';

class QuoteDetailBottomSheet extends StatefulWidget {
  final Quote quote;
  final Function(String action, String? feedback, String? designerId)? onStage2Decision;
  final Function(String format)? onExport;

  const QuoteDetailBottomSheet({
    super.key,
    required this.quote,
    this.onStage2Decision,
    this.onExport,
  });

  static Future<void> show(
    BuildContext context, {
    required Quote quote,
    Function(String action, String? feedback, String? designerId)? onStage2Decision,
    Function(String format)? onExport,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuoteDetailBottomSheet(
        quote: quote,
        onStage2Decision: onStage2Decision,
        onExport: onExport,
      ),
    );
  }

  @override
  State<QuoteDetailBottomSheet> createState() => _QuoteDetailBottomSheetState();
}

class _QuoteDetailBottomSheetState extends State<QuoteDetailBottomSheet> {
  late String _selectedDesignerId;
  late String _selectedDesignerName;
  final Set<String> _expandedReasons = {};

  @override
  void initState() {
    super.initState();
    if (widget.quote.recommendedDesigners.isNotEmpty) {
      final firstRec = widget.quote.recommendedDesigners.first;
      _selectedDesignerId = firstRec.designerId;
      _selectedDesignerName = firstRec.displayName;
    } else {
      _selectedDesignerId = widget.quote.designerId;
      _selectedDesignerName = widget.quote.designerDisplayName ?? 'Lead Designer';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusStr = widget.quote.status.toLowerCase();
    final isReleased = statusStr == 'stage1released' || statusStr == 'clientreview';
    final currentVer = widget.quote.currentVersion;

    return Container(
      padding: const EdgeInsets.only(top: 12, left: 20, right: 20, bottom: 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
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
                                Text('Quote Specification', style: QcTheme.serifTitle(fontSize: 20)),
                                const SizedBox(width: 8),
                                StatusBadge(status: widget.quote.status),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.quote.scopeSummary,
                              style: const TextStyle(color: QcTheme.textMain, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            if (currentVer != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Version ${currentVer.versionNumber} • Updated by ${currentVer.authorRole}',
                                style: const TextStyle(color: QcTheme.gold, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
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

                  // Client and Assigned Designer Information Box
                  if (widget.quote.description != null || widget.quote.designerDisplayName != null || widget.quote.projectReferenceCode != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: QcTheme.surfaceSunken,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: QcTheme.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.quote.projectReferenceCode != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('PROJECT REF:', style: TextStyle(color: QcTheme.textSubtle, fontSize: 10, fontWeight: FontWeight.w700)),
                                Text(widget.quote.projectReferenceCode!, style: const TextStyle(color: QcTheme.gold, fontSize: 11.5, fontWeight: FontWeight.w700)),
                              ],
                            ),
                            const SizedBox(height: 6),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('ASSIGNED DESIGNER:', style: TextStyle(color: QcTheme.textSubtle, fontSize: 10, fontWeight: FontWeight.w700)),
                              Row(
                                children: [
                                  Text(_selectedDesignerName, style: const TextStyle(color: QcTheme.gold, fontSize: 11.5, fontWeight: FontWeight.w700)),
                                  if (widget.quote.recommendedDesigners.isNotEmpty) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.check_circle, size: 13, color: QcTheme.gold),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          if (widget.quote.description != null && widget.quote.description!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            const Text('PROJECT DESCRIPTION:', style: TextStyle(color: QcTheme.textSubtle, fontSize: 10, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(widget.quote.description!, style: const TextStyle(color: QcTheme.textMuted, fontSize: 11.5, height: 1.35)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  if (widget.quote.notes != null && widget.quote.notes!.isNotEmpty) ...[
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
                          const Text('SPECIFICATION NOTES:', style: TextStyle(color: QcTheme.textSubtle, fontSize: 10.5, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(widget.quote.notes!, style: const TextStyle(color: QcTheme.textMuted, fontSize: 12.5, height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // AI Recommended Designers Selection List
                  if (widget.quote.recommendedDesigners.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('AI Recommended Designers', style: TextStyle(color: QcTheme.textMain, fontSize: 13.5, fontWeight: FontWeight.w700)),
                        Text('Tap to select candidate', style: TextStyle(color: QcTheme.gold.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: widget.quote.recommendedDesigners.take(3).map((d) {
                        final isSelected = d.designerId == _selectedDesignerId || d.userId == _selectedDesignerId;
                        final matchPct = (d.matchScore * 100).round();
                        final isExpanded = _expandedReasons.contains(d.designerId);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0x24C48A36) : QcTheme.surfaceSunken,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? QcTheme.gold : QcTheme.borderSubtle,
                              width: isSelected ? 1.8 : 1.0,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedDesignerId = d.designerId;
                                _selectedDesignerName = d.displayName;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                        color: isSelected ? QcTheme.gold : QcTheme.textSubtle,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    d.displayName,
                                                    style: TextStyle(
                                                      color: isSelected ? Colors.white : QcTheme.textMain,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                if (isSelected) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                    decoration: BoxDecoration(
                                                      color: QcTheme.gold,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: const Text(
                                                      'SELECTED',
                                                      style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w800),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${d.rating.toStringAsFixed(1)} ★ • \$${d.hourlyRate.toStringAsFixed(0)}/hr',
                                              style: const TextStyle(color: QcTheme.textSubtle, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: matchPct >= 80 ? const Color(0x2E10B981) : const Color(0x2EF59E0B),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '$matchPct% Match',
                                          style: TextStyle(
                                            color: matchPct >= 80 ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Compatibility Reason & Breakdown Toggle
                                  if (d.matchReason != null && d.matchReason!.isNotEmpty) ...[
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
                                        children: [
                                          Expanded(
                                            child: Text(
                                              d.matchReason!,
                                              maxLines: isExpanded ? 6 : 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(color: QcTheme.textMuted, fontSize: 11, height: 1.3),
                                            ),
                                          ),
                                          Icon(
                                            isExpanded ? Icons.expand_less : Icons.expand_more,
                                            size: 16,
                                            color: QcTheme.textSubtle,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Quotation Engine Computed Breakdown
                  if (currentVer != null) ...[
                    const Text('Quotation Engine Breakdown', style: TextStyle(color: QcTheme.textMain, fontSize: 13.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: QcTheme.surfaceSunken,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: QcTheme.borderSubtle),
                      ),
                      child: Column(
                        children: [
                          _buildCostRow('Materials Subtotal', currentVer.materialsSubtotal),
                          _buildCostRow('Labor Subtotal', currentVer.laborSubtotal),
                          _buildCostRow('Design Fee (10%)', currentVer.designFee),
                          _buildCostRow('Contingency (5%)', currentVer.contingencyAmount),
                          _buildCostRow('Tax / VAT (8%)', currentVer.taxAmount),
                          const Divider(color: QcTheme.borderSubtle, height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Quote Cost:', style: TextStyle(color: QcTheme.textMain, fontSize: 13, fontWeight: FontWeight.w700)),
                              Text(
                                QcTheme.formatCurrency(currentVer.totalCost),
                                style: const TextStyle(color: QcTheme.gold, fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Line Items section
                  const Text('Itemized Line Items', style: TextStyle(color: QcTheme.textMain, fontSize: 13.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: QcTheme.surfaceSunken,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: QcTheme.border),
                    ),
                    child: Column(
                      children: [
                        ...((currentVer?.items ?? []).isNotEmpty
                            ? currentVer!.items.map((item) => _buildItemTile(item.description, item.category, item.quantity, item.unitCost, item.lineTotal))
                            : widget.quote.items.map((item) => _buildItemTile(item.description, item.category, item.quantity, item.unitCost, item.calculatedTotal))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Prior Version History if multiple versions exist
                  if (widget.quote.versions.length > 1) ...[
                    const Text('Prior Version History', style: TextStyle(color: QcTheme.textMain, fontSize: 13.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ...widget.quote.versions.where((v) => v.versionNumber != currentVer?.versionNumber).map((v) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: QcTheme.surfaceSunken,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: QcTheme.borderSubtle),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Version ${v.versionNumber} (${v.authorRole})', style: const TextStyle(color: QcTheme.textMuted, fontSize: 12)),
                          Text(QcTheme.formatCurrency(v.totalCost), style: const TextStyle(color: QcTheme.textMain, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],

                  // Export Buttons
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.file_download, size: 16),
                        label: const Text('Export CSV'),
                        onPressed: widget.onExport != null ? () => widget.onExport!('csv') : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: QcTheme.textMain,
                          side: const BorderSide(color: QcTheme.borderLight),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf, size: 16),
                        label: const Text('Export PDF'),
                        onPressed: widget.onExport != null ? () => widget.onExport!('pdf') : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: QcTheme.textMain,
                          side: const BorderSide(color: QcTheme.borderLight),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stage 2 Client Decision Actions
                  if (isReleased && widget.onStage2Decision != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.handshake_outlined, size: 18),
                            label: Text(
                              'Approve with ${_selectedDesignerName.split(" ").first}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              widget.onStage2Decision!('Approve', null, _selectedDesignerId);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: QcTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onStage2Decision!('RequestChanges', 'Client requested scope adjustments.', null);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: QcTheme.textMain,
                            backgroundColor: QcTheme.surfaceSunken,
                            side: const BorderSide(color: QcTheme.borderLight),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
                          ),
                          child: const Text('Request Changes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.thumb_down_outlined, color: Colors.redAccent),
                          tooltip: 'Reject Proposal',
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onStage2Decision!('Reject', 'Declined by client.', null);
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(String title, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: QcTheme.textMuted, fontSize: 12)),
          Text(QcTheme.formatCurrency(amount), style: const TextStyle(color: QcTheme.textMain, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildItemTile(String desc, String category, int qty, double unitCost, double total) {
    final catColor = QcTheme.getCategoryColor(category);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: QcTheme.borderSubtle))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(category, style: TextStyle(color: catColor, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, style: const TextStyle(color: QcTheme.textMain, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  'Qty: $qty × ${QcTheme.formatCurrency(unitCost)}',
                  style: const TextStyle(color: QcTheme.textSubtle, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            QcTheme.formatCurrency(total),
            style: const TextStyle(color: QcTheme.textMain, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
