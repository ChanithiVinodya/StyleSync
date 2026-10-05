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
    final nameController = TextEditingController(text: material?.name ?? '');
    final descriptionController = TextEditingController(text: material?.description ?? '');
    final quantityController = TextEditingController(text: material?.quantity.toString() ?? '0');
    final unitController = TextEditingController(text: material?.unit ?? 'pcs');
    String status = material?.status.name ?? 'Required';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(material == null ? 'New Material' : 'Edit Material'),
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
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: unitController,
                  decoration: const InputDecoration(labelText: 'Unit'),
                ),
                DropdownButtonFormField<String>(
                  value: status,
                  items: const [
                    DropdownMenuItem(value: 'Required', child: Text('Required')),
                    DropdownMenuItem(value: 'Ordered', child: Text('Ordered')),
                    DropdownMenuItem(value: 'Delivered', child: Text('Delivered')),
                  ],
                  onChanged: (val) {
                    if (val != null) status = val;
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
                  'quantity': int.tryParse(quantityController.text) ?? 0,
                  'unit': unitController.text,
                  'status': status,
                };
                try {
                  if (material == null) {
                    await service.createMaterial(data);
                  } else {
                    await service.updateMaterial(material.materialId, data);
                  }
                  if (mounted) Navigator.pop(context);
                  ref.invalidate(projectMaterialsProvider(widget.projectId));
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
        if (mounted) {
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
