import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../modules/requests/providers/requests_provider.dart';

class RoomPhotoPicker extends ConsumerStatefulWidget {
  final String? initialPhotoUrl;
  final String? requestId;
  final Future<String?> Function() onCreateDraft;
  final void Function(String? newUrl)? onPhotoUpdated;

  const RoomPhotoPicker({
    super.key,
    this.initialPhotoUrl,
    this.requestId,
    required this.onCreateDraft,
    this.onPhotoUpdated,
  });

  @override
  ConsumerState<RoomPhotoPicker> createState() => _RoomPhotoPickerState();
}

class _RoomPhotoPickerState extends ConsumerState<RoomPhotoPicker> {
  String? _photoUrl;
  File? _uploadingFile;
  Uint8List? _uploadingBytes;
  String? _uploadingFileName;
  String? _uploadingPath;
  bool _isUploading = false;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    _photoUrl = widget.initialPhotoUrl;
  }

  @override
  void didUpdateWidget(RoomPhotoPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPhotoUrl != oldWidget.initialPhotoUrl && !_isUploading && _uploadingFile == null && _uploadingBytes == null) {
      _photoUrl = widget.initialPhotoUrl;
    }
  }

  Future<void> _showPermissionDialog(String type) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text('We need permission to access your $type to upload a room photo. Please enable it in app settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
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
  }

  Future<bool> _checkPermission(ImageSource source) async {
    if (kIsWeb) return true;
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        await _showPermissionDialog('camera');
        return false;
      }
    } else {
      if (Platform.isIOS) {
        final status = await Permission.photos.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          await _showPermissionDialog('photo gallery');
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // Close bottom sheet
    
    if (!await _checkPermission(source)) return;

    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );

    if (xfile == null) return; // User cancelled

    final length = await xfile.length();

    if (length > 10 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image is too large. Maximum size is 10MB.')),
      );
      return;
    }

    final ext = xfile.name.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid file type. Only JPEG, PNG, and WebP are supported.')),
      );
      return;
    }

    final bytes = await xfile.readAsBytes();
    _uploadImage(xfile.path, bytes: bytes, filename: xfile.name);
  }

  Future<void> _uploadImage(String path, {Uint8List? bytes, String? filename}) async {
    setState(() {
      _uploadingPath = path;
      _uploadingBytes = bytes;
      _uploadingFileName = filename;
      if (!kIsWeb && path.isNotEmpty) {
        try {
          _uploadingFile = File(path);
        } catch (_) {}
      }
      _isUploading = true;
      _uploadError = null;
    });

    String? id = widget.requestId;
    if (id == null) {
      try {
        id = await widget.onCreateDraft();
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isUploading = false;
          _uploadError = 'Could not create draft for upload: $e';
        });
        return;
      }
      if (!mounted) return;
      if (id == null) {
        setState(() {
          _isUploading = false;
          _uploadError = 'Could not create draft. Please try again.';
        });
        return; // Failed to create draft
      }
    }

    try {
      final repo = ref.read(requestsRepositoryProvider);
      final request = await repo.uploadRoomPhoto(id, path, bytes: bytes, filename: filename);
      if (!mounted) return;
      setState(() {
        _photoUrl = request.roomPhotoUrl;
        _uploadingFile = null;
        _uploadingBytes = null;
        _uploadingPath = null;
        _uploadingFileName = null;
      });
      widget.onPhotoUpdated?.call(_photoUrl);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadError = 'Upload failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _removeImage() async {
    if (widget.requestId == null && _photoUrl != null) {
      setState(() {
        _photoUrl = null;
        _uploadingFile = null;
        _uploadingBytes = null;
      });
      widget.onPhotoUpdated?.call(null);
      return;
    }
    if (widget.requestId == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Photo'),
        content: const Text('Are you sure you want to remove the room photo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    setState(() { _isUploading = true; _uploadError = null; });
    try {
      final repo = ref.read(requestsRepositoryProvider);
      await repo.deleteImage(widget.requestId!, 'room');
      if (!mounted) return;
      setState(() {
        _photoUrl = null;
        _uploadingFile = null;
      });
      widget.onPhotoUpdated?.call(null);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadError = 'Failed to remove photo.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery / files'),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Paste image web URL'),
              onTap: () {
                Navigator.pop(context);
                _showUrlInputDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUrlInputDialog() {
    final controller = TextEditingController(text: _photoUrl ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Room Photo URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste a public direct link to an image (e.g. from Unsplash):',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'https://images.unsplash.com/...',
                labelText: 'Image URL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'))) {
                Navigator.pop(ctx);
                setState(() {
                  _photoUrl = url;
                  _uploadingFile = null;
                  _uploadingBytes = null;
                  _uploadError = null;
                });
                widget.onPhotoUpdated?.call(url);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid HTTP or HTTPS image URL.')),
                );
              }
            },
            child: const Text('Use Photo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _photoUrl != null || _uploadingBytes != null || _uploadingFile != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Room Photo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'A photo of the current room is REQUIRED to submit. Uploading or replacing this photo will not affect your palette choices.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (!hasImage)
              InkWell(
                onTap: _isUploading ? null : _showPickerSheet,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Center(
                    child: _isUploading
                      ? const CircularProgressIndicator()
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 48, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 8),
                            const Text('Add Room Photo'),
                          ],
                        ),
                  ),
                ),
              )
            else
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black12,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _uploadingBytes != null
                        ? Image.memory(_uploadingBytes!, fit: BoxFit.cover)
                        : (_uploadingFile != null
                            ? Image.file(_uploadingFile!, fit: BoxFit.cover)
                            : Image.network(_photoUrl!, fit: BoxFit.cover)),
                  ),
                  if (_isUploading)
                    Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                    ),
                  if (_uploadError != null)
                    Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 8),
                          Text(_uploadError!, style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (_uploadingPath != null) {
                                _uploadImage(
                                  _uploadingPath!,
                                  bytes: _uploadingBytes,
                                  filename: _uploadingFileName,
                                );
                              } else if (_uploadingFile != null) {
                                _uploadImage(_uploadingFile!.path);
                              }
                            },
                            child: const Text('Retry'),
                          )
                        ],
                      ),
                    ),
                ],
              ),
            if (hasImage && _uploadError == null && !_isUploading)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: _removeImage,
                      icon: const Icon(Icons.delete),
                      label: const Text('Remove'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _showPickerSheet,
                      icon: const Icon(Icons.edit),
                      label: const Text('Replace'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
