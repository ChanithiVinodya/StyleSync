import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/designer_summary.dart';

class DesignerFilterSheet extends StatefulWidget {
  final DesignerQueryParameters currentParams;
  final ValueChanged<DesignerQueryParameters> onApply;
  final VoidCallback onReset;

  const DesignerFilterSheet({
    super.key,
    required this.currentParams,
    required this.onApply,
    required this.onReset,
  });

  static const List<String> popularStyles = [
    'All',
    'Tropical Modernism',
    'Minimalist',
    'Japandi',
    'Scandinavian',
    'Boho Chic',
    'Industrial',
    'Coastal',
    'Classic Luxury',
    'Contemporary',
    'Biophilic'
  ];

  @override
  State<DesignerFilterSheet> createState() => _DesignerFilterSheetState();
}

class _DesignerFilterSheetState extends State<DesignerFilterSheet> {
  late String _selectedStyle;
  late TextEditingController _minBudgetController;
  late TextEditingController _maxBudgetController;
  late bool _availableOnly;
  late String _selectedSort;

  @override
  void initState() {
    super.initState();
    _selectedStyle = widget.currentParams.style ?? 'All';
    _minBudgetController = TextEditingController(
      text: widget.currentParams.budgetMin != null
          ? widget.currentParams.budgetMin!.toInt().toString()
          : '',
    );
    _maxBudgetController = TextEditingController(
      text: widget.currentParams.budgetMax != null
          ? widget.currentParams.budgetMax!.toInt().toString()
          : '',
    );
    _availableOnly = widget.currentParams.available == true;
    _selectedSort = widget.currentParams.sort ?? 'newest';
  }

  @override
  void dispose() {
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final minVal = double.tryParse(_minBudgetController.text.trim());
    final maxVal = double.tryParse(_maxBudgetController.text.trim());

    final updated = widget.currentParams.copyWith(
      style: _selectedStyle == 'All' ? null : _selectedStyle,
      clearStyle: _selectedStyle == 'All',
      budgetMin: minVal,
      clearBudget: minVal == null && maxVal == null,
      budgetMax: maxVal,
      available: _availableOnly ? true : null,
      clearAvailable: !_availableOnly,
      sort: _selectedSort,
      page: 1,
    );

    widget.onApply(updated);
    Navigator.of(context).pop();
  }

  void _resetFilters() {
    widget.onReset();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sheetBg = isDark ? const Color(0xFF1E1A17) : const Color(0xFFFAF7F2);
    final cardBorder = isDark ? const Color(0xFF332B25) : const Color(0xFFEDE5DC);
    final textPrimary = isDark ? const Color(0xFFFAF8F5) : const Color(0xFF241611);
    final textSecondary = isDark ? const Color(0xFFA89F91) : const Color(0xFF706558);
    const accentTerracotta = Color(0xFF8C4A3E);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Sheet Drag Pill Handle
              Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF4A3E35) : const Color(0xFFD6C9BC),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),

              // Sheet Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Studios',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: _resetFilters,
                    child: Text(
                      'Reset All',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: accentTerracotta,
                      ),
                    ),
                  ),
                ],
              ),
              Divider(color: cardBorder, height: 1),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    // 1. Sort By
                    Text(
                      'Sort Directory By',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedSort,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? const Color(0xFF26201B) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: cardBorder),
                        ),
                      ),
                      dropdownColor: sheetBg,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'newest', child: Text('Newest Listings')),
                        DropdownMenuItem(value: 'rating', child: Text('Highest Client Rating')),
                        DropdownMenuItem(value: 'price_low_high', child: Text('Rate: Low to High')),
                        DropdownMenuItem(value: 'price_high_low', child: Text('Rate: High to Low')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSort = val);
                      },
                    ),
                    const SizedBox(height: 20),

                    // 2. Style Aesthetic Selection
                    Text(
                      'Design Aesthetic',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: DesignerFilterSheet.popularStyles.map((style) {
                        final isSelected = _selectedStyle.toLowerCase() == style.toLowerCase();
                        return ChoiceChip(
                          label: Text(style),
                          selected: isSelected,
                          showCheckmark: false,
                          avatar: isSelected
                              ? const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white)
                              : null,
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? const Color(0xFFD6CFC7) : const Color(0xFF4A4036)),
                          ),
                          selectedColor: accentTerracotta,
                          backgroundColor: isDark ? const Color(0xFF26201B) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected ? accentTerracotta : cardBorder,
                            ),
                          ),
                          onSelected: (selected) {
                            setState(() => _selectedStyle = selected ? style : 'All');
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // 3. Budget Range Inputs
                    Text(
                      'Project Budget Range (LKR)',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minBudgetController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Min Budget',
                              hintText: 'e.g. 100000',
                              prefixText: 'LKR ',
                              filled: true,
                              fillColor: isDark ? const Color(0xFF26201B) : Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: cardBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: cardBorder),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _maxBudgetController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Max Budget',
                              hintText: 'e.g. 800000',
                              prefixText: 'LKR ',
                              filled: true,
                              fillColor: isDark ? const Color(0xFF26201B) : Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: cardBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: cardBorder),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 4. Availability Switch
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF26201B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorder),
                      ),
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        activeColor: accentTerracotta,
                        title: Text(
                          'Accepting Projects Only',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Filter out studios currently at maximum capacity',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: textSecondary),
                        ),
                        value: _availableOnly,
                        onChanged: (val) => setState(() => _availableOnly = val),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Apply Filters Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: accentTerracotta,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _applyFilters,
                  child: Text(
                    'Apply Filters',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
