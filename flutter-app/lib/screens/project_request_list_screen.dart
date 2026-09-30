import 'package:flutter/material.dart';
import '../services/project_request_api.dart';
import '../services/auth_api.dart';
import '../models/project_request.dart';
import 'create_project_request_screen.dart';
import 'request_detail_screen.dart';
import 'login_screen.dart';

class ProjectRequestListScreen extends StatefulWidget {
  const ProjectRequestListScreen({Key? key}) : super(key: key);

  @override
  State<ProjectRequestListScreen> createState() =>
      _ProjectRequestListScreenState();
}

class _ProjectRequestListScreenState extends State<ProjectRequestListScreen> {
  final _apiService = ProjectRequestApiService();
  final TextEditingController _searchController = TextEditingController();

  List<ProjectRequestModel> _requests = [];
  bool _isLoading = true;

  String _selectedStatus = 'All';
  String _selectedSort = 'date_desc';
  int _currentPage = 1;

  final List<String> _statuses = [
    'All',
    'Draft',
    'Submitted',
    'AIAnalysis',
    'ProposalReady',
    'Accepted',
    'Rejected',
    'Cancelled',
    'Flagged'
  ];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.fetchAllRequests(
        search: _searchController.text,
        status: _selectedStatus,
        sortBy: _selectedSort,
        page: _currentPage,
      );
      setState(() {
        _requests = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDraft(ProjectRequestModel req) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Draft?'),
        content: Text('Are you sure you want to delete draft "${req.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _apiService.deleteProjectRequest(req.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft deleted.')),
        );
        _fetchRequests();
      }
    }
  }

  Future<void> _submitDraft(ProjectRequestModel req) async {
    try {
      await _apiService.submitRequestForAIAnalysis(req.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('🚀 Request submitted! AI Workflow started.')),
      );
      _fetchRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Submission error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ProposalReady':
      case 'Accepted':
        return Colors.green.shade700;
      case 'Submitted':
      case 'AIAnalysis':
        return Colors.orange.shade800;
      case 'Draft':
        return Colors.blue.shade700;
      case 'Rejected':
      case 'Cancelled':
      case 'Flagged':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Room Makeover Requests'),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRequests,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              AuthApiService.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const ClientLoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.indigo.shade50,
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by room type, title, description...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _fetchRequests();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _fetchRequests(),
                ),
                const SizedBox(height: 8),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statuses.map((status) {
                      final isSelected = _selectedStatus == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(status == 'AIAnalysis'
                              ? 'AI Analysis'
                              : (status == 'ProposalReady'
                                  ? 'Proposal Ready'
                                  : status)),
                          selected: isSelected,
                          selectedColor: Colors.indigo.shade900,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              _selectedStatus = status;
                            });
                            _fetchRequests();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 6),

                // Sort Dropdown & Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Found ${_requests.length} requests',
                        style: TextStyle(
                            color: Colors.indigo.shade900,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: _selectedSort,
                      underline: const SizedBox(),
                      style: TextStyle(
                          color: Colors.indigo.shade900,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                      items: const [
                        DropdownMenuItem(
                            value: 'date_desc', child: Text('Newest First')),
                        DropdownMenuItem(
                            value: 'date_asc', child: Text('Oldest First')),
                        DropdownMenuItem(
                            value: 'budget_desc',
                            child: Text('Budget: High to Low')),
                        DropdownMenuItem(
                            value: 'budget_asc',
                            child: Text('Budget: Low to High')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedSort = val);
                          _fetchRequests();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Request Cards List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchRequests,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _requests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_open,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text('No room makeover requests found.',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey)),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const CreateProjectRequestScreen()),
                                  ).then((_) => _fetchRequests());
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Create New Request'),
                              )
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _requests.length,
                          itemBuilder: (context, index) {
                            final req = _requests[index];
                            final mainPhoto = req.photos.isNotEmpty
                                ? req.photos.first.photoUrl
                                : 'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?q=80&w=800&auto=format&fit=crop';
                            final isDraft = req.status == 'Draft';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 14),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RequestDetailScreen(
                                          requestId: req.id),
                                    ),
                                  ).then((_) => _fetchRequests());
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          // Thumbnail
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(
                                              mainPhoto,
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                width: 70,
                                                height: 70,
                                                color: Colors.indigo.shade100,
                                                child: const Icon(
                                                    Icons.meeting_room,
                                                    color: Colors.indigo),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Content Details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        req.title,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: _getStatusColor(
                                                                req.status)
                                                            .withOpacity(0.12),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        border: Border.all(
                                                            color:
                                                                _getStatusColor(
                                                                    req.status)),
                                                      ),
                                                      child: Text(
                                                        req.status ==
                                                                'AIAnalysis'
                                                            ? 'AI Analysis'
                                                            : (req.status ==
                                                                    'ProposalReady'
                                                                ? 'Proposal Ready'
                                                                : req.status),
                                                        style: TextStyle(
                                                          color:
                                                              _getStatusColor(
                                                                  req.status),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                    '🏠 ${req.roomType} • ${req.roomSize.toStringAsFixed(0)} sq ft',
                                                    style: TextStyle(
                                                        color: Colors
                                                            .grey.shade700,
                                                        fontSize: 13)),
                                                Text(
                                                    '💰 Budget: LKR ${req.budgetLkr.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                        color: Colors
                                                            .indigo.shade900,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13)),
                                                Text(
                                                    '🖼️ ${req.photos.length} Photos & Moodboards',
                                                    style: TextStyle(
                                                        color: Colors
                                                            .grey.shade600,
                                                        fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Actions bar for Drafts (Edit / Delete / Submit)
                                      if (isDraft) ...[
                                        const Divider(height: 16),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              onPressed: () =>
                                                  _deleteDraft(req),
                                              icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 18,
                                                  color: Colors.red),
                                              label: const Text('Delete Draft',
                                                  style: TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 12)),
                                            ),
                                            TextButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          CreateProjectRequestScreen(
                                                              existingDraft:
                                                                  req)),
                                                ).then((_) => _fetchRequests());
                                              },
                                              icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 18,
                                                  color: Colors.indigo),
                                              label: const Text('Edit Draft',
                                                  style: TextStyle(
                                                      color: Colors.indigo,
                                                      fontSize: 12)),
                                            ),
                                            ElevatedButton.icon(
                                              onPressed: () =>
                                                  _submitDraft(req),
                                              icon: const Icon(Icons.send,
                                                  size: 16),
                                              label: const Text('Submit Now',
                                                  style:
                                                      TextStyle(fontSize: 12)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.indigo.shade900,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CreateProjectRequestScreen()),
          ).then((_) => _fetchRequests());
        },
        backgroundColor: Colors.indigo.shade900,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Request',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
