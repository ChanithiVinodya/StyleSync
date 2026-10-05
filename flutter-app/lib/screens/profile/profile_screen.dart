import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import '../../main.dart';
import '../../providers/auth/auth_provider.dart';
import '../../routes.dart';

/// Modern Profile & Settings Screen for StyleSync
/// Implements user profile presentation, activity counters, modern aesthetics,
/// and comprehensive Light/Dark/System theme preferences.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(currentUserProvider);
    final appState = legacy_provider.Provider.of<AppStateProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF1A1715) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2824) : const Color(0xFFEFE7DE);
    final subtitleColor = isDark ? const Color(0xFFB5A49B) : const Color(0xFF7A6B65);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            tooltip: 'Share Profile Card',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Client portfolio link copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // 1. Client Identity & Tier Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.5),
                              width: 2.5,
                            ),
                            image: const DecorationImage(
                              image: NetworkImage(
                                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: cardBg, width: 2),
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                authUser?.name.isNotEmpty == true ? authUser!.name : appState.clientName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.verified,
                                size: 16,
                                color: primaryColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            authUser?.email.isNotEmpty == true ? authUser!.email : appState.clientEmail,
                            style: TextStyle(
                              fontSize: 12,
                              color: subtitleColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${authUser?.role.displayName.toUpperCase() ?? 'CLIENT'} TIER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 14),
                // Activity Summary Metric Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn('1', 'In Progress', () {
                      Navigator.pushNamed(context, AppRoutes.progressPath('proj-101'));
                    }, primaryColor, subtitleColor),
                    _buildStatDivider(borderColor),
                    _buildStatColumn('1', 'Pending Quote', () {
                      Navigator.pushNamed(context, AppRoutes.quoteDetailPath('q-804'));
                    }, primaryColor, subtitleColor),
                    _buildStatDivider(borderColor),
                    _buildStatColumn('3', 'Saved Designers', () {
                      Navigator.pushNamed(context, AppRoutes.designers);
                    }, primaryColor, subtitleColor),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. THEME & APPEARANCE PREFERENCES (CORE FEATURE)
          _buildSectionHeader('APPEARANCE & THEME', subtitleColor),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                          size: 20,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Interface Theme',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ],
                    ),
                    Text(
                      appState.themeMode == ThemeMode.system
                          ? 'System (${isDark ? 'Dark' : 'Light'})'
                          : appState.themeMode == ThemeMode.dark
                              ? 'Dark'
                              : 'Light',
                      style: TextStyle(fontSize: 12, color: subtitleColor),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Modern Segmented Mode Selector
                Row(
                  children: [
                    Expanded(
                      child: _buildThemeOptionCard(
                        context: context,
                        title: 'Light',
                        icon: Icons.wb_sunny_rounded,
                        isSelected: appState.themeMode == ThemeMode.light,
                        onTap: () => appState.setThemeMode(ThemeMode.light),
                        primaryColor: primaryColor,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildThemeOptionCard(
                        context: context,
                        title: 'Dark',
                        icon: Icons.nightlight_round,
                        isSelected: appState.themeMode == ThemeMode.dark,
                        onTap: () => appState.setThemeMode(ThemeMode.dark),
                        primaryColor: primaryColor,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildThemeOptionCard(
                        context: context,
                        title: 'System',
                        icon: Icons.brightness_auto,
                        isSelected: appState.themeMode == ThemeMode.system,
                        onTap: () => appState.setThemeMode(ThemeMode.system),
                        primaryColor: primaryColor,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. STYLE PROFILE & CURATION
          _buildSectionHeader('STYLE SYNC PROFILE', subtitleColor),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Primary Aesthetic',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text(
                      'Match Score: 98%',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStyleTag('Warm Minimalism', primaryColor, true),
                    _buildStyleTag('Organic Modern', primaryColor, true),
                    _buildStyleTag('Japandi Woodwork', primaryColor, true),
                    _buildStyleTag('Mediterranean Earth', primaryColor, false),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 10),
                _buildInfoRow('Project Scope', 'Full Residential Penthouse', isDark, subtitleColor),
                const SizedBox(height: 6),
                _buildInfoRow('Target Completion', 'Q4 2026', isDark, subtitleColor),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 4. NOTIFICATIONS & ALERTS
          _buildSectionHeader('COMMUNICATION PREFERENCES', subtitleColor),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: appState.quoteAlertsEnabled,
                  onChanged: (val) => appState.toggleQuoteAlerts(val),
                  title: const Text('Designer Quote Alerts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text('Immediate push notification when quotes arrive', style: TextStyle(fontSize: 11, color: subtitleColor)),
                  activeTrackColor: primaryColor.withValues(alpha: 0.5),
                  activeThumbColor: primaryColor,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile.adaptive(
                  value: appState.milestoneAlertsEnabled,
                  onChanged: (val) => appState.toggleMilestoneAlerts(val),
                  title: const Text('Milestone Progress Photos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text('On-site updates from contractor & designer', style: TextStyle(fontSize: 11, color: subtitleColor)),
                  activeTrackColor: primaryColor.withValues(alpha: 0.5),
                  activeThumbColor: primaryColor,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile.adaptive(
                  value: appState.curatedInspoEnabled,
                  onChanged: (val) => appState.toggleCuratedInspo(val),
                  title: const Text('Weekly Curation Digest', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text('Trending furniture and bespoke styling inspo', style: TextStyle(fontSize: 11, color: subtitleColor)),
                  activeTrackColor: primaryColor.withValues(alpha: 0.5),
                  activeThumbColor: primaryColor,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 5. SECURITY & BIOMETRICS
          _buildSectionHeader('SECURITY & APP ACCESS', subtitleColor),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: appState.biometricsEnabled,
                  onChanged: (val) => appState.toggleBiometrics(val),
                  title: const Text('Biometric Quick Unlock', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text('Use Face ID / Touch ID to sign contracts and approve quotes', style: TextStyle(fontSize: 11, color: subtitleColor)),
                  activeTrackColor: primaryColor.withValues(alpha: 0.5),
                  activeThumbColor: primaryColor,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.payment_outlined, size: 20, color: primaryColor),
                  title: const Text('Payment Methods', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text('Mastercard ending in 8824', style: TextStyle(fontSize: 11, color: subtitleColor)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment preferences will be managed via Client Billing API')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // 6. LOGOUT & CACHE ACTIONS
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Offline style cache cleared successfully (34.2 MB)')),
              );
            },
            icon: const Icon(Icons.cleaning_services_outlined, size: 16),
            label: const Text('Clear Image Cache'),
            style: OutlinedButton.styleFrom(
              foregroundColor: subtitleColor,
              side: BorderSide(color: borderColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),

          const SizedBox(height: 10),

          FilledButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: cardBg,
                  title: const Text('Sign Out of StyleSync?'),
                  content: const Text(
                    'You will need to sign in again to review active designer proposals and progress logs.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB3261E),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.login,
                            (route) => false,
                          );
                        }
                      },
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('Log Out'),
            style: FilledButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF2E1B18) : const Color(0xFFFBEBE8),
              foregroundColor: const Color(0xFFC84534),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),

          const SizedBox(height: 20),
          Center(
            child: Text(
              'StyleSync Mobile Client v1.0.4 · Build 2026.09\nEngineered with Flutter + Provider',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: subtitleColor.withValues(alpha: 0.7), height: 1.5),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  static Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: color,
        ),
      ),
    );
  }

  static Widget _buildStatColumn(
    String count,
    String label,
    VoidCallback onTap,
    Color primaryColor,
    Color subtitleColor,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: subtitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildStatDivider(Color borderColor) {
    return Container(
      width: 1,
      height: 24,
      color: borderColor,
    );
  }

  static Widget _buildThemeOptionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryColor,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: isDark ? 0.25 : 0.12)
              : (isDark ? const Color(0xFF161311) : const Color(0xFFF9F5F0)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primaryColor : (isDark ? const Color(0xFF2E2824) : const Color(0xFFE8DFD5)),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? primaryColor : (isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? primaryColor : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildStyleTag(String text, Color primaryColor, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? primaryColor.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? primaryColor : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          color: active ? primaryColor : Colors.grey,
        ),
      ),
    );
  }

  static Widget _buildInfoRow(String label, String value, bool isDark, Color subtitleColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: subtitleColor)),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
