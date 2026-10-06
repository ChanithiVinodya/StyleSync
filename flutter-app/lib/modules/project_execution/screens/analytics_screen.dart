import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/project_execution_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  final String projectId;
  const AnalyticsScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(projectAnalyticsProvider(projectId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textEspresso = const Color(0xFF231713);
    final terracotta = const Color(0xFF8C4A3E);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF18110E) : const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: Text('Analytics', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
      ),
      body: analyticsAsync.when(
        data: (analytics) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressCard(
                  title: 'Tasks Completion',
                  total: analytics.totalTasks,
                  completed: analytics.completedTasks,
                  delayed: analytics.delayedTasks,
                  isDark: isDark,
                  terracotta: terracotta,
                  textEspresso: textEspresso,
                ),
                const SizedBox(height: 16),
                _buildProgressCard(
                  title: 'Milestones Completion',
                  total: analytics.totalMilestones,
                  completed: analytics.completedMilestones,
                  delayed: analytics.delayedMilestones,
                  isDark: isDark,
                  terracotta: terracotta,
                  textEspresso: textEspresso,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildProgressCard({
    required String title,
    required int total,
    required int completed,
    required int delayed,
    required bool isDark,
    required Color terracotta,
    required Color textEspresso,
  }) {
    final double completionPercentage = total > 0 ? (completed / total) : 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF221915) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF382C27) : const Color(0xFFEDE3D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFFAF5F0) : textEspresso,
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: completionPercentage,
            backgroundColor: isDark ? const Color(0xFF382C27) : const Color(0xFFF4ECE4),
            valueColor: AlwaysStoppedAnimation<Color>(terracotta),
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('Total', total.toString(), Colors.blueGrey),
              _buildMetric('Completed', completed.toString(), Colors.green),
              _buildMetric('Delayed', delayed.toString(), Colors.redAccent),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
