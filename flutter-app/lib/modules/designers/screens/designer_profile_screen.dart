import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/designer_profile.dart';
import '../models/designer_summary.dart';
import '../models/portfolio_item.dart';
import '../services/designers_api_service.dart';
import 'match_score_breakdown_screen.dart';

class DesignerProfileScreen extends StatefulWidget {
  final int designerId;
  final DesignersApiService? apiService;

  const DesignerProfileScreen({
    super.key,
    required this.designerId,
    this.apiService,
  });

  @override
  State<DesignerProfileScreen> createState() => _DesignerProfileScreenState();
}

class _DesignerProfileScreenState extends State<DesignerProfileScreen> {
  late final DesignersApiService _apiService;
  late Future<({DesignerProfile profile, List<PortfolioItem> portfolio})> _dataFuture;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? DesignersApiService();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _dataFuture = _fetchProfileAndPortfolio();
    });
  }

  Future<({DesignerProfile profile, List<PortfolioItem> portfolio})> _fetchProfileAndPortfolio() async {
    final results = await Future.wait([
      _apiService.getProfile(widget.designerId),
      _apiService.getPortfolioItems(widget.designerId),
    ]);

    final profile = results[0] as DesignerProfile;
    final portfolio = results[1] as List<PortfolioItem>;

    return (profile: profile, portfolio: portfolio);
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return 'LKR ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    return 'LKR ${(amount / 1000).toStringAsFixed(0)}k';
  }

  // Format initials strictly to preserve client privacy
  String _formatClientInitials(String raw) {
    if (raw.isEmpty) return 'Private Client';
    final trimmed = raw.trim();
    if (trimmed.contains('.')) return trimmed;
    if (trimmed.length <= 3) return trimmed.toUpperCase();
    return '${trimmed.split(' ').map((n) => n.isNotEmpty ? n[0] : '').join('.').toUpperCase()}.';
  }

  void _showProjectDetailModal(BuildContext context, PortfolioItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1A17) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFFAF8F5) : const Color(0xFF241611);
    final textSecondary = isDark ? const Color(0xFFA89F91) : const Color(0xFF706558);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full Image View
                  Image.network(
                    item.imageUrl,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 240,
                      color: isDark ? const Color(0xFF2A2420) : const Color(0xFFF3ECE4),
                      child: const Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badges Row
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildStatusBadge(item.completionStatusBadge),
                            if (item.clientInitials.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF29231D) : const Color(0xFFF5EFE7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Client: ${_formatClientInitials(item.clientInitials)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            if (item.budgetRangeLabel.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD97706).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  item.budgetRangeLabel,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          item.title,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Description
                        Text(
                          item.description,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            height: 1.5,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF2E2620) : const Color(0xFFEFE7DE),
                              foregroundColor: textPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'Close',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(ListingStatus status) {
    switch (status) {
      case ListingStatus.published:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF064E3B).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
          ),
          child: Text(
            'Published Project',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: const Color(0xFF059669),
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      case ListingStatus.draft:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFB45309).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
          ),
          child: Text(
            'In Progress (Draft)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: const Color(0xFFD97706),
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      case ListingStatus.archived:
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: Text(
            'Archived',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgMain = isDark ? const Color(0xFF14110E) : const Color(0xFFFAF7F2);
    final cardBg = isDark ? const Color(0xFF1E1A17) : Colors.white;
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
        title: Text(
          'Studio Profile',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: textPrimary,
          ),
        ),
      ),
      body: FutureBuilder<({DesignerProfile profile, List<PortfolioItem> portfolio})>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(accentTerracotta),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      'Unable to load studio profile',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: accentTerracotta),
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final profile = snapshot.data!.profile;
          final portfolio = snapshot.data!.portfolio;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Studio Header Card
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: cardBorder, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFF241611).withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Studio Avatar & Verification Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8C4A3E), Color(0xFFC05621)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                profile.displayName.isNotEmpty
                                    ? profile.displayName[0].toUpperCase()
                                    : 'S',
                                style: GoogleFonts.playfairDisplay(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        profile.displayName,
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w700,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 18,
                                      color: Color(0xFFC05621),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (profile.averageRating != null) ...[
                                      const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
                                      const SizedBox(width: 3),
                                      Text(
                                        profile.averageRating!.toStringAsFixed(2),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
                                          color: textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '• Verified Client Rating',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ] else
                                      Text(
                                        'No ratings yet',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Capacity Badge Pill
                      _buildProfileCapacityBadge(profile),
                      const SizedBox(height: 14),

                      // Bio Statement
                      Text(
                        profile.bio,
                        style: GoogleFonts.plusJakartaSans(
                          color: textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Style Tags
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: profile.styleTags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2A231C) : const Color(0xFFF7F2EB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? const Color(0xFF42372D) : const Color(0xFFE6DDD2),
                              ),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFE6DDD2) : const Color(0xFF5A4D41),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Pricing & Capacity Matrix
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: cardBorder, width: 1.2),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'TYPICAL PROJECT BUDGET',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatCurrency(profile.priceRangeMin)} – ${_formatCurrency(profile.priceRangeMax)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 36, width: 1, color: cardBorder),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'RATE / SQ.FT',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'LKR ${profile.ratePerSqFt.toInt()}',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: const Color(0xFFC05621),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 3. AI Match Score Inspector Callout
                Material(
                  color: isDark ? const Color(0xFF261E18) : const Color(0xFFF5EEE6),
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => MatchScoreBreakdownScreen(
                            designerId: profile.id,
                            styleTags: profile.styleTags,
                            budgetMin: profile.priceRangeMin,
                            budgetMax: profile.priceRangeMax,
                            designerDisplayName: profile.displayName,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFC05621).withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFC05621).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Color(0xFFC05621),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Match Compatibility',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Inspect style, budget & capacity breakdown',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFFC05621),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Portfolio Showcase Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Portfolio Showcase',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      '${portfolio.length} Projects',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (portfolio.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.photo_library_outlined, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            'No published portfolio projects yet.',
                            style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: portfolio.length,
                    itemBuilder: (context, index) {
                      final item = portfolio[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: cardBorder, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF241611).withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showProjectDetailModal(context, item),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image with status pill
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Image.network(
                                        item.imageUrl,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: isDark ? const Color(0xFF2A2420) : const Color(0xFFF3ECE4),
                                          child: const Icon(Icons.apartment, size: 36),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: _buildStatusBadge(item.completionStatusBadge),
                                      ),
                                    ],
                                  ),
                                ),

                                // Project Metadata
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),

                                      // Client Privacy Initials
                                      Row(
                                        children: [
                                          Icon(Icons.person_outline, size: 12, color: textSecondary),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Client: ${_formatClientInitials(item.clientInitials)}',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 10.5,
                                                color: textSecondary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),

                                      // Budget Label
                                      Text(
                                        item.budgetRangeLabel,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? const Color(0xFFF6AD55) : const Color(0xFFB45309),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCapacityBadge(DesignerProfile profile) {
    if (profile.isAtCapacity) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF451A03).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFFF59E0B),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'At Capacity (${profile.activeProjectCount}/${profile.maxConcurrentProjects} projects)',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFFDE68A),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    } else if (profile.isAvailable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF064E3B).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Accepting Projects (${profile.remainingCapacity} slots open)',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFA7F3D0),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Text(
          'Unavailable for Projects',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
  }
}
