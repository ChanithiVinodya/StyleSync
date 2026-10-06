import 'package:flutter/material.dart';
import '../../../config/style_constants.dart';

/// Visual style picker for the New Request form (Component 2).
/// Displays a grid of style thumbnail cards that clients tap to toggle multi-selection.
class StylePicker extends StatelessWidget {
  final List<String> selectedStyles;
  final ValueChanged<List<String>> onChanged;
  final String? errorText;

  const StylePicker({
    super.key,
    required this.selectedStyles,
    required this.onChanged,
    this.errorText,
  });

  void _toggleStyle(String styleTitle) {
    final updated = List<String>.from(selectedStyles);
    if (updated.contains(styleTitle)) {
      updated.remove(styleTitle);
    } else {
      updated.add(styleTitle);
    }
    onChanged(updated);
  }

  Widget _buildCardImage(AppStyleItem item) {
    if (item.assetPath != null && item.assetPath!.isNotEmpty) {
      return Image.asset(
        item.assetPath!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildNetworkOrFallback(item.fallbackUrl),
      );
    }
    return _buildNetworkOrFallback(item.fallbackUrl);
  }

  Widget _buildNetworkOrFallback(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: const Color(0xFFF3ECE7),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8C4A3E)),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFFE8DDD6),
          child: const Center(
            child: Icon(Icons.style_outlined, color: Color(0xFF8C4A3E), size: 28),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryTerracotta = Color(0xFF8C4A3E);
    const styles = AppStyleConstants.homeStyles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preferred Design Styles',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Select one or more styles that match your vision',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFFB5A7A0) : const Color(0xFF7A6B65),
                  ),
                ),
              ],
            ),
            if (selectedStyles.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryTerracotta.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${selectedStyles.length} selected',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: primaryTerracotta,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: styles.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) {
            final item = styles[index];
            final isSelected = selectedStyles.contains(item.title);

            return Semantics(
              label: '${item.title} style card, ${isSelected ? "selected" : "not selected"}',
              selected: isSelected,
              button: true,
              child: GestureDetector(
                onTap: () => _toggleStyle(item.title),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF261F1C) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? primaryTerracotta
                          : (isDark ? Colors.white12 : Colors.black12),
                      width: isSelected ? 2.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? primaryTerracotta.withValues(alpha: 0.22)
                            : Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                        blurRadius: isSelected ? 8 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Thumbnail Image Header with Badge Overlay
                        Expanded(
                          flex: 5,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildCardImage(item),
                              // Selection state tint overlay
                              if (isSelected)
                                Container(
                                  color: primaryTerracotta.withValues(alpha: 0.15),
                                ),
                              // Checkmark badge in top right
                              Positioned(
                                top: 8,
                                right: 8,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryTerracotta
                                        : Colors.black.withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Title & One-line Description footer
                        Expanded(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? primaryTerracotta
                                        : (isDark ? const Color(0xFFFAF5F0) : const Color(0xFF231713)),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.description ?? '',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    height: 1.2,
                                    color: isDark ? const Color(0xFF9E8F88) : const Color(0xFF756761),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 2),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 14,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 5),
                Text(
                  errorText!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
