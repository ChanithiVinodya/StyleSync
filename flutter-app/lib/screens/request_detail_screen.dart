import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/project_request.dart';
import '../services/project_request_api.dart';
import 'create_project_request_screen.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;

  const RequestDetailScreen({Key? key, required this.requestId}) : super(key: key);

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  final _apiService = ProjectRequestApiService();
  ProjectRequestModel? _request;
  bool _isLoading = true;

  final List<Map<String, String>> _workflowStages = [
    {'key': 'Draft', 'label': 'Draft Created', 'icon': '📝'},
    {'key': 'Submitted', 'label': 'Submitted', 'icon': '📥'},
    {'key': 'AIAnalysis', 'label': 'AI Analysis', 'icon': '🤖'},
    {'key': 'ProposalReady', 'label': 'Proposal Ready', 'icon': '✨'},
    {'key': 'Accepted', 'label': 'Accepted', 'icon': '🎉'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      final req = await _apiService.fetchRequestById(widget.requestId);
      setState(() {
        _request = req;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _copyHex(String hex) {
    Clipboard.setData(ClipboardData(text: hex));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $hex copied!'),
        backgroundColor: Colors.indigo.shade800,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  int _getStageIndex(String currentStatus) {
    switch (currentStatus) {
      case 'Draft':
        return 0;
      case 'Submitted':
        return 1;
      case 'AIAnalysis':
      case 'UnderReview':
        return 2;
      case 'ProposalReady':
      case 'QuoteProvided':
        return 3;
      case 'Accepted':
        return 4;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('MMM dd, yyyy • hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(_request != null ? _request!.title : 'Request Details'),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _request == null
              ? const Center(child: Text('Failed to load request details.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _request!.status == 'Flagged' || _request!.status == 'Rejected'
                              ? Colors.red.shade50
                              : Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _request!.status == 'Flagged' || _request!.status == 'Rejected'
                                ? Colors.red.shade300
                                : Colors.indigo.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _request!.status == 'Flagged' ? Icons.flag : Icons.info_outline,
                              color: _request!.status == 'Flagged' ? Colors.red : Colors.indigo,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status: ${_request!.status}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _request!.status == 'Flagged' ? Colors.red.shade900 : Colors.indigo.shade900,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (_request!.flagReason != null && _request!.flagReason!.isNotEmpty)
                                    Text('Reason: ${_request!.flagReason}', style: const TextStyle(color: Colors.red, fontSize: 13)),
                                  if (_request!.rejectionReason != null && _request!.rejectionReason!.isNotEmpty)
                                    Text('Rejection: ${_request!.rejectionReason}', style: const TextStyle(color: Colors.red, fontSize: 13)),
                                  Text('Created: ${formatter.format(_request!.createdAt)}',
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Status Timeline (Client tracking AI workflow)
                      const Text('AI Workflow Status Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: List.generate(_workflowStages.length, (idx) {
                              final stage = _workflowStages[idx];
                              final activeIndex = _getStageIndex(_request!.status);
                              final isPassed = idx <= activeIndex;
                              final isCurrent = idx == activeIndex;

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isCurrent
                                              ? Colors.orange.shade700
                                              : (isPassed ? Colors.green.shade600 : Colors.grey.shade300),
                                        ),
                                        child: Center(
                                          child: isPassed
                                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                                              : Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                        ),
                                      ),
                                      if (idx < _workflowStages.length - 1)
                                        Container(
                                          width: 2,
                                          height: 30,
                                          color: isPassed ? Colors.green.shade500 : Colors.grey.shade300,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${stage['icon']} ${stage['label']}',
                                            style: TextStyle(
                                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                              color: isCurrent ? Colors.orange.shade900 : (isPassed ? Colors.black87 : Colors.grey),
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            isCurrent
                                                ? 'In progress / active stage'
                                                : (isPassed ? 'Completed' : 'Pending stage'),
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Room Photo & Moodboard Gallery
                      Text('Room Photo & Moodboards (${_request!.photos.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      if (_request!.photos.isEmpty)
                        const Text('No photos attached.', style: TextStyle(color: Colors.grey))
                      else
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _request!.photos.length,
                            itemBuilder: (ctx, idx) {
                              final photo = _request!.photos[idx];
                              return Container(
                                margin: const EdgeInsets.only(right: 10),
                                width: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.indigo.shade200),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    photo.photoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(color: Colors.indigo.shade100, child: const Icon(Icons.image)),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Extracted Colour Palette Display
                      const Text('Extracted Colour Palette Hex Chips 🎨', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('Tappable hex chips with copy-to-clipboard', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _request!.suggestedPalette.map((chip) {
                          final int colorVal = int.parse(chip.hexCode.replaceFirst('#', 'FF'), radix: 16);
                          return ActionChip(
                            avatar: CircleAvatar(backgroundColor: Color(colorVal), radius: 8),
                            label: Text('${chip.hexCode} (${chip.colorName})', style: const TextStyle(fontWeight: FontWeight.w600)),
                            backgroundColor: Colors.indigo.shade50,
                            onPressed: () => _copyHex(chip.hexCode),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Request Specifications
                      const Text('Specifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoRow('Room Type', _request!.roomType),
                              _infoRow('Room Size', '${_request!.roomSize.toStringAsFixed(0)} sq ft'),
                              _infoRow('Budget', 'LKR ${_request!.budgetLkr.toStringAsFixed(0)}'),
                              _infoRow('Preferred Styles', _request!.preferredStyles.join(', ')),
                              _infoRow('Preferred Colours', _request!.preferredColours.join(', ')),
                              const SizedBox(height: 8),
                              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(_request!.description, style: const TextStyle(fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Draft Edit / Delete / Submit buttons
                      if (_request!.status == 'Draft')
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => CreateProjectRequestScreen(existingDraft: _request)),
                                  ).then((_) => _loadDetails());
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit Draft'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await _apiService.submitRequestForAIAnalysis(_request!.id);
                                  _loadDetails();
                                },
                                icon: const Icon(Icons.send),
                                label: const Text('Submit Now'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo.shade900,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          Text(value.isNotEmpty ? value : 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
