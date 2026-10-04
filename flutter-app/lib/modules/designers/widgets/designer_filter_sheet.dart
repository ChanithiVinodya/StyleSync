import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Sheet Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter & Sort Designers',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _resetFilters,
                    child: const Text('Reset All'),
                  ),
                ],
              ),
              const Divider(),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Sort By Section
                    Text(
                      'Sort By',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedSort,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'newest', child: Text('Newest Studios')),
                        DropdownMenuItem(
                            value: 'rating', child: Text('Highest Rating')),
                        DropdownMenuItem(
                            value: 'price_asc',
                            child: Text('Price: Low to High')),
                        DropdownMenuItem(
                            value: 'price_desc',
                            child: Text('Price: High to Low')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSort = val);
                      },
                    ),
                    const SizedBox(height: 20),

                    // Availability Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Open Capacity Only',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Only show designers currently accepting projects',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _availableOnly,
                      onChanged: (val) => setState(() => _availableOnly = val),
                    ),
                    const SizedBox(height: 16),

                    // Budget Range Section
                    Text(
                      'Project Budget Range (LKR)',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minBudgetController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Min Budget',
                              hintText: 'e.g. 100000',
                              prefixText: 'LKR ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _maxBudgetController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Max Budget',
                              hintText: 'e.g. 500000',
                              prefixText: 'LKR ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Style Tags Section
                    Text(
                      'Design Aesthetics & Style',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: DesignerFilterSheet.popularStyles.map((style) {
                        final isSelected = _selectedStyle.toLowerCase() ==
                            style.toLowerCase();
                        return FilterChip(
                          label: Text(style),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedStyle = selected ? style : 'All';
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Apply Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _applyFilters,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
