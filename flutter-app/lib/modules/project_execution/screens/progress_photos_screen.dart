import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/api_config.dart';
import '../providers/project_execution_providers.dart';
import '../models/project_execution_models.dart';

class ProgressPhotosScreen extends ConsumerStatefulWidget {
  final String projectId;
  const ProgressPhotosScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProgressPhotosScreen> createState() => _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends ConsumerState<ProgressPhotosScreen> {
  Future<void> _uploadPhoto() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _PhotoDialog(projectId: widget.projectId),
    );
    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _editPhoto(ProgressPhoto photo) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _PhotoDialog(
        projectId: widget.projectId,
        existingPhoto: photo,
      ),
    );
    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _deletePhoto(ProgressPhoto photo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final service = ref.read(projectExecutionServiceProvider);
        await service.deleteProgressPhoto(photo.photoId);
        setState(() {});
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    // Note: Assuming there's a projectProgressPhotosProvider in providers file. If not, this is standard implementation.
    // I will mock this watch if it's missing or add it to providers.
    // To ensure compilation, I'll watch the service directly or create a local future provider.
    final photosFuture = ref.watch(projectExecutionServiceProvider).getProgressPhotos(widget.projectId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textEspresso = const Color(0xFF231713);
    final terracotta = const Color(0xFF8C4A3E);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF18110E) : const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: Text('Progress Photos', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<List<ProgressPhoto>>(
        future: photosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final photos = snapshot.data ?? [];
          if (photos.isEmpty) {
            return _buildEmptyState(isDark, textEspresso);
          }
          return RefreshIndicator(
            color: terracotta,
            onRefresh: () async {
              // Trigger rebuild
              (context as Element).markNeedsBuild();
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(18),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                return _buildPhotoCard(photo, isDark, textEspresso);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _uploadPhoto(),
        backgroundColor: terracotta,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }

  String _resolveImageUrl(String fileUrl) {
    if (fileUrl.isEmpty) {
      return 'https://images.unsplash.com/photo-1540932239986-30128078f3c5?auto=format&fit=crop&w=300&q=80';
    }
    if (fileUrl.startsWith('http')) {
      return fileUrl;
    }
    final uri = Uri.parse(ApiConfig.baseUrl);
    final host = '${uri.scheme}://${uri.host}:${uri.port}';
    return fileUrl.startsWith('/') ? '$host$fileUrl' : '$host/$fileUrl';
  }

  Widget _buildPhotoCard(ProgressPhoto photo, bool isDark, Color textEspresso) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF221915) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF382C27) : const Color(0xFFEDE3D8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    _resolveImageUrl(photo.fileUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: isDark ? const Color(0xFF382C27) : const Color(0xFFEDE3D8),
                      child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.7)),
                        onPressed: () => _editPhoto(photo),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.7)),
                        onPressed: () => _deletePhoto(photo),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (photo.caption != null && photo.caption!.isNotEmpty) ...[
                  Text(
                    photo.caption!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFFAF5F0) : textEspresso,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  photo.uploadedAt.toLocal().toString().split(' ')[0],
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? const Color(0xFF85756E) : const Color(0xFF8A7973),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color textEspresso) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 64, color: isDark ? const Color(0xFF382C27) : const Color(0xFFEDE3D8)),
          const SizedBox(height: 16),
          Text(
            'No progress photos available.',
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

class _PhotoDialog extends ConsumerStatefulWidget {
  final String projectId;
  final ProgressPhoto? existingPhoto;

  const _PhotoDialog({required this.projectId, this.existingPhoto});

  @override
  ConsumerState<_PhotoDialog> createState() => _PhotoDialogState();
}

class _PhotoDialogState extends ConsumerState<_PhotoDialog> {
  late final TextEditingController _captionController;
  String? _selectedMilestoneId;
  String? _selectedTaskId;
  
  List<Milestone> _milestones = [];
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.existingPhoto?.caption ?? '');
    _selectedMilestoneId = widget.existingPhoto?.milestoneId;
    _selectedTaskId = widget.existingPhoto?.taskId;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final service = ref.read(projectExecutionServiceProvider);
      _milestones = await service.getMilestones(widget.projectId);
      if (_selectedMilestoneId != null) {
        _tasks = await service.getTasks(milestoneId: _selectedMilestoneId!);
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onMilestoneChanged(String? milestoneId) async {
    setState(() {
      _selectedMilestoneId = milestoneId;
      _selectedTaskId = null;
      _tasks = [];
    });
    if (milestoneId != null) {
      try {
        final service = ref.read(projectExecutionServiceProvider);
        final tasks = await service.getTasks(milestoneId: milestoneId);
        if (mounted) {
          setState(() {
            _tasks = tasks;
          });
        }
      } catch (e) {
        // ignore
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      title: Text(widget.existingPhoto == null ? 'Upload Photo' : 'Edit Photo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(labelText: 'Caption (optional)'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMilestoneId,
              decoration: const InputDecoration(labelText: 'Milestone (optional)'),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ..._milestones.map((m) => DropdownMenuItem(value: m.milestoneId, child: Text(m.name))),
              ],
              onChanged: _onMilestoneChanged,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTaskId,
              decoration: const InputDecoration(labelText: 'Task (optional)'),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ..._tasks.map((t) => DropdownMenuItem(value: t.taskId, child: Text(t.name))),
              ],
              onChanged: _selectedMilestoneId == null ? null : (val) => setState(() => _selectedTaskId = val),
            ),
            if (widget.existingPhoto != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _handleReplaceImage(context),
                icon: const Icon(Icons.photo_library),
                label: const Text('Replace Image'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => _handleSave(context),
          child: Text(widget.existingPhoto == null ? 'Upload' : 'Save Caption'),
        ),
      ],
    );
  }

  Future<void> _handleReplaceImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    
    final service = ref.read(projectExecutionServiceProvider);
    try {
      final bytes = await pickedFile.readAsBytes();
      final multipartFile = MultipartFile.fromBytes(bytes, filename: pickedFile.name);
      
      final Map<String, dynamic> formMap = {
        'projectId': widget.projectId,
        'caption': _captionController.text,
        'file': multipartFile,
      };
      if (_selectedMilestoneId != null) formMap['milestoneId'] = _selectedMilestoneId;
      if (_selectedTaskId != null) formMap['taskId'] = _selectedTaskId;
      
      final formData = FormData.fromMap(formMap);
      
      await service.createProgressPhoto(formData);
      await service.deleteProgressPhoto(widget.existingPhoto!.photoId);
      
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _handleSave(BuildContext context) async {
    final service = ref.read(projectExecutionServiceProvider);
    try {
      if (widget.existingPhoto == null) {
        // Upload
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        if (pickedFile == null) return;
        
        final bytes = await pickedFile.readAsBytes();
        final multipartFile = MultipartFile.fromBytes(bytes, filename: pickedFile.name);
        
        final Map<String, dynamic> formMap = {
          'projectId': widget.projectId,
          'caption': _captionController.text,
          'file': multipartFile,
        };
        if (_selectedMilestoneId != null) formMap['milestoneId'] = _selectedMilestoneId;
        if (_selectedTaskId != null) formMap['taskId'] = _selectedTaskId;
        
        final formData = FormData.fromMap(formMap);
        await service.createProgressPhoto(formData);
      } else {
        // Update
        final Map<String, dynamic> data = {
          'caption': _captionController.text,
        };
        if (_selectedMilestoneId != null) data['milestoneId'] = _selectedMilestoneId;
        if (_selectedTaskId != null) data['taskId'] = _selectedTaskId;
        
        await service.updateProgressPhoto(widget.existingPhoto!.photoId, data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
