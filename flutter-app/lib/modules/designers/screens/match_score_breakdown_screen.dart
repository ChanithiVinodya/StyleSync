import 'package:flutter/material.dart';
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
    if (score >= 0.80) return const Color(0xFF2E7D32); // Deep green
    if (score >= 0.60) return const Color(0xFFD97706); // Warm Amber
    return const Color(0xFFC05621); // Terracotta
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF9F7F5),
      appBar: AppBar(
        title: Text(
          widget.designerDisplayName != null
              ? '${widget.designerDisplayName} - Match Breakdown'
              : 'Match Score Explanation',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor:
            isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAF7F2),
        elevation: 0,
        centerTitle: false,
      ),
      body: FutureBuilder<MatchScoreBreakdownResponse>(
        future: _scoreFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFC05621)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Calculating match breakdown...',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load match breakdown.',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _loadScore,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC05621),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final breakdown = snapshot.data!;
          return _buildExplanationContent(context, breakdown, isDark);
        },
      ),
    );
  }

  Widget _buildExplanationContent(
    BuildContext context,
    MatchScoreBreakdownResponse data,
    bool isDark,
  ) {
    final stylePct = (data.styleTagOverlapPct * 100).round();
    final budgetPct = (data.budgetRangeOverlapPct * 100).round();
    final totalPct = (data.matchScore * 100).round();
    final scoreColor = _getScoreColor(data.matchScore, isDark);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Overall Match Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF262626), const Color(0xFF1E1E1E)]
                    : [const Color(0xFFFFFFFF), const Color(0xFFFBF8F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
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
                          'Overall AI Match Score',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalPct% Match',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: scoreColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: scoreColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        _getMatchTier(data.matchScore),
                        style: TextStyle(
                          color: scoreColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
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
                    minHeight: 10,
                    backgroundColor: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Deterministic weighted score: 40% Style + 30% Budget + 20% Rating + 10% Availability',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Section Title
          Text(
            'Score Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Plain-language explanation of how your request parameters aligned with this designer.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Component 1: Style Match (40% Weight)
          _buildBreakdownCard(
            context: context,
            isDark: isDark,
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF805AD5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    const Color(0xFF805AD5).withOpacity(0.25)),
                          ),
                          child: Text(
                            '# $tag',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF805AD5),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : null,
          ),

          const SizedBox(height: 14),

          // 3. Component 2: Budget Fit (30% Weight)
          _buildBreakdownCard(
            context: context,
            isDark: isDark,
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
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  )
                : null,
          ),

          const SizedBox(height: 14),

          // 4. Component 3: Past Rating (20% Weight)
          _buildBreakdownCard(
            context: context,
            isDark: isDark,
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
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  )
                : null,
          ),

          const SizedBox(height: 14),

          // 5. Component 4: Availability (10% Weight)
          _buildBreakdownCard(
            context: context,
            isDark: isDark,
            icon: data.availabilityBonus > 0
                ? Icons.check_circle_outline
                : Icons.hourglass_empty_rounded,
            iconColor: data.availabilityBonus > 0
                ? const Color(0xFF38A169)
                : const Color(0xFFE53E3E),
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
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // 6. Read-Only Notice Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Read-Only Explanation',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.grey[200] : const Color(0xFF1E1E1E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This explanation view shows how the StyleSync matching algorithm scored your shortlist. Weights and scores are calculated directly from request criteria and designer profile data.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getRatingExplanation(MatchScoreBreakdownResponse data) {
    if (data.averageRating != null) {
      return 'Rating: ${data.averageRating!.toStringAsFixed(1)} / 5 from past clients';
    }
    // If averageRating was not provided in DTO but pastRatingNormalized != 0.5, compute from it
    if (data.pastRatingNormalized != 0.5) {
      final computed = (data.pastRatingNormalized * 5.0).toStringAsFixed(1);
      return 'Rating: $computed / 5 from past clients';
    }
    return 'Rating: No ratings yet';
  }

  Widget _buildBreakdownCard({
    required BuildContext context,
    required bool isDark,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  weightLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            plainLanguageExplanation,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.35,
              color: isDark ? Colors.grey[200] : const Color(0xFF2D3748),
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
