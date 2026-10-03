import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../models/quote_item.dart';
import '../services/quotes_contracts_service.dart';
import '../theme/qc_theme.dart';

class QuoteFormBottomSheet extends StatefulWidget {
  final Quote? initialQuote;
  final Function(Quote quote) onQuoteSaved;

  const QuoteFormBottomSheet({
    super.key,
    this.initialQuote,
    required this.onQuoteSaved,
  });

  static Future<void> show(
    BuildContext context, {
    Quote? initialQuote,
    required Function(Quote quote) onQuoteSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuoteFormBottomSheet(
        initialQuote: initialQuote,
        onQuoteSaved: onQuoteSaved,
      ),
    );
  }

  @override
  State<QuoteFormBottomSheet> createState() => _QuoteFormBottomSheetState();
}

class _QuoteFormBottomSheetState extends State<QuoteFormBottomSheet> {
  final _service = QuotesContractsService();

  static const List<String> categories = [
    'Other',
    'Design',
    'Labor',
    'Materials',
    'Furniture',
    'Carpentry',
    'Electrical',
    'Painting',
    'Plumbing',
    'Textiles',
  ];

  late TextEditingController _scopeSummaryController;
  late TextEditingController _notesController;
  late List<_ItemFormData> _items;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuote;
    _scopeSummaryController = TextEditingController(text: q?.scopeSummary ?? '');
    _notesController = TextEditingController(text: q?.notes ?? '');

    if (q != null && q.items.isNotEmpty) {
      _items = q.items.map((i) => _ItemFormData(
        id: i.id,
        descriptionController: TextEditingController(text: i.description),
        category: categories.contains(i.category) ? i.category : 'Other',
        quantityController: TextEditingController(text: i.quantity.toString()),
        unitCostController: TextEditingController(text: i.unitCost.toInt().toString()),
      )).toList();
    } else {
      _items = [
        _ItemFormData(
          descriptionController: TextEditingController(),
          category: 'Other',
          quantityController: TextEditingController(text: '1'),
          unitCostController: TextEditingController(text: '0'),
        ),
      ];
    }
  }

  @override
  void dispose() {
    _scopeSummaryController.dispose();
    _notesController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  double get _totalCost {
    return _items.fold(0.0, (sum, i) {
      final qty = int.tryParse(i.quantityController.text) ?? 0;
      final cost = double.tryParse(i.unitCostController.text) ?? 0.0;
      return sum + (qty * cost);
    });
  }

  void _addItem() {
    setState(() {
      _items.add(_ItemFormData(
        descriptionController: TextEditingController(),
        category: 'Other',
        quantityController: TextEditingController(text: '1'),
        unitCostController: TextEditingController(text: '0'),
      ));
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      final removed = _items.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _handleSubmit() async {
    final summary = _scopeSummaryController.text.trim();
    if (summary.isEmpty) {
      setState(() => _errorMessage = 'Please enter a scope summary.');
      return;
    }

    final quoteItems = <QuoteItem>[];
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      final desc = item.descriptionController.text.trim();
      final qty = int.tryParse(item.quantityController.text) ?? 1;
      final unitCost = double.tryParse(item.unitCostController.text) ?? 0.0;

      if (desc.isEmpty) {
        setState(() => _errorMessage = 'Line item #${i + 1} needs a description.');
        return;
      }

      quoteItems.add(QuoteItem(
        id: item.id,
        description: desc,
        category: item.category,
        quantity: qty > 0 ? qty : 1,
        unitCost: unitCost >= 0 ? unitCost : 0,
        totalCost: qty * unitCost,
      ));
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final payload = QuoteFormPayload(
      scopeSummary: summary,
      notes: _notesController.text.trim(),
      items: quoteItems,
      projectRequestId: widget.initialQuote?.projectRequestId,
      designerId: widget.initialQuote?.designerId,
      isAiGenerated: widget.initialQuote?.isAiGenerated ?? false,
    );

    try {
      Quote result;
      if (widget.initialQuote != null) {
        result = await _service.updateQuote(widget.initialQuote!.id, payload);
      } else {
        result = await _service.createQuote(payload);
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onQuoteSaved(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialQuote != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: bottomInset + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: QcTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: QcTheme.border, width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle pill
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
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
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'Revise quote' : 'New quote',
                            style: QcTheme.serifTitle(fontSize: 22),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Build a clear, itemized estimate.',
                            style: TextStyle(
                              color: QcTheme.textMuted,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: QcTheme.textMuted, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: QcTheme.surfaceSunken,
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Scope summary field
                  const Text(
                    'Scope summary',
                    style: TextStyle(
                      color: QcTheme.textMuted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: QcTheme.surfaceSunken,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFC48A36), width: 1.2),
                    ),
                    child: TextField(
                      controller: _scopeSummaryController,
                      style: const TextStyle(color: QcTheme.textMain, fontSize: 13.5),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Modern bedroom redesign',
                        hintStyle: TextStyle(color: QcTheme.textSubtle, fontSize: 13),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Line Items section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Line items',
                        style: TextStyle(
                          color: QcTheme.textMuted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_items.length} item${_items.length == 1 ? '' : 's'}',
                        style: const TextStyle(color: QcTheme.textSubtle, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Items cards
                  ..._items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161311),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: QcTheme.borderSubtle, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item index & Description Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                margin: const EdgeInsets.only(top: 8, right: 10),
                                decoration: const BoxDecoration(
                                  color: Color(0x33C48A36),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${idx + 1}',
                                  style: const TextStyle(
                                    color: QcTheme.gold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: QcTheme.surfaceSunken,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: QcTheme.border, width: 1),
                                  ),
                                  child: TextField(
                                    controller: item.descriptionController,
                                    style: const TextStyle(color: QcTheme.textMain, fontSize: 13),
                                    decoration: const InputDecoration(
                                      hintText: 'Item description',
                                      hintStyle: TextStyle(color: QcTheme.textSubtle, fontSize: 12.5),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ),
                              if (_items.length > 1) ...[
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFE57373)),
                                  onPressed: () => _removeItem(idx),
                                  tooltip: 'Remove',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Category & Qty & Unit Cost row
                          Row(
                            children: [
                              // Category Dropdown
                              Expanded(
                                flex: 3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: QcTheme.surfaceSunken,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: QcTheme.border, width: 1),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: item.category,
                                      isExpanded: true,
                                      dropdownColor: QcTheme.surfaceSunken,
                                      icon: const Icon(Icons.keyboard_arrow_down, color: QcTheme.textMuted, size: 16),
                                      items: categories.map((cat) {
                                        return DropdownMenuItem(
                                          value: cat,
                                          child: Text(cat, style: const TextStyle(color: QcTheme.textMain, fontSize: 12.5)),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => item.category = val);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Quantity input
                              Expanded(
                                flex: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: QcTheme.surfaceSunken,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: QcTheme.border, width: 1),
                                  ),
                                  child: TextField(
                                    controller: item.quantityController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(color: QcTheme.textMain, fontSize: 13),
                                    decoration: const InputDecoration(
                                      labelText: 'Qty',
                                      labelStyle: TextStyle(color: QcTheme.textSubtle, fontSize: 11),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Unit cost input
                              Expanded(
                                flex: 3,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: QcTheme.surfaceSunken,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: QcTheme.border, width: 1),
                                  ),
                                  child: TextField(
                                    controller: item.unitCostController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(color: QcTheme.textMain, fontSize: 13),
                                    decoration: const InputDecoration(
                                      labelText: 'Unit Cost',
                                      labelStyle: TextStyle(color: QcTheme.textSubtle, fontSize: 11),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                  // + Add item button
                  OutlinedButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add, size: 16, color: QcTheme.textMain),
                    label: const Text('Add item', style: TextStyle(color: QcTheme.textMain, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: QcTheme.surfaceSunken,
                      side: const BorderSide(color: QcTheme.borderLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Notes (internal)
                  const Text(
                    'Notes (internal)',
                    style: TextStyle(
                      color: QcTheme.textMuted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: QcTheme.surfaceSunken,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: QcTheme.border, width: 1),
                    ),
                    child: TextField(
                      controller: _notesController,
                      maxLines: 3,
                      style: const TextStyle(color: QcTheme.textMain, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Add context for your team...',
                        hintStyle: TextStyle(color: QcTheme.textSubtle, fontSize: 13),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Total preview
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0x1F2C2723),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: QcTheme.borderSubtle),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Estimated Total:',
                          style: TextStyle(color: QcTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          QcTheme.formatCurrency(_totalCost),
                          style: const TextStyle(color: QcTheme.gold, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0x2EEF4444),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x66EF4444)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFFF87171), fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: QcTheme.textMain,
                            backgroundColor: QcTheme.surfaceSunken,
                            side: const BorderSide(color: QcTheme.borderLight),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: QcTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  isEdit ? 'Save changes' : 'Create quote',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                        ),
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

class _ItemFormData {
  final String? id;
  final TextEditingController descriptionController;
  String category;
  final TextEditingController quantityController;
  final TextEditingController unitCostController;

  _ItemFormData({
    this.id,
    required this.descriptionController,
    required this.category,
    required this.quantityController,
    required this.unitCostController,
  });

  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    unitCostController.dispose();
  }
}
