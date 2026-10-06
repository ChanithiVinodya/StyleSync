import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth/auth_provider.dart';
import '../../routes.dart';
import '../../screens/home/home_screen.dart';

/// Reusable floating bottom navigation bar visible across the entire mobile application.
class MainBottomNavBar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const MainBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  void _handleNavTap(BuildContext context, int index) {
    if (onTap != null) {
      onTap!(index);
    } else {
      // If tapped on a pushed sub-screen, navigate back to HomeScreen with the requested tab
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => AuthGuard(child: HomeScreen(initialTab: index))),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const terracotta = Color(0xFF8C4A3E);
    final isDesigner = ref.watch(authProvider).isDesigner;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      height: 66,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1715).withValues(alpha: 0.95)
            : const Color(0xFFFAF7F2).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(33),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2824) : const Color(0xFFE8DFD5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, 0, Icons.home_rounded, Icons.home_outlined, 'Home', isDark, terracotta),
          _buildNavItem(context, 1, Icons.explore_rounded, Icons.explore_outlined, 'Designers', isDark, terracotta),
          _buildNavItem(context, 2, Icons.assignment_rounded, Icons.assignment_outlined, 'Requests', isDark, terracotta),
          _buildNavItem(context, 3, Icons.receipt_long_rounded, Icons.receipt_long_outlined, isDesigner ? 'Contracts' : 'Quotes', isDark, terracotta),
          _buildNavItem(context, 4, Icons.account_tree_rounded, Icons.account_tree_outlined, 'Progress', isDark, terracotta),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    bool isDark,
    Color terracotta,
  ) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => _handleNavTap(context, index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2E2824) : const Color(0xFFF3E7DC))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: isSelected
              ? Border.all(color: terracotta.withValues(alpha: 0.3), width: 1)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              size: 20,
              color: isSelected ? terracotta : const Color(0xFF8A7973),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? terracotta : const Color(0xFF8A7973),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
