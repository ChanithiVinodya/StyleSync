import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../modules/project_execution/project_execution_page.dart';
import '../../modules/requests/models/request_models.dart';
import '../../modules/requests/providers/requests_provider.dart';
import '../requests/new_request_screen.dart';
import '../requests/request_detail_screen.dart';

class ProjectTimelineScreen extends ConsumerStatefulWidget {
  final String? projectId;
  const ProjectTimelineScreen({super.key, this.projectId});

  @override
  ConsumerState<ProjectTimelineScreen> createState() => _ProjectTimelineScreenState();
}

class _ProjectTimelineScreenState extends ConsumerState<ProjectTimelineScreen> {
  String? _selectedProjectId;
  List<RequestSummary> _requests = [];
  bool _isLoadingRequests = true;
  String? _requestsError;

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.projectId;
    _loadUserRequests();
  }

  @override
  void didUpdateWidget(covariant ProjectTimelineScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.projectId != oldWidget.projectId && widget.projectId != null) {
      setState(() {
        _selectedProjectId = widget.projectId;
      });
    }
  }

  Future<void> _loadUserRequests() async {
    try {
      final repo = ref.read(requestsRepositoryProvider);
      final result = await repo.listRequests(query: {'page': 1, 'pageSize': 50});
      if (mounted) {
        setState(() {
          _requests = result.items;
          _isLoadingRequests = false;
          _requestsError = null;

          // If no specific project was chosen, select the best candidate
          if (_selectedProjectId == null && _requests.isNotEmpty) {
            final active = _requests.firstWhere(
              (r) =>
                  r.status == RequestStatus.inProgress ||
                  r.status == RequestStatus.approved ||
                  r.status == RequestStatus.designerAssigned ||
                  r.status == RequestStatus.aiAnalysis ||
                  r.status == RequestStatus.proposalReady ||
                  r.status == RequestStatus.submitted,
              orElse: () => _requests.first,
            );
            _selectedProjectId = active.id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRequests = false;
          _requestsError = e.toString();
          // Fallback to default if provided
          _selectedProjectId ??= widget.projectId;
        });
      }
    }
  }

  RequestSummary? get _currentRequest {
    if (_selectedProjectId == null) return null;
    try {
      return _requests.firstWhere((r) => r.id == _selectedProjectId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const terracotta = Color(0xFF8C4A3E);
    const textEspresso = Color(0xFF231713);
    final bgColor = isDark ? const Color(0xFF18110E) : const Color(0xFFFAF7F2);

    // If loading initial user requests and no explicit projectId was passed
    if (_isLoadingRequests && _selectedProjectId == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(
            'Project Execution',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: terracotta),
        ),
      );
    }

    // If user has no requests and no explicit projectId
    if (!_isLoadingRequests && _requests.isEmpty && widget.projectId == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(
            'Project Execution',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: _buildEmptyState(isDark, terracotta, textEspresso),
      );
    }

    final activeId = _selectedProjectId ?? widget.projectId ?? '123e4567-e89b-12d3-a456-426614174000';

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Project switcher banner if requests are loaded
          if (_requests.isNotEmpty)
            _buildProjectSelectorBar(isDark, terracotta, textEspresso),

          // Main execution page
          Expanded(
            child: ProjectExecutionPage(
              key: ValueKey(activeId),
              projectId: activeId,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectSelectorBar(bool isDark, Color terracotta, Color textEspresso) {
    final current = _currentRequest;
    final title = current != null ? '${current.roomType.label} Design' : 'Project Execution';
    final refCode = current?.referenceNumber ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF221915) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF382C27) : const Color(0xFFEDE3D8),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: terracotta.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.architecture_rounded, color: terracotta, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: GoogleFonts.playfairDisplay(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark ? const Color(0xFFFAF5F0) : textEspresso,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (current != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: terracotta.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            current.status.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: terracotta,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (refCode.isNotEmpty)
                    Text(
                      refCode,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF85756E) : const Color(0xFF8A7973),
                      ),
                    ),
                ],
              ),
            ),
            if (_requests.length > 1)
              PopupMenuButton<String>(
                icon: Icon(Icons.swap_horiz_rounded, color: terracotta),
                tooltip: 'Switch Project',
                onSelected: (newId) {
                  setState(() {
                    _selectedProjectId = newId;
                  });
                },
                itemBuilder: (context) {
                  return _requests.map((r) {
                    final isSelected = r.id == _selectedProjectId;
                    return PopupMenuItem<String>(
                      value: r.id,
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                            color: isSelected ? terracotta : Colors.grey,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${r.roomType.label} (${r.referenceNumber})',
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  r.status.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },
              ),
            if (_selectedProjectId != null)
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, size: 20),
                tooltip: 'View Request Details',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RequestDetailScreen(id: _selectedProjectId!),
                    ),
                  ).then((_) => _loadUserRequests());
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color terracotta, Color textEspresso) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: terracotta.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.assignment_outlined, color: terracotta, size: 56),
            ),
            const SizedBox(height: 24),
            Text(
              'No Projects in Progress',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFFAF5F0) : textEspresso,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Submit a design request to track your project execution, milestones, materials, and live site progress photos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFFB5A49B) : const Color(0xFF6E5D53),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewRequestScreen()),
                ).then((_) => _loadUserRequests());
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Start New Design Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: terracotta,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
