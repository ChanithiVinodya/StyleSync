import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/project_execution_providers.dart';
import '../models/project_execution_models.dart';

class MaterialListScreen extends ConsumerStatefulWidget {
  final String projectId;
  const MaterialListScreen({super.key, required this.projectId});

  @override
  ConsumerState<MaterialListScreen> createState() => _MaterialListScreenState();
}

class _MaterialListScreenState extends ConsumerState<MaterialListScreen> {
  Future<void> _showMaterialDialog({MaterialItem? material}) async {
    await showDialog(
      context: context,
      builder: (context) {
        return _MaterialDialogBody(
          projectId: widget.projectId,
          material: material,
        );
      },
    );
  }

  Future<void> _deleteMaterial(MaterialItem material) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: const Text('Are you sure you want to delete this material?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final service = ref.read(projectExecutionServiceProvider);
        await service.deleteMaterial(material.materialId);
        ref.invalidate(projectMaterialsProvider(widget.projectId));
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(projectMaterialsProvider(widget.projectId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textEspresso = const Color(0xFF231713);
    final terracotta = const Color(0xFF8C4A3E);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF18110E) : const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: Text('Materials', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
      ),
      body: materialsAsync.when(
        data: (materials) {
          if (materials.isEmpty) {
            return _buildEmptyState(isDark, textEspresso);
          }
          return RefreshIndicator(
            color: terracotta,
            onRefresh: () async {
              ref.invalidate(projectMaterialsProvider(widget.projectId));
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: materials.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final material = materials[index];
                return _buildMaterialCard(material, isDark, textEspresso, terracotta);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMaterialDialog(),
        backgroundColor: terracotta,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMaterialCard(MaterialItem material, bool isDark, Color textEspresso, Color terracotta) {
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
                  material.name,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFFAF5F0) : textEspresso,
                  ),
                ),
              ),
              Checkbox(
                value: material.status == MaterialStatus.Delivered,
                activeColor: terracotta,
                onChanged: (bool? checked) async {
                  if (checked != null) {
                    final newStatus = checked ? 'Delivered' : 'Ordered';
                    try {
                      final service = ref.read(projectExecutionServiceProvider);
                      await service.updateMaterialStatus(material.materialId, newStatus);
                      ref.invalidate(projectMaterialsProvider(widget.projectId));
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  }
                },
              ),
              _buildStatusBadge(material.status, terracotta),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () => _showMaterialDialog(material: material),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () => _deleteMaterial(material),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${material.quantity} ${material.unit}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFB5A49B) : const Color(0xFF6E5D53),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(MaterialStatus status, Color terracotta) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case MaterialStatus.Delivered:
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        label = 'Delivered';
        break;
      case MaterialStatus.Ordered:
        bgColor = terracotta.withValues(alpha: 0.1);
        textColor = terracotta;
        label = 'Ordered';
        break;
      default:
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        label = 'Required';
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
          Icon(Icons.inventory_2_outlined, size: 64, color: isDark ? const Color(0xFF382C27) : const Color(0xFFEDE3D8)),
          const SizedBox(height: 16),
          Text(
            'No materials added.',
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

class _MaterialDialogBody extends ConsumerStatefulWidget {
  final String projectId;
  final MaterialItem? material;

  const _MaterialDialogBody({required this.projectId, this.material});

  @override
  ConsumerState<_MaterialDialogBody> createState() => _MaterialDialogBodyState();
}

class _MaterialDialogBodyState extends ConsumerState<_MaterialDialogBody> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController quantityController;
  late TextEditingController unitController;
  late String status;
  String? selectedMilestoneId;
  String? selectedTaskId;
  DateTime? requiredDate;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.material?.name ?? '');
    descriptionController = TextEditingController(text: widget.material?.description ?? '');
    quantityController = TextEditingController(text: widget.material?.quantity.toString() ?? '0');
    unitController = TextEditingController(text: widget.material?.unit ?? 'pcs');
    status = widget.material?.status.name ?? 'Required';
    selectedMilestoneId = widget.material?.milestoneId;
    selectedTaskId = widget.material?.taskId;
    requiredDate = widget.material?.requiredDate;
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    quantityController.dispose();
    unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final milestonesAsync = ref.watch(projectMilestonesProvider(widget.projectId));
    final tasksAsync = ref.watch(projectTasksProvider(selectedMilestoneId));

    return AlertDialog(
      title: Text(widget.material == null ? 'New Material' : 'Edit Material'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            milestonesAsync.when(
              data: (milestones) => DropdownButtonFormField<String>(
                value: selectedMilestoneId,
                items: milestones.map((m) => DropdownMenuItem(value: m.milestoneId, child: Text(m.name))).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedMilestoneId = val;
                    selectedTaskId = null; // Reset task when milestone changes
                  });
                },
                decoration: const InputDecoration(labelText: 'Milestone'),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('Error: $err'),
            ),
            if (selectedMilestoneId != null)
              tasksAsync.when(
                data: (tasks) {
                  final milestoneTasks = tasks.where((t) => t.milestoneId == selectedMilestoneId).toList();
                  return DropdownButtonFormField<String>(
                    value: selectedTaskId,
                    items: milestoneTasks.map((t) => DropdownMenuItem(value: t.taskId, child: Text(t.name))).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedTaskId = val;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Task'),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (err, stack) => Text('Error: $err'),
              ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: unitController,
                    decoration: const InputDecoration(labelText: 'Unit'),
                  ),
                ),
              ],
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Required By (Date)'),
              subtitle: Text(requiredDate != null ? "${requiredDate!.toLocal()}".split(' ')[0] : 'Select a date'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                if (selectedMilestoneId == null || selectedTaskId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a milestone and a task first.')));
                  return;
                }
                final tasks = ref.read(projectTasksProvider(selectedMilestoneId!)).value;
                if (tasks == null) return;
                
                final task = tasks.where((t) => t.taskId == selectedTaskId).firstOrNull;
                if (task == null) return;

                final minDate = DateTime(task.startDate.year, task.startDate.month, task.startDate.day);
                final maxDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
                
                var initDate = requiredDate ?? minDate;
                if (initDate.isBefore(minDate)) initDate = minDate;
                if (initDate.isAfter(maxDate)) initDate = maxDate;

                final date = await showDatePicker(
                  context: context,
                  initialDate: initDate,
                  firstDate: minDate,
                  lastDate: maxDate,
                );
                if (date != null) {
                  setState(() {
                    requiredDate = date;
                  });
                }
              },
            ),
            DropdownButtonFormField<String>(
              value: status,
              items: const [
                DropdownMenuItem(value: 'Required', child: Text('Required')),
                DropdownMenuItem(value: 'Ordered', child: Text('Ordered')),
                DropdownMenuItem(value: 'Delivered', child: Text('Delivered')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => status = val);
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
            if (selectedMilestoneId == null || selectedTaskId == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a milestone and a task.')));
              return;
            }

            if (requiredDate != null) {
              final tasks = ref.read(projectTasksProvider(selectedMilestoneId!)).value;
              final task = tasks?.firstWhere((t) => t.taskId == selectedTaskId, orElse: () => throw Exception('Task not found'));
              if (task != null) {
                final rDate = DateTime(requiredDate!.year, requiredDate!.month, requiredDate!.day);
                final sDate = DateTime(task.startDate.year, task.startDate.month, task.startDate.day);
                final dDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
                
                if (rDate.isBefore(sDate) || rDate.isAfter(dDate)) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Required date must be between ${sDate.toLocal().toString().split(' ')[0]} and ${dDate.toLocal().toString().split(' ')[0]}')));
                  return;
                }
              }
            }

            final service = ref.read(projectExecutionServiceProvider);
            final data = {
              'projectId': widget.projectId,
              'milestoneId': selectedMilestoneId,
              'taskId': selectedTaskId,
              'name': nameController.text,
              'description': descriptionController.text,
              'quantity': int.tryParse(quantityController.text) ?? 0,
              'unit': unitController.text,
              'status': status,
              if (requiredDate != null) 'requiredDate': requiredDate!.toUtc().toIso8601String(),
            };

            try {
              if (widget.material == null) {
                await service.createMaterial(data);
              } else {
                await service.updateMaterial(widget.material!.materialId, data);
              }
              if (context.mounted) Navigator.pop(context);
              ref.invalidate(projectMaterialsProvider(widget.projectId));
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
