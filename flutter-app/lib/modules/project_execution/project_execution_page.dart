import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/project_execution_providers.dart';
import 'screens/milestone_list_screen.dart';
import 'screens/task_list_screen.dart';
import 'screens/material_list_screen.dart';
import 'screens/analytics_screen.dart';

import 'screens/timeline_screen.dart';
import 'screens/progress_photos_screen.dart';

class ProjectExecutionPage extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectExecutionPage({super.key, required this.projectId});

  @override
  ConsumerState<ProjectExecutionPage> createState() => _ProjectExecutionPageState();
}

class _ProjectExecutionPageState extends ConsumerState<ProjectExecutionPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textEspresso = const Color(0xFF231713);
    final terracotta = const Color(0xFF8C4A3E);
    
    final analyticsAsync = ref.watch(projectAnalyticsProvider(widget.projectId));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF18110E) : const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: Text('Project Execution', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
      ),
      body: analyticsAsync.when(
        data: (analytics) {
          return RefreshIndicator(
            color: terracotta,
            onRefresh: () async {
              ref.invalidate(projectAnalyticsProvider(widget.projectId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProjectSummaryCard(context, analytics, isDark, textEspresso, terracotta),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Progress & Timeline', isDark, textEspresso),
                  const SizedBox(height: 12),
                  _buildNavigationGrid(context, isDark, terracotta),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildProjectSummaryCard(BuildContext context, dynamic analytics, bool isDark, Color textEspresso, Color terracotta) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF221915) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF382C27) : const Color(0xFFEDE3D8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFB5A49B) : const Color(0xFF6E5D53),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: terracotta.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${analytics.overallProgress}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: terracotta,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: analytics.overallProgress / 100,
            backgroundColor: isDark ? const Color(0xFF382C27) : const Color(0xFFF4ECE4),
            valueColor: AlwaysStoppedAnimation<Color>(terracotta),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatMetric('Tasks', '${analytics.completedTasks}/${analytics.totalTasks}', isDark, textEspresso),
              _buildStatMetric('Milestones', '${analytics.completedMilestones}/${analytics.totalMilestones}', isDark, textEspresso),
              _buildStatMetric('Delays', '${analytics.delayedTasks}', isDark, textEspresso, isWarning: analytics.delayedTasks > 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetric(String label, String value, bool isDark, Color textEspresso, {bool isWarning = false}) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isWarning ? Colors.redAccent : (isDark ? const Color(0xFFFAF5F0) : textEspresso),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF85756E) : const Color(0xFF8A7973),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark, Color textEspresso) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: isDark ? const Color(0xFFFAF5F0) : textEspresso,
      ),
    );
  }

  Widget _buildNavigationGrid(BuildContext context, bool isDark, Color terracotta) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildNavCard(context, 'Milestones', Icons.flag_rounded, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => MilestoneListScreen(projectId: widget.projectId)));
        }, isDark, terracotta),
        _buildNavCard(context, 'Tasks', Icons.task_alt_rounded, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => TaskListScreen(projectId: widget.projectId)));
        }, isDark, terracotta),
        _buildNavCard(context, 'Materials', Icons.inventory_2_rounded, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => MaterialListScreen(projectId: widget.projectId)));
        }, isDark, terracotta),
        _buildNavCard(context, 'Timeline', Icons.timeline_rounded, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => TimelineScreen(projectId: widget.projectId)));
        }, isDark, terracotta),
        _buildNavCard(context, 'Photos', Icons.photo_library_rounded, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProgressPhotosScreen(projectId: widget.projectId)));
        }, isDark, terracotta),
        _buildNavCard(context, 'Analytics', Icons.analytics_rounded, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AnalyticsScreen(projectId: widget.projectId)));
        }, isDark, terracotta),
      ],
    );
  }

  Widget _buildNavCard(BuildContext context, String title, IconData icon, VoidCallback onTap, bool isDark, Color terracotta) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF221915) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? const Color(0xFF382C27) : const Color(0xFFEDE3D8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF382620) : const Color(0xFFF4ECE4),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: terracotta, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFFAF5F0) : const Color(0xFF231713),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
