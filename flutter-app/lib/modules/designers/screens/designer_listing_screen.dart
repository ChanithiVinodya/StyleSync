import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
          setState(() => _params = newParams);
          _fetchListings();
        },
        onReset: () {
          setState(() {
            _params = const DesignerQueryParameters(
              page: 1,
              pageSize: 10,
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

            // Active Filters Sub-Header Banner
            if (hasActiveFilters)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF26201A) : const Color(0xFFF2ECE3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF3D332A) : const Color(0xFFE5DBD0),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.filter_alt_outlined,
                      size: 16,
                      color: accentTerracotta,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _buildFilterSummaryText(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        setState(() {
                          _params = const DesignerQueryParameters(
                            page: 1,
                            pageSize: 10,
                            sort: 'newest',
                          );
                        });
                        _fetchListings();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          'Reset',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: accentTerracotta,
                          ),
                        ),
                      ),
                    ),
                  ],
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
      parts.add('Accepting Only');
    }
    return parts.join(' • ');
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
                  color: Colors.red.withOpacity(0.12),
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
