import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/match_score_breakdown.dart';
import '../services/designers_api_service.dart';

/// Screen shown when a client opens a designer from their AI-generated shortlist.
///
/// Accepts the designerId plus the styleTags/budgetMin/budgetMax the client's request
/// was scored against (passed in from the shortlist screen - do not re-fetch or guess).
/// Calls GET /api/designers/{id}/match-score?styleTags=&budgetMin=&budgetMax=
/// and renders the 4 components in plain language alongside the overall matchScore.
/// Pure read-only explanation view.
class MatchScoreBreakdownScreen extends StatefulWidget {
  final int designerId;
  final List<String> styleTags;
  final double budgetMin;
  final double budgetMax;
  final String? designerDisplayName;
  final DesignersApiService? apiService;

  const MatchScoreBreakdownScreen({
    super.key,
    required this.designerId,
    required this.styleTags,
    required this.budgetMin,
    required this.budgetMax,
    this.designerDisplayName,
    this.apiService,
  });

  @override
  State<MatchScoreBreakdownScreen> createState() =>
      _MatchScoreBreakdownScreenState();
}

class _MatchScoreBreakdownScreenState extends State<MatchScoreBreakdownScreen> {
  late final DesignersApiService _apiService;
  late Future<MatchScoreBreakdownResponse> _scoreFuture;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? DesignersApiService();
    _loadScore();
  }

  void _loadScore() {
    setState(() {
      _scoreFuture = _apiService.getMatchScoreBreakdown(
        designerId: widget.designerId,
        styleTags: widget.styleTags,
        budgetMin: widget.budgetMin,
        budgetMax: widget.budgetMax,
      );
    });
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return 'LKR ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    return 'LKR ${(amount / 1000).toStringAsFixed(0)}k';
  }

  String _getMatchTier(double score) {
    if (score >= 0.85) return 'Exceptional Match';
    if (score >= 0.70) return 'Strong Match';
    if (score >= 0.50) return 'Good Match';
    return 'Moderate Match';
  }

  Color _getScoreColor(double score, bool isDark) {
    if (score >= 0.80) return const Color(0xFF059669); // Emerald
    if (score >= 0.60) return const Color(0xFFD97706); // Warm Amber
    return const Color(0xFFC05621); // Terracotta
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        title: Text(
          widget.designerDisplayName != null
              ? '${widget.designerDisplayName} - Match Breakdown'
              : 'Match Score Explanation',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: textPrimary,
          ),
        ),
      ),
      body: FutureBuilder<MatchScoreBreakdownResponse>(
        future: _scoreFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(accentTerracotta),
                    strokeWidth: 2.5,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Evaluating compatibility parameters...',
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

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 48, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load match breakdown.',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: accentTerracotta),
                      onPressed: _loadScore,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        'Retry',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final breakdown = snapshot.data!;
          return _buildExplanationContent(context, breakdown, isDark, cardBorder, textPrimary, textSecondary);
        },
      ),
    );
  }

  Widget _buildExplanationContent(
    BuildContext context,
    MatchScoreBreakdownResponse data,
    bool isDark,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    final stylePct = (data.styleTagOverlapPct * 100).round();
    final budgetPct = (data.budgetRangeOverlapPct * 100).round();
    final totalPct = (data.matchScore * 100).round();
    final scoreColor = _getScoreColor(data.matchScore, isDark);
    final cardBg = isDark ? const Color(0xFF1E1A17) : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Overall Match Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cardBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.3) : const Color(0xFF241611).withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OVERALL COMPATIBILITY',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalPct% Match',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: scoreColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: scoreColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        _getMatchTier(data.matchScore),
                        style: GoogleFonts.plusJakartaSans(
                          color: scoreColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: data.matchScore.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Deterministic Weighted Formula: 40% Style + 30% Budget + 20% Rating + 10% Availability',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section Title
          Text(
            'Component Breakdown',
            style: GoogleFonts.playfairDisplay(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Transparent explanation of how your criteria aligned with this studio.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: textSecondary,
            ),
          ),

          const SizedBox(height: 14),

          // 2. Component 1: Style Match (40% Weight)
          _buildBreakdownCard(
            context: context,
            isDark: isDark,
            cardBg: cardBg,
            cardBorder: cardBorder,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            icon: Icons.palette_outlined,
            iconColor: const Color(0xFF805AD5),
            title: 'Style Compatibility',
            weightLabel: '40% Weight',
            plainLanguageExplanation:
                "Style match: $stylePct% of your requested style overlaps with this designer's work",
            progressValue: data.styleTagOverlapPct,
            extraContent: widget.styleTags.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.styleTags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF805AD5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF805AD5).withOpacity(0.25)),
                          ),
                          child: Text(
                            '# $tag',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF805AD5),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : null,
          ),

          const SizedBox(height: 12),

          // 3. Component 2: Budget Fit (30% Weight)
          _buildBreakdownCard(
            context: context,
            isDark: isDark,
            cardBg: cardBg,
            cardBorder: cardBorder,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            icon: Icons.account_balance_wallet_outlined,
            iconColor: const Color(0xFF2B6CB0),
            title: 'Budget Fit',
            weightLabel: '30% Weight',
            plainLanguageExplanation:
                "Budget fit: your budget range overlaps $budgetPct% with their pricing",
            progressValue: data.budgetRangeOverlapPct,
            extraContent: (widget.budgetMin > 0 || widget.budgetMax > 0)
                ? Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Requested budget: ${_formatCurrency(widget.budgetMin)} - ${_formatCurrency(widget.budgetMax)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  )
                : null,
          ),

          const SizedBox(height: 12),

          // 4. Component 3: Past Rating (20% Weight)
          _buildBreakdownCard(
            context: context,
            isDark: isDark,
            cardBg: cardBg,
            cardBorder: cardBorder,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            icon: Icons.star_outline_rounded,
            iconColor: const Color(0xFFD69E2E),
            title: 'Client Satisfaction Rating',
            weightLabel: '20% Weight',
            plainLanguageExplanation: _getRatingExplanation(data),
            progressValue: data.pastRatingNormalized,
            extraContent: (data.averageRating == null)
                ? Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      'New designer on platform; standard 50% baseline applied.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: textSecondary,
                      ),
                    ),
                  )
                : null,
          ),

          const SizedBox(height: 12),

          // 5. Component 4: Availability (10% Weight)
          _buildBreakdownCard(
            context: context,
            isDark: isDark,
            cardBg: cardBg,
            cardBorder: cardBorder,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            icon: data.availabilityBonus > 0
                ? Icons.check_circle_outline
                : Icons.hourglass_empty_rounded,
            iconColor: data.availabilityBonus > 0
                ? const Color(0xFF059669)
                : const Color(0xFFDC2626),
            title: 'Capacity & Availability',
            weightLabel: '10% Weight',
            plainLanguageExplanation: data.availabilityBonus > 0
                ? 'Availability: currently accepting new projects'
                : 'Availability: At capacity',
            progressValue: data.availabilityBonus,
            extraContent: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                data.availabilityBonus > 0
                    ? 'Designer is active and under maximum concurrent project limit.'
                    : 'Designer is currently occupied with active client commitments.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: textSecondary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 6. Read-Only Notice
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1A17) : const Color(0xFFF4EDE4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF8C4A3E)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Read-Only Explanation',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This breakdown shows how the StyleSync deterministic matching algorithm evaluated compatibility between your request and the designer profile.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          height: 1.45,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingExplanation(MatchScoreBreakdownResponse data) {
    if (data.averageRating != null) {
      return 'Rating: ${data.averageRating!.toStringAsFixed(1)} / 5 from past clients';
    }
    if (data.pastRatingNormalized != 0.5) {
      final computed = (data.pastRatingNormalized * 5.0).toStringAsFixed(1);
      return 'Rating: $computed / 5 from past clients';
    }
    return 'Rating: No ratings yet';
  }

  Widget _buildBreakdownCard({
    required BuildContext context,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String weightLabel,
    required String plainLanguageExplanation,
    required double progressValue,
    Widget? extraContent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : const Color(0xFF241611).withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2E2620)
                      : const Color(0xFFF3ECE4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  weightLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            plainLanguageExplanation,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressValue.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
            ),
          ),
          if (extraContent != null) extraContent,
        ],
      ),
    );
  }
}
