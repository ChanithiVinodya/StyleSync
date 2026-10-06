import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/designers/designer_filter_provider.dart';
import '../models/designer_summary.dart';
import '../models/paged_result.dart';
import '../services/designers_api_service.dart';
import '../widgets/designer_card.dart';
import '../widgets/designer_filter_sheet.dart';
import 'designer_profile_screen.dart';

class DesignerListingScreen extends ConsumerStatefulWidget {
  final DesignersApiService? apiService;
  final String? initialStyle;
  final DesignerQueryParameters? initialParams;

  const DesignerListingScreen({
    super.key,
    this.apiService,
    this.initialStyle,
    this.initialParams,
  });

  @override
  ConsumerState<DesignerListingScreen> createState() =>
      _DesignerListingScreenState();
}

class _DesignerListingScreenState extends ConsumerState<DesignerListingScreen> {
  late final DesignersApiService _apiService;

  DesignerQueryParameters _params = const DesignerQueryParameters(
    page: 1,
    pageSize: 10,
    sort: 'newest',
  );

  bool _isLoading = true;
  String? _errorMessage;
  PagedResult<DesignerSummary>? _result;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? DesignersApiService();

    if (widget.initialParams != null) {
      _params = widget.initialParams!;
    } else if (widget.initialStyle != null &&
        widget.initialStyle!.trim().isNotEmpty) {
      _params = DesignerQueryParameters(
        style: widget.initialStyle!.trim(),
        page: 1,
        pageSize: 10,
        sort: 'newest',
      );
    } else {
      _params = ref.read(designerFilterProvider);
    }

    _fetchListings();
  }

  void _applyParams(DesignerQueryParameters newParams) {
    setState(() => _params = newParams);
    ref.read(designerFilterProvider.notifier).setParams(newParams);
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
          _errorMessage = 'Unable to connect to the designer directory.';
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
          _applyParams(newParams);
        },
        onReset: () {
          _applyParams(const DesignerQueryParameters(
            page: 1,
            pageSize: 10,
            sort: 'newest',
          ));
        },
      ),
    );
  }

  void _onPageChanged(int newPage) {
    if (_result == null || newPage < 1 || newPage > _result!.totalPages) return;
    _applyParams(_params.copyWith(page: newPage));
  }

  String _budgetFilterLabel() {
    if (_params.budgetMin != null && _params.budgetMax != null) {
      return 'Budget: LKR ${(_params.budgetMin! / 1000).toStringAsFixed(0)}k - ${(_params.budgetMax! / 1000).toStringAsFixed(0)}k';
    } else if (_params.budgetMin != null) {
      return 'Budget: ≥ LKR ${(_params.budgetMin! / 1000).toStringAsFixed(0)}k';
    } else if (_params.budgetMax != null) {
      return 'Budget: ≤ LKR ${(_params.budgetMax! / 1000).toStringAsFixed(0)}k';
    }
    return 'Budget';
  }

  @override
  Widget build(BuildContext context) {
    // Listen to global designerFilterProvider updates (e.g. from Home screen style/category taps)
    ref.listen<DesignerQueryParameters>(designerFilterProvider, (previous, next) {
      if (previous != next && next != _params) {
        setState(() {
          _params = next;
        });
        _fetchListings();
      }
    });

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasActiveFilters = (_params.style != null && _params.style != 'All') ||
        _params.budgetMin != null ||
        _params.budgetMax != null ||
        _params.available != null;

    final bgMain = isDark ? const Color(0xFF14110E) : const Color(0xFFFAF7F2);
    final cardBorder = isDark ? const Color(0xFF332B25) : const Color(0xFFEDE5DC);
    final textPrimary = isDark ? const Color(0xFFFAF8F5) : const Color(0xFF241611);
    final textSecondary = isDark ? const Color(0xFFA89F91) : const Color(0xFF706558);
    const accentTerracotta = Color(0xFF8C4A3E);

    return Scaffold(
      backgroundColor: bgMain,
      appBar: AppBar(
        backgroundColor: bgMain,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interior Designers',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Curated Studios & Architectural Specialists',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.filledTonal(
              style: IconButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF241E19)
                    : const Color(0xFFEFE7DE),
                foregroundColor: textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: cardBorder),
                ),
              ),
              icon: Badge(
                isLabelVisible: hasActiveFilters,
                backgroundColor: accentTerracotta,
                smallSize: 8,
                child: const Icon(Icons.tune_rounded, size: 20),
              ),
              tooltip: 'Filter & Refine',
              onPressed: _openFilterSheet,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: accentTerracotta,
        onRefresh: _fetchListings,
        child: Column(
          children: [
            const SizedBox(height: 6),

            // Style Quick-Pills Filter Carousel
            Container(
              height: 46,
              margin: const EdgeInsets.only(bottom: 6),
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
                    selected: isSelected,
                    showCheckmark: false,
                    avatar: isSelected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? const Color(0xFFD6CFC7) : const Color(0xFF4A4036)),
                    ),
                    selectedColor: accentTerracotta,
                    backgroundColor: isDark
                        ? const Color(0xFF221C18)
                        : const Color(0xFFF0EAE1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? accentTerracotta
                            : (isDark ? const Color(0xFF3D322A) : const Color(0xFFE4D9CE)),
                        width: 1.2,
                      ),
                    ),
                    onSelected: (selected) {
                      _applyParams(_params.copyWith(
                        style: selected ? style : 'All',
                        clearStyle: !selected || style == 'All',
                        page: 1,
                      ));
                    },
                  );
                },
              ),
            ),

            // Active Removable Filter Chips Banner
            if (hasActiveFilters)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (_params.style != null && _params.style != 'All') ...[
                        InputChip(
                          avatar: const Icon(
                            Icons.style_outlined,
                            size: 14,
                            color: accentTerracotta,
                          ),
                          label: Text('Style: ${_params.style}'),
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFFAF8F5)
                                : const Color(0xFF241611),
                          ),
                          backgroundColor: isDark
                              ? const Color(0xFF2A221C)
                              : const Color(0xFFEDE3D8),
                          deleteIcon: const Icon(Icons.close_rounded, size: 15),
                          deleteIconColor: accentTerracotta,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: accentTerracotta.withValues(alpha: 0.5),
                              width: 1.1,
                            ),
                          ),
                          onDeleted: () {
                            _applyParams(_params.copyWith(clearStyle: true, page: 1));
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (_params.budgetMin != null || _params.budgetMax != null) ...[
                        InputChip(
                          avatar: const Icon(
                            Icons.payments_outlined,
                            size: 14,
                            color: accentTerracotta,
                          ),
                          label: Text(_budgetFilterLabel()),
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFFAF8F5)
                                : const Color(0xFF241611),
                          ),
                          backgroundColor: isDark
                              ? const Color(0xFF2A221C)
                              : const Color(0xFFEDE3D8),
                          deleteIcon: const Icon(Icons.close_rounded, size: 15),
                          deleteIconColor: accentTerracotta,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: accentTerracotta.withValues(alpha: 0.5),
                              width: 1.1,
                            ),
                          ),
                          onDeleted: () {
                            _applyParams(_params.copyWith(clearBudget: true, page: 1));
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (_params.available != null) ...[
                        InputChip(
                          avatar: const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 14,
                            color: accentTerracotta,
                          ),
                          label: Text(_params.available == true
                              ? 'Available Only'
                              : 'All Statuses'),
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFFAF8F5)
                                : const Color(0xFF241611),
                          ),
                          backgroundColor: isDark
                              ? const Color(0xFF2A221C)
                              : const Color(0xFFEDE3D8),
                          deleteIcon: const Icon(Icons.close_rounded, size: 15),
                          deleteIconColor: accentTerracotta,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: accentTerracotta.withValues(alpha: 0.5),
                              width: 1.1,
                            ),
                          ),
                          onDeleted: () {
                            _applyParams(_params.copyWith(clearAvailable: true, page: 1));
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                      TextButton(
                        onPressed: () {
                          _applyParams(const DesignerQueryParameters(
                            page: 1,
                            pageSize: 10,
                            sort: 'newest',
                          ));
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Clear all',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: accentTerracotta,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Main Listing Stream Area
            Expanded(
              child: _buildBodyContent(theme, isDark, textPrimary, textSecondary),
            ),

            // Sticky Bottom Pagination Bar
            if (_result != null && _result!.totalPages > 1)
              _buildPaginationBar(theme, isDark, cardBorder, textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent(
    ThemeData theme,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8C4A3E)),
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 16),
            Text(
              'Curating interior studios...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wifi_off_rounded, size: 32, color: Colors.redAccent),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8C4A3E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _fetchListings,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'Refresh Directory',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                ),
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
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF221C17) : const Color(0xFFF3ECE4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chair_outlined,
                  size: 36,
                  color: isDark ? const Color(0xFF78695C) : const Color(0xFFA89A8C),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'No Studios Found',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try broadening your style selection or adjusting your budget range.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: textSecondary,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8C4A3E),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  setState(() {
                    _params = const DesignerQueryParameters(
                      page: 1,
                      pageSize: 10,
                      sort: 'newest',
                    );
                  });
                  _fetchListings();
                },
                child: Text(
                  'Reset All Filters',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Results List
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _result!.items.length,
      itemBuilder: (context, index) {
        final designer = _result!.items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
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

  Widget _buildPaginationBar(
    ThemeData theme,
    bool isDark,
    Color cardBorder,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1613) : Colors.white,
        border: Border(
          top: BorderSide(color: cardBorder, width: 1.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${_result!.page} of ${_result!.totalPages} (${_result!.totalCount} studios)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          Row(
            children: [
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF26201B)
                      : const Color(0xFFF3EBE2),
                ),
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: _result!.hasPreviousPage
                    ? () => _onPageChanged(_result!.page - 1)
                    : null,
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF26201B)
                      : const Color(0xFFF3EBE2),
                ),
                icon: const Icon(Icons.chevron_right_rounded),
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
