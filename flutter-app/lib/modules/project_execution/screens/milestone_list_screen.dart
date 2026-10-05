import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/project_execution_providers.dart';
import '../models/project_execution_models.dart';

class MilestoneListScreen extends ConsumerStatefulWidget {
  final String projectId;
  const MilestoneListScreen({super.key, required this.projectId});

  @override
  ConsumerState<MilestoneListScreen> createState() => _MilestoneListScreenState();
}

class _MilestoneListScreenState extends ConsumerState<MilestoneListScreen> {
  Future<void> _showMilestoneDialog({Milestone? milestone}) async {
    final nameController = TextEditingController(text: milestone?.name ?? '');
    final descriptionController = TextEditingController(text: milestone?.description ?? '');
    String status = milestone?.status.name ?? 'NotStarted';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime startDate = milestone != null ? DateTime(milestone.startDate.year, milestone.startDate.month, milestone.startDate.day) : today;
    DateTime dueDate = milestone != null ? DateTime(milestone.dueDate.year, milestone.dueDate.month, milestone.dueDate.day) : today.add(const Duration(days: 7));

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(milestone == null ? 'New Milestone' : 'Edit Milestone'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate,
                                firstDate: milestone == null ? today : (startDate.isBefore(today) ? startDate : today),
                                lastDate: dueDate,
                              );
                              if (picked != null) setDialogState(() => startDate = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Start Date'),
                              child: Text(startDate.toLocal().toString().split(' ')[0]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: dueDate,
                                firstDate: startDate,
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) setDialogState(() => dueDate = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Due Date'),
                              child: Text(dueDate.toLocal().toString().split(' ')[0]),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: status,
                      items: const [
                        DropdownMenuItem(value: 'NotStarted', child: Text('Not Started')),
                        DropdownMenuItem(value: 'InProgress', child: Text('In Progress')),
                        DropdownMenuItem(value: 'Delayed', child: Text('Delayed')),
                        DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => status = val);
                      },
                      decoration: const InputDecoration(labelText: 'Status'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
            TextButton(
              onPressed: () async {
                final service = ref.read(projectExecutionServiceProvider);
                final data = {
                  'projectId': widget.projectId,
                  'name': nameController.text,
                  'description': descriptionController.text,
                  'status': status,
                  'startDate': startDate.toUtc().toIso8601String(),
                  'dueDate': dueDate.toUtc().toIso8601String(),
                };
                try {
                  if (milestone == null) {
                    await service.createMilestone(data);
                  } else {
                    await service.updateMilestone(milestone.milestoneId, data);
                  }
                  if (mounted) Navigator.pop(context);
                  ref.invalidate(projectMilestonesProvider(widget.projectId));
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
          },
        );
      },
    );
  }

  Future<void> _deleteMilestone(Milestone milestone) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Milestone'),
        content: const Text('Are you sure you want to delete this milestone?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final service = ref.read(projectExecutionServiceProvider);
        await service.deleteMilestone(milestone.milestoneId);
        ref.invalidate(projectMilestonesProvider(widget.projectId));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final milestonesAsync = ref.watch(projectMilestonesProvider(widget.projectId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textEspresso = const Color(0xFF231713);
    final terracotta = const Color(0xFF8C4A3E);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF18110E) : const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: Text('Milestones', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
      ),
      body: milestonesAsync.when(
        data: (milestones) {
          if (milestones.isEmpty) {
            return _buildEmptyState(isDark, textEspresso);
          }
          return RefreshIndicator(
            color: terracotta,
            onRefresh: () async {
              ref.invalidate(projectMilestonesProvider(widget.projectId));
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: milestones.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final milestone = milestones[index];
                return _buildMilestoneCard(milestone, isDark, textEspresso, terracotta);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMilestoneDialog(),
        backgroundColor: terracotta,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMilestoneCard(Milestone milestone, bool isDark, Color textEspresso, Color terracotta) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF221915) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF382C27) : const Color(0xFFEDE3D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  milestone.name,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFFAF5F0) : textEspresso,
                  ),
                ),
              ),
              _buildStatusBadge(milestone.status, terracotta),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () => _showMilestoneDialog(milestone: milestone),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () => _deleteMilestone(milestone),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            milestone.description,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFFB5A49B) : const Color(0xFF6E5D53),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF12100E) : const Color(0xFFFAF8F5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isDark ? const Color(0xFF2E2824) : const Color(0xFFE7E1D7)),
                ),
                child: Text(
                  'Start: ${milestone.startDate.toLocal().toString().split(' ')[0]}',
                  style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF78716C) : const Color(0xFF78716C)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF12100E) : const Color(0xFFFAF8F5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isDark ? const Color(0xFF2E2824) : const Color(0xFFE7E1D7)),
                ),
                child: Text(
                  'Due: ${milestone.dueDate.toLocal().toString().split(' ')[0]}',
                  style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF78716C) : const Color(0xFF78716C)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(MilestoneStatus status, Color terracotta) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case MilestoneStatus.Completed:
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        label = 'Completed';
        break;
      case MilestoneStatus.InProgress:
        bgColor = terracotta.withValues(alpha: 0.1);
        textColor = terracotta;
        label = 'In Progress';
        break;
      case MilestoneStatus.Delayed:
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        label = 'Delayed';
        break;
      default:
        bgColor = const Color(0xFFF5F5F5);
        textColor = const Color(0xFF616161);
        label = 'Not Started';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color textEspresso) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined, size: 64, color: isDark ? const Color(0xFF382C27) : const Color(0xFFEDE3D8)),
          const SizedBox(height: 16),
          Text(
            'No milestones available.',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? const Color(0xFFB5A49B) : const Color(0xFF6E5D53),
            ),
          ),
        ],
      ),
    );
  }
}
