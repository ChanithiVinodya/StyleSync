import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../providers/project_execution_providers.dart';
import '../models/project_execution_models.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  final String projectId;
  const TaskListScreen({super.key, required this.projectId});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  Future<void> _showTaskDialog({Task? task}) async {
    final service = ref.read(projectExecutionServiceProvider);
    List<Milestone> milestones = [];
    try {
      milestones = await service.getMilestones(widget.projectId);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load milestones: $e')));
      return;
    }

    if (milestones.isEmpty && task == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please create a milestone first.')));
      return;
    }

    String selectedMilestoneId = task?.milestoneId ?? milestones.first.milestoneId;

    final nameController = TextEditingController(text: task?.name ?? '');
    final descriptionController = TextEditingController(text: task?.description ?? '');
    String status = task?.status.name ?? 'NotStarted';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime startDate = task != null ? DateTime(task.startDate.year, task.startDate.month, task.startDate.day) : today;
    DateTime dueDate = task != null ? DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day) : today.add(const Duration(days: 7));

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(task == null ? 'New Task' : 'Edit Task'),
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
                    if (task == null) ...[
                      DropdownButtonFormField<String>(
                        value: selectedMilestoneId,
                        items: milestones.map((m) {
                          return DropdownMenuItem(value: m.milestoneId, child: Text(m.name));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedMilestoneId = val);
                        },
                        decoration: const InputDecoration(labelText: 'Milestone'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate,
                                firstDate: task == null ? today : (startDate.isBefore(today) ? startDate : today),
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
                  'milestoneId': selectedMilestoneId,
                  'name': nameController.text,
                  'description': descriptionController.text,
                  'status': status,
                  'startDate': startDate.toUtc().toIso8601String(),
                  'dueDate': dueDate.toUtc().toIso8601String(),
                };
                try {
                  if (task == null) {
                    await service.createTask(data);
                  } else {
                    await service.updateTask(task.taskId, data);
                  }
                  if (mounted) Navigator.pop(context);
                  ref.invalidate(projectTasksProvider(null));
                } catch (e) {
                  if (mounted) {
                    String msg = e.toString();
                    if (e is DioException && e.response?.data != null) {
                      msg = e.response?.data['message'] ?? e.response?.data.toString() ?? msg;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $msg')));
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

  Future<void> _deleteTask(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final service = ref.read(projectExecutionServiceProvider);
        await service.deleteTask(task.taskId);
        ref.invalidate(projectTasksProvider(null));
      } catch (e) {
        if (mounted) {
          String msg = e.toString();
          if (e is DioException && e.response?.data != null) {
            msg = e.response?.data['message'] ?? e.response?.data.toString() ?? msg;
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $msg')));
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(projectTasksProvider(null));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textEspresso = const Color(0xFF231713);
    final terracotta = const Color(0xFF8C4A3E);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF18110E) : const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: Text('Tasks', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
      ),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return _buildEmptyState(isDark, textEspresso);
          }
          return RefreshIndicator(
            color: terracotta,
            onRefresh: () async {
              ref.invalidate(projectTasksProvider(null));
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: tasks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _buildTaskCard(task, isDark, textEspresso, terracotta);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(),
        backgroundColor: terracotta,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTaskCard(Task task, bool isDark, Color textEspresso, Color terracotta) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF221915) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: task.cascadedDelay > 0 
            ? Colors.redAccent.withValues(alpha: 0.5) 
            : (isDark ? const Color(0xFF382C27) : const Color(0xFFEDE3D8))
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task.name,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFFAF5F0) : textEspresso,
                  ),
                ),
              ),
              _buildStatusBadge(task.status, terracotta),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () => _showTaskDialog(task: task),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () => _deleteTask(task),
              ),
            ],
          ),
          if (task.cascadedDelay > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.redAccent),
                const SizedBox(width: 4),
                Text(
                  'Delayed by ${task.cascadedDelay} days',
                  style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ],
            )
          ],
          const SizedBox(height: 8),
          Text(
            task.description,
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
                  'Start: ${task.startDate.toLocal().toString().split(' ')[0]}',
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
                  'Due: ${task.dueDate.toLocal().toString().split(' ')[0]}',
                  style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF78716C) : const Color(0xFF78716C)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TaskStatus status, Color terracotta) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case TaskStatus.Completed:
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        label = 'Completed';
        break;
      case TaskStatus.InProgress:
        bgColor = terracotta.withValues(alpha: 0.1);
        textColor = terracotta;
        label = 'In Progress';
        break;
      case TaskStatus.Delayed:
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color textEspresso) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt_outlined, size: 64, color: isDark ? const Color(0xFF382C27) : const Color(0xFFEDE3D8)),
          const SizedBox(height: 16),
          Text(
            'No tasks available.',
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
