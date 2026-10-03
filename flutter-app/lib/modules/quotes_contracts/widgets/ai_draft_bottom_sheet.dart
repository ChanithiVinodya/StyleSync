import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../models/quote_item.dart';
import '../services/quotes_contracts_service.dart';
import '../theme/qc_theme.dart';

class AiDraftBottomSheet extends StatefulWidget {
  final Function(Quote quote) onDraftCreated;

  const AiDraftBottomSheet({
    super.key,
    required this.onDraftCreated,
  });

  static Future<void> show(BuildContext context, {required Function(Quote quote) onDraftCreated}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AiDraftBottomSheet(onDraftCreated: onDraftCreated),
    );
  }

  @override
  State<AiDraftBottomSheet> createState() => _AiDraftBottomSheetState();
}

class _AiDraftBottomSheetState extends State<AiDraftBottomSheet> {
  final _service = QuotesContractsService();

  static const List<String> roomPresets = [
    'Bedroom',
    'Living room',
    'Master bedroom',
    'Kitchen',
    'Dining room',
    'Home office',
    'Bathroom',
  ];

  static const List<String> styleOptions = [
    'Modern',
    'Minimalist',
    'Industrial',
    'Luxury',
    'Traditional',
    'Mid Century Modern',
  ];

  static const List<Map<String, dynamic>> budgetPresets = [
    {'label': '150K – 250K', 'min': 150000.0, 'max': 250000.0},
    {'label': '250K – 500K', 'min': 250000.0, 'max': 500000.0},
    {'label': '500K – 1.0M', 'min': 500000.0, 'max': 1000000.0},
    {'label': '1.0M – 2.5M', 'min': 1000000.0, 'max': 2500000.0},
  ];

  static const List<String> preferenceSuggestions = [
    'Warm recessed lighting',
    'Low-profile oak furniture',
    'Custom built-in storage',
    'Natural textures & linen',
    'Matte black accents',
  ];

  String _roomType = 'Bedroom';
  String _designStyle = 'Modern';
  final _roomSizeController = TextEditingController(text: '200');
  final _budgetMinController = TextEditingController(text: '150000');
  final _budgetMaxController = TextEditingController(text: '250000');
  final _preferencesController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // Preview Mode
  bool _isPreviewMode = false;
  AgentBudgetScopeResponse? _previewResponse;
  final _previewScopeController = TextEditingController();
  List<QuoteItem> _previewItems = [];

  @override
  void dispose() {
    _roomSizeController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _preferencesController.dispose();
    _previewScopeController.dispose();
    super.dispose();
  }

  void _applyBudgetPreset(double min, double max) {
    setState(() {
      _budgetMinController.text = min.toInt().toString();
      _budgetMaxController.text = max.toInt().toString();
    });
  }

  void _appendPreference(String text) {
    final cur = _preferencesController.text.trim();
    if (cur.isEmpty) {
      _preferencesController.text = text;
    } else {
      _preferencesController.text = '$cur, $text';
    }
  }

  Future<void> _handleDraftDirect() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final payload = AiDraftPayload(
      roomType: _roomType,
      roomSizeSqft: double.tryParse(_roomSizeController.text) ?? 200.0,
      budgetMin: double.tryParse(_budgetMinController.text) ?? 150000.0,
      budgetMax: double.tryParse(_budgetMaxController.text) ?? 250000.0,
      styleProfile: _designStyle,
      preferences: _preferencesController.text.trim().isEmpty ? null : _preferencesController.text.trim(),
    );

    try {
      final quote = await _service.draftQuoteFromAgent(payload);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onDraftCreated(quote);
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

  Future<void> _handlePreviewDraft() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final payload = AiDraftPayload(
      roomType: _roomType,
      roomSizeSqft: double.tryParse(_roomSizeController.text) ?? 200.0,
      budgetMin: double.tryParse(_budgetMinController.text) ?? 150000.0,
      budgetMax: double.tryParse(_budgetMaxController.text) ?? 250000.0,
      styleProfile: _designStyle,
      preferences: _preferencesController.text.trim().isEmpty ? null : _preferencesController.text.trim(),
    );

    try {
      final response = await _service.previewQuoteFromAgent(payload);
      if (mounted) {
        setState(() {
          _previewResponse = response;
          _previewScopeController.text = response.scopeSummary;
          _previewItems = List<QuoteItem>.from(response.items);
          _isPreviewMode = true;
          _isLoading = false;
        });
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

  Future<void> _handleSavePreview() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final payload = QuoteFormPayload(
        scopeSummary: _previewScopeController.text.trim().isEmpty
            ? '$_designStyle ${_roomType.toLowerCase()} refresh'
            : _previewScopeController.text.trim(),
        notes: _previewResponse?.notes ?? 'Drafted by AI Agent',
        items: _previewItems,
        isAiGenerated: true,
      );

      final quote = await _service.createQuote(payload);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onDraftCreated(quote);
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

          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              child: _isPreviewMode ? _buildPreviewView() : _buildConfigView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigView() {
    final curMin = double.tryParse(_budgetMinController.text) ?? 0.0;
    final curMax = double.tryParse(_budgetMaxController.text) ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget & Scope AI\nAgent',
                    style: QcTheme.serifTitle(fontSize: 22),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Configure the room and budget to draft an itemized scope.',
                    style: TextStyle(
                      color: QcTheme.textMuted,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
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
        const SizedBox(height: 12),

        // Student 3 Badge Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0x1AC48A36),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: QcTheme.primary, width: 1),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, color: QcTheme.gold, size: 12),
              SizedBox(width: 6),
              Text(
                'STUDENT 3 AGENT',
                style: TextStyle(
                  color: QcTheme.gold,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Room Type
        const Text(
          'Room type',
          style: TextStyle(
            color: QcTheme.textMuted,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: roomPresets.map((room) {
            final isSelected = _roomType.toLowerCase() == room.toLowerCase();
            return InkWell(
              onTap: () => setState(() => _roomType = room),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? QcTheme.primary : QcTheme.surfaceSunken,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? QcTheme.primary : QcTheme.border,
                    width: 1,
                  ),
                ),
                child: Text(
                  room,
                  style: TextStyle(
                    color: isSelected ? Colors.white : QcTheme.textMain,
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),

        // Two Column: Room size & Design style
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Room size (sq ft)',
                    style: TextStyle(
                      color: QcTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildTextInput(_roomSizeController, keyboardType: TextInputType.number),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Design style',
                    style: TextStyle(
                      color: QcTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildDropdown(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Two Column: Budget min & Budget max
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Budget min (LKR)',
                    style: TextStyle(
                      color: QcTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildTextInput(_budgetMinController, keyboardType: TextInputType.number),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Budget max (LKR)',
                    style: TextStyle(
                      color: QcTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildTextInput(_budgetMaxController, keyboardType: TextInputType.number),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Quick budget presets
        const Text(
          'Quick budget presets',
          style: TextStyle(
            color: QcTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: budgetPresets.map((preset) {
            final isSelected = curMin == preset['min'] && curMax == preset['max'];
            return InkWell(
              onTap: () => _applyBudgetPreset(preset['min'] as double, preset['max'] as double),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? QcTheme.primary : QcTheme.surfaceSunken,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? QcTheme.primary : QcTheme.border,
                    width: 1,
                  ),
                ),
                child: Text(
                  preset['label'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : QcTheme.textMain,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),

        // Client preferences (optional)
        const Text(
          'Client preferences (optional)',
          style: TextStyle(
            color: QcTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        _buildTextInput(
          _preferencesController,
          hint: 'e.g. warm neutral tones, low-profile oak',
          maxLines: 2,
        ),
        const SizedBox(height: 8),

        // Suggestion chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: preferenceSuggestions.map((pref) {
            return InkWell(
              onTap: () => _appendPreference(pref),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x1F2C2723),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: QcTheme.borderLight, width: 0.8),
                ),
                child: Text(
                  '+ $pref',
                  style: const TextStyle(
                    color: QcTheme.textSubtle,
                    fontSize: 11,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),

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

        // Footer buttons
        Row(
          children: [
            Expanded(
              flex: 2,
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
            const SizedBox(width: 8),
            // Preview draft button
            IconButton(
              onPressed: _isLoading ? null : _handlePreviewDraft,
              tooltip: 'Inspect items before saving',
              icon: const Icon(Icons.remove_red_eye_outlined, color: QcTheme.gold),
              style: IconButton.styleFrom(
                backgroundColor: QcTheme.surfaceSunken,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: QcTheme.borderLight),
                padding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(width: 8),
            // Primary Draft quote button
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: QcTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4DC48A36),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleDraftDirect,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                  label: Text(
                    _isLoading ? 'Drafting…' : 'Draft quote with AI',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewView() {
    final total = _previewItems.fold(0.0, (sum, i) => sum + i.calculatedTotal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Review AI Draft', style: QcTheme.serifTitle(fontSize: 20)),
                const SizedBox(height: 2),
                Text(
                  'Engine: ${_previewResponse?.source == 'llm' ? 'Claude LLM' : 'Deterministic Ratios'}',
                  style: const TextStyle(color: QcTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.arrow_back, color: QcTheme.textMuted),
              onPressed: () => setState(() => _isPreviewMode = false),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Scope Summary Editable
        const Text(
          'Scope Summary',
          style: TextStyle(color: QcTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        _buildTextInput(_previewScopeController),
        const SizedBox(height: 12),

        // Estimated Total Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: QcTheme.surfaceSunken,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: QcTheme.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ESTIMATED TOTAL',
                style: TextStyle(color: QcTheme.textSubtle, fontSize: 11, fontWeight: FontWeight.w700),
              ),
              Text(
                QcTheme.formatCurrency(total),
                style: const TextStyle(color: QcTheme.gold, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Items list
        const Text(
          'Generated Line Items',
          style: TextStyle(color: QcTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        ..._previewItems.map((item) {
          final catColor = QcTheme.getCategoryColor(item.category);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: QcTheme.surfaceSunken,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: QcTheme.borderSubtle),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.category,
                    style: TextStyle(color: catColor, fontSize: 10.5, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.description,
                    style: const TextStyle(color: QcTheme.textMain, fontSize: 12.5, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  QcTheme.formatCurrency(item.calculatedTotal),
                  style: const TextStyle(color: QcTheme.textMain, fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _isPreviewMode = false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: QcTheme.textMain,
                  backgroundColor: QcTheme.surfaceSunken,
                  side: const BorderSide(color: QcTheme.borderLight),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSavePreview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: QcTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _isLoading ? 'Saving…' : 'Save as Quote Draft',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextInput(TextEditingController controller, {String? hint, TextInputType? keyboardType, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: QcTheme.surfaceSunken,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: QcTheme.border, width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: QcTheme.textMain, fontSize: 13.5),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: QcTheme.textSubtle, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: QcTheme.surfaceSunken,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: QcTheme.border, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _designStyle,
          isExpanded: true,
          dropdownColor: QcTheme.surfaceSunken,
          icon: const Icon(Icons.keyboard_arrow_down, color: QcTheme.textMuted, size: 18),
          items: styleOptions.map((style) {
            return DropdownMenuItem(
              value: style,
              child: Text(
                style,
                style: const TextStyle(color: QcTheme.textMain, fontSize: 13.5),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _designStyle = val);
          },
        ),
      ),
    );
  }
}
