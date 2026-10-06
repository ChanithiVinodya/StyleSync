import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../modules/requests/models/request_models.dart';
import '../../../modules/requests/providers/requests_provider.dart';

class _PendingUpload {
  final String path;
  final Uint8List? bytes;
  final String? filename;
  bool isUploading = false;
  String? error;

  _PendingUpload({
    required this.path,
    this.bytes,
    this.filename,
  });
}

class MoodboardPicker extends ConsumerStatefulWidget {
  final List<MoodboardImage>? initialImages;
  final String? requestId;
  final Future<String?> Function() onCreateDraft;
  final void Function(List<MoodboardImage> newImages)? onMoodboardUpdated;

  const MoodboardPicker({
    super.key,
    this.initialImages,
    this.requestId,
    required this.onCreateDraft,
    this.onMoodboardUpdated,
  });

  @override
  ConsumerState<MoodboardPicker> createState() => _MoodboardPickerState();
}

class _MoodboardPickerState extends ConsumerState<MoodboardPicker> {
  late List<MoodboardImage> _images;
  final List<_PendingUpload> _pendingUploads = [];
  bool _isCreatingDraft = false;

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.initialImages ?? []);
  }

  @override
  void didUpdateWidget(MoodboardPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImages != oldWidget.initialImages && widget.initialImages != null) {
      _images = List.from(widget.initialImages!);
    }
  }

  Future<bool> _checkPermission() async {
    if (kIsWeb) return true;
    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        if (!mounted) return false;
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text('We need permission to access your photo gallery. Please enable it in app settings.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _pickImages() async {
    final remainingSlots = 10 - (_images.length + _pendingUploads.length);
    if (remainingSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You have reached the maximum of 10 moodboard images.')));
      return;
    }

    if (!await _checkPermission()) return;

    final picker = ImagePicker();
    final xfiles = await picker.pickMultiImage(
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );

    if (xfiles.isEmpty) return; // User cancelled

    final filesToAdd = xfiles.take(remainingSlots).toList();
    if (xfiles.length > remainingSlots && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only the first $remainingSlots image(s) were added to stay within the limit of 10.')),
      );
    }

    for (var xfile in filesToAdd) {
      final length = await xfile.length();
      if (length > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Skipped ${xfile.name} because it exceeds 10MB.')),
          );
        }
        continue;
      }
      final ext = xfile.name.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Skipped ${xfile.name} because file type is not supported.')),
          );
        }
        continue;
      }

      final bytes = await xfile.readAsBytes();
      setState(() {
        _pendingUploads.add(_PendingUpload(
          path: xfile.path,
          bytes: bytes,
          filename: xfile.name,
        ));
      });
    }

    _processQueue();
  }

  Future<void> _processQueue() async {
    String? id = widget.requestId;
    if (id == null) {
      setState(() => _isCreatingDraft = true);
      id = await widget.onCreateDraft();
      if (!mounted) return;
      if (id == null) {
        setState(() {
          _isCreatingDraft = false;
          for (var p in _pendingUploads) {
            p.error = 'Failed to create draft.';
          }
        });
        return;
      }
      setState(() => _isCreatingDraft = false);
    }

    final repo = ref.read(requestsRepositoryProvider);

    // Sequential upload to avoid hitting concurrent limits or messing up sortOrder
    for (var p in _pendingUploads) {
      if (p.isUploading || (p.error == null && !kIsWeb && p.bytes == null && !File(p.path).existsSync())) continue;
      // Skip if already successful or uploading
      if (p.error == null && p.isUploading) continue;

      if (!mounted) return;
      setState(() {
        p.isUploading = true;
        p.error = null;
      });

      try {
        final request = await repo.uploadMoodboard(id, p.path, bytes: p.bytes, filename: p.filename);
        if (!mounted) return;
        setState(() {
          _images = List.from(request.moodboard);
          _pendingUploads.remove(p);
        });
        widget.onMoodboardUpdated?.call(_images);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          p.isUploading = false;
          p.error = 'Failed';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Moodboard upload failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _removeImage(MoodboardImage image) async {
    if (widget.requestId == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Image'),
        content: const Text('Are you sure you want to remove this image?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    try {
      final repo = ref.read(requestsRepositoryProvider);
      final req = await repo.deleteImage(widget.requestId!, image.id);
      if (!mounted) return;
      setState(() {
        _images = List.from(req.moodboard);
      });
      widget.onMoodboardUpdated?.call(_images);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to remove image.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _images.length + _pendingUploads.length;
    final canAdd = totalCount < 10;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Moodboard (Optional)', style: Theme.of(context).textTheme.titleLarge),
                Text('$totalCount / 10', style: TextStyle(color: totalCount == 10 ? Colors.red : Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Add up to 10 reference images to inspire your design. You can upload from your gallery.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            if (_isCreatingDraft)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (totalCount == 0)
              InkWell(
                onTap: _pickImages,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library, size: 48, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 8),
                        const Text('Choose from gallery'),
                      ],
                    ),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: totalCount + (canAdd ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _images.length) {
                    final img = _images[index];
                    return _buildExistingImage(img);
                  } else if (index < _images.length + _pendingUploads.length) {
                    final p = _pendingUploads[index - _images.length];
                    return _buildPendingImage(p);
                  } else {
                    return InkWell(
                      onTap: _pickImages,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).colorScheme.outline),
                        ),
                        child: const Center(child: Icon(Icons.add, size: 32)),
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingImage(MoodboardImage image) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black12,
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.network(image.url, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(image),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingImage(_PendingUpload p) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black12,
          ),
          clipBehavior: Clip.antiAlias,
          child: p.bytes != null
              ? Image.memory(p.bytes!, fit: BoxFit.cover)
              : (!kIsWeb && File(p.path).existsSync()
                  ? Image.file(File(p.path), fit: BoxFit.cover)
                  : const Center(child: Icon(Icons.image))),
        ),
        if (p.isUploading)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.black54,
            ),
            child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
          ),
        if (p.error != null)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.black87,
            ),
            child: InkWell(
              onTap: () {
                setState(() => p.error = null);
                _processQueue();
              },
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, color: Colors.white),
                  SizedBox(height: 4),
                  Text('Retry', style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
        if (p.error != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() => _pendingUploads.remove(p));
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
