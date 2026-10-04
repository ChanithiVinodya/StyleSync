import 'package:flutter/material.dart';
import '../models/designer_summary.dart';

class DesignerCard extends StatelessWidget {
  final DesignerSummary designer;
  final VoidCallback onTap;

  const DesignerCard({
    super.key,
    required this.designer,
    required this.onTap,
  });

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return 'LKR ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    return 'LKR ${(amount / 1000).toStringAsFixed(0)}k';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF2C2723) : const Color(0xFFE7E1D7),
        ),
      ),
      color: isDark ? const Color(0xFF1C1917) : const Color(0xFFFAF8F5),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Header with Rating and Capacity Badges
            Stack(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  color: isDark ? const Color(0xFF2A2420) : const Color(0xFFEAE4D9),
                  child: designer.featuredImageUrl != null
                      ? Image.network(
                          designer.featuredImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderImage(isDark),
                        )
                      : _buildPlaceholderImage(isDark),
                ),
                // Dark gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ),
                // Rating Badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          designer.averageRating != null
                              ? designer.averageRating!.toStringAsFixed(2)
                              : 'New',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Capacity Badge (Sourced directly from backend DTO)
                Positioned(
                  top: 10,
                  right: 10,
                  child: _buildCapacityBadge(),
                ),
                // Portfolio Project Count
                Positioned(
                  bottom: 8,
                  left: 10,
                  child: Row(
                    children: [
                      const Icon(Icons.photo_library_outlined,
                          color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${designer.publishedPortfolioCount} projects',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Card Body Information
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    designer.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    designer.bio,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? const Color(0xFFA8A29E) : const Color(0xFF57534E),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Style Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: designer.styleTags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF28221D)
                              : const Color(0xFFF0ECE1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF38312B)
                                : const Color(0xFFE7E1D7),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFFD6D3D1)
                                : const Color(0xFF44403C),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // Pricing Details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BUDGET RANGE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: isDark
                                  ? const Color(0xFFA8A29E)
                                  : const Color(0xFF78716C),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatCurrency(designer.priceRangeMin)} – ${_formatCurrency(designer.priceRangeMax)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'RATE / SQ.FT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: isDark
                                  ? const Color(0xFFA8A29E)
                                  : const Color(0xFF78716C),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'LKR ${designer.ratePerSqFt.toInt()}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFE8A849)
                                  : const Color(0xFF925C18),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacityBadge() {
    if (designer.isAtCapacity) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF78350F).withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withOpacity(0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 12),
            SizedBox(width: 4),
            Text(
              'At Capacity',
              style: TextStyle(
                color: Colors.amberAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (designer.isAvailable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF064E3B).withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 12),
            SizedBox(width: 4),
            Text(
              'Accepting Projects',
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Unavailable',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
  }

  Widget _buildPlaceholderImage(bool isDark) {
    return Center(
      child: Icon(
        Icons.apartment_rounded,
        size: 48,
        color: isDark ? const Color(0xFF57534E) : const Color(0xFFA8A29E),
      ),
    );
  }
}
