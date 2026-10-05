import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../modules/requests/models/request_models.dart';
import '../../modules/requests/providers/requests_provider.dart';
import 'new_request_screen.dart';
import 'widgets/status_timeline.dart';

class RequestDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const RequestDetailScreen({super.key, required this.id});

  @override
  ConsumerState<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends ConsumerState<RequestDetailScreen> {
  RequestDetail? _detail;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  String? get _length {
    final raw = _detail?.description ?? '';
    final match = RegExp(r'\[Dimensions: L=([^,]+), W=([^,]+), H=([^\]]+)\]').firstMatch(raw);
    if (match != null) {
      final val = match.group(1)?.trim() ?? '';
      return val.isNotEmpty ? val : null;
    }
    return null;
  }

  String? get _width {
    final raw = _detail?.description ?? '';
    final match = RegExp(r'\[Dimensions: L=([^,]+), W=([^,]+), H=([^\]]+)\]').firstMatch(raw);
    if (match != null) {
      final val = match.group(2)?.trim() ?? '';
      return val.isNotEmpty ? val : null;
    }
    return null;
  }

  String? get _height {
    final raw = _detail?.description ?? '';
    final match = RegExp(r'\[Dimensions: L=([^,]+), W=([^,]+), H=([^\]]+)\]').firstMatch(raw);
    if (match != null) {
      final val = match.group(3)?.trim() ?? '';
      return val.isNotEmpty ? val : null;
    }
    return null;
  }

  String? get _roomSizeDisplay {
    final l = double.tryParse(_length ?? '');
    final w = double.tryParse(_width ?? '');
    if (l != null && w != null && l > 0 && w > 0) {
      final area = l * w;
      final areaStr = area % 1 == 0 ? area.toInt().toString() : area.toStringAsFixed(1);
      return '$areaStr sq ft';
    }
    return null;
  }

  String get _cleanDescription {
    final raw = _detail?.description ?? '';
    final match = RegExp(r'\[Dimensions: L=([^,]+), W=([^,]+), H=([^\]]+)\]').firstMatch(raw);
    if (match != null) {
      final clean = raw.replaceAll(match.group(0)!, '').trim();
      return clean.isEmpty ? '-' : clean;
    }
    return raw.isEmpty ? '-' : raw;
  }

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(requestsRepositoryProvider);
      final res = await repo.getRequest(widget.id);
      setState(() {
        _detail = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load request details.';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDraft() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Draft'),
        content: const Text('Are you sure you want to delete this draft? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(requestsRepositoryProvider).deleteDraft(widget.id);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete draft')));
      }
    }
  }

  Future<void> _submitRequest() async {
    if (_detail == null) return;
    
    // On-device rules
    if (_detail!.roomPhotoUrl == null || _detail!.roomPhotoUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Missing required room photo to submit.')));
      return;
    }
    // Checking palette and other fields could be done here, but API will validate anyway
    
    setState(() => _isSubmitting = true);
    
    try {
      final repo = ref.read(requestsRepositoryProvider);
      await repo.submit(widget.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request submitted successfully!')));
        _fetchDetail();
      }
    } on ApiProblem catch (e) {
      if (mounted) {
        if (e.status == 409) {
          // Conflict, maybe already submitted. Refresh.
          _fetchDetail();
        } else if (e.status == 400 && e.errors.isNotEmpty) {
          // Validation errors
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Cannot Submit'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: e.errors.map((err) {
                  String message = err.message;
                  final field = err.field.toLowerCase();
                  if (field == 'roomsizesqft' || field == 'roomsizesqm' || err.code == 'ROOM_SIZE_INVALID') {
                    message = 'Length, width, and height are required: length and width must produce a room size > 0 and <= 10000 sq ft.';
                  }
                  return Text('• $message');
                }).toList(),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.title)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit request.')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied $text')));
  }
  
  Color _getLuminanceContrast(Color color) {
    return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Detail'),
        actions: [
          if (_detail?.status == RequestStatus.draft)
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => NewRequestScreen(editId: widget.id)))
                      .then((_) => _fetchDetail());
                } else if (val == 'delete') {
                  _deleteDraft();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
              ],
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _detail?.status == RequestStatus.draft
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Request'),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchDetail, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_detail == null) return const Center(child: Text('Not found'));

    final fmt = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0);

    return RefreshIndicator(
      onRefresh: _fetchDetail,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_detail!.referenceNumber, style: Theme.of(context).textTheme.headlineSmall),
              Chip(label: Text(_detail!.status.label)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Timeline
          const Text('Status Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          StatusTimeline(
            currentStatus: _detail!.status,
            history: _detail!.statusHistory,
            cancelReason: _detail!.cancelReason,
            flagReason: _detail!.flagReason,
          ),
          const SizedBox(height: 24),

          // Fields
          Card(
            clipBehavior: Clip.antiAlias,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  _buildFieldRow('Room Type', _detail!.roomType?.label ?? '-'),
                  const Divider(),
                  _buildFieldRow('Budget', _detail!.budget != null ? fmt.format(_detail!.budget) : '-'),
                  const Divider(),
                  _buildFieldRow('Length', _length != null ? '$_length ft' : '-'),
                  const Divider(),
                  _buildFieldRow('Width', _width != null ? '$_width ft' : '-'),
                  const Divider(),
                  _buildFieldRow('Height', _height != null ? '$_height ft' : '-'),
                  const Divider(),
                  if (_roomSizeDisplay != null) ...[
                    _buildFieldRow('Room Size', _roomSizeDisplay!),
                    const Divider(),
                  ],
                  _buildFieldRow('Description', _cleanDescription),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Preferred Colours
          if (_detail!.palette.isNotEmpty) ...[
            const Text('Preferred Colours', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _detail!.palette.map((c) {
                final color = Color(int.parse(c.hexValue.replaceAll('#', '0xff')));
                final tc = _getLuminanceContrast(color);
                return InkWell(
                  onTap: () => _copyToClipboard(c.hexValue),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                    child: Text(c.hexValue, style: TextStyle(color: tc, fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Room Photo
          const Text('Room Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (_detail!.roomPhotoUrl != null && _detail!.roomPhotoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _detail!.roomPhotoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (ctx, _, __) => Container(height: 200, color: Colors.grey.shade300, child: const Center(child: Icon(Icons.broken_image))),
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('No room photo provided')),
            ),
          
          const SizedBox(height: 24),

          // Moodboard
          if (_detail!.moodboard.isNotEmpty) ...[
            const Text('Moodboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _detail!.moodboard.length,
              itemBuilder: (context, index) {
                final img = _detail!.moodboard[index];
                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: EdgeInsets.zero,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            InteractiveViewer(
                              child: Image.network(img.url, fit: BoxFit.contain,
                                errorBuilder: (c, _, __) => const Icon(Icons.broken_image, color: Colors.white, size: 64),
                              ),
                            ),
                            Positioned(
                              top: 40,
                              right: 20,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      img.url,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, _, __) => Container(color: Colors.grey.shade300, child: const Icon(Icons.broken_image)),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    );
  }
}
