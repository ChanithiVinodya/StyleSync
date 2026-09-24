import 'package:flutter/material.dart';
import '../models/designer_summary.dart';
import '../models/paged_result.dart';
import '../services/designers_api_service.dart';
import '../widgets/designer_card.dart';
import '../widgets/designer_filter_sheet.dart';
import 'designer_profile_screen.dart';

class DesignerListingScreen extends StatefulWidget {
  final DesignersApiService? apiService;

  const DesignerListingScreen({super.key, this.apiService});

  @override
  State<DesignerListingScreen> createState() => _DesignerListingScreenState();
}

class _DesignerListingScreenState extends State<DesignerListingScreen> {
  late final DesignersApiService _apiService;

  DesignerQueryParameters _params = const DesignerQueryParameters(
    page: 1,
    pageSize: 6,
    sort: 'newest',
  );

  bool _isLoading = true;
  String? _errorMessage;
  PagedResult<DesignerSummary>? _result;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? DesignersApiService();
    _fetchListings();
  }

  Future<void> _fetchListings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final paged = await _apiService.getListings(_params);
      if (mounted) {
        setState(() {
          _result = paged;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load designer directory.';
          _isLoading = false;
        });
      }
    }
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DesignerFilterSheet(
        currentParams: _params,
        onApply: (newParams) {
          setState(() => _params = newParams);
          _fetchListings();
        },
        onReset: () {
          setState(() {
            _params = const DesignerQueryParameters(
              page: 1,
              pageSize: 6,
              sort: 'newest',
            );
          });
          _fetchListings();
        },
      ),
    );
  }

  void _onPageChanged(int newPage) {
    if (_result == null || newPage < 1 || newPage > _result!.totalPages) return;
    setState(() {
      _params = _params.copyWith(page: newPage);
    });
    _fetchListings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasActiveFilters = (_params.style != null && _params.style != 'All') ||
        _params.budgetMin != null ||
        _params.budgetMax != null ||
        _params.available != null;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Interior Designers',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Certified Architecture & Design Studios',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: hasActiveFilters,
              child: const Icon(Icons.tune_rounded),
            ),
            tooltip: 'Filter & Sort',
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchListings,
        child: Column(
          children: [
            // Style Chips Quick Scroll Row
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: DesignerFilterSheet.popularStyles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final style = DesignerFilterSheet.popularStyles[index];
                  final isSelected =
                      (_params.style ?? 'All').toLowerCase() ==
                          style.toLowerCase();

                  return ChoiceChip(
                    label: Text(style),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _params = _params.copyWith(
                          style: selected ? style : 'All',
                          clearStyle: !selected || style == 'All',
                          page: 1,
                        );
                      });
                      _fetchListings();
                    },
                  );
                },
              ),
            ),

            // Active Filters Summary Bar
            if (hasActiveFilters)
              Container(
                color: isDark ? const Color(0xFF24201D) : const Color(0xFFF3EEE5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt_outlined,
                        size: 14, color: Colors.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _buildFilterSummaryText(),
                        style: const TextStyle(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _params = const DesignerQueryParameters(
                            page: 1,
                            pageSize: 6,
                            sort: 'newest',
                          );
                        });
                        _fetchListings();
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Main Content Area
            Expanded(
              child: _buildBodyContent(theme),
            ),

            // Pagination Controls Footer
            if (_result != null && _result!.totalPages > 1)
              _buildPaginationBar(theme),
          ],
        ),
      ),
    );
  }

  String _buildFilterSummaryText() {
    final parts = <String>[];
    if (_params.style != null && _params.style != 'All') {
      parts.add('Style: ${_params.style}');
    }
    if (_params.budgetMin != null || _params.budgetMax != null) {
      final minStr = _params.budgetMin != null
          ? 'LKR ${(_params.budgetMin! / 1000).toStringAsFixed(0)}k'
          : '0';
      final maxStr = _params.budgetMax != null
          ? 'LKR ${(_params.budgetMax! / 1000).toStringAsFixed(0)}k'
          : 'Any';
      parts.add('Budget: $minStr - $maxStr');
    }
    if (_params.available == true) {
      parts.add('Available Only');
    }
    return parts.join(' • ');
  }

  Widget _buildBodyContent(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Loading designer listings...',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(_errorMessage!,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: _fetchListings,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_result == null || _result!.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No published designers found',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try broadening your style, budget range, or availability filter options.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _params = const DesignerQueryParameters(
                      page: 1,
                      pageSize: 6,
                      sort: 'newest',
                    );
                  });
                  _fetchListings();
                },
                child: const Text('Reset All Filters'),
              ),
            ],
          ),
        ),
      );
    }

    // Results List
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _result!.items.length,
      itemBuilder: (context, index) {
        final designer = _result!.items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DesignerCard(
            designer: designer,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      DesignerProfileScreen(designerId: designer.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPaginationBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${_result!.page} of ${_result!.totalPages} (${_result!.totalCount} studios)',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _result!.hasPreviousPage
                    ? () => _onPageChanged(_result!.page - 1)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _result!.hasNextPage
                    ? () => _onPageChanged(_result!.page + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
