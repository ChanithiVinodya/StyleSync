import 'package:flutter/material.dart';
import '../services/project_request_api.dart';
import '../services/auth_api.dart';
import '../models/project_request.dart';
import 'create_project_request_screen.dart';
import 'request_detail_screen.dart';
import '../widgets/smooth_mouse_scroll.dart';
import 'package:google_fonts/google_fonts.dart';

class ProjectRequestListScreen extends StatefulWidget {
  const ProjectRequestListScreen({Key? key}) : super(key: key);

  @override
  State<ProjectRequestListScreen> createState() =>
      _ProjectRequestListScreenState();
}

class _ProjectRequestListScreenState extends State<ProjectRequestListScreen> {
  final _apiService = ProjectRequestApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgMain = isDark ? const Color(0xFF14110E) : const Color(0xFFFAF7F2);
    final cardBorder = isDark ? const Color(0xFF332B25) : const Color(0xFFEDE5DC);
    final cardBg = isDark ? const Color(0xFF1A1715) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFFAF8F5) : const Color(0xFF241611);
    final textSecondary = isDark ? const Color(0xFFA89F91) : const Color(0xFF706558);
    const accentTerracotta = Color(0xFF8C4A3E);

    return Scaffold(
      backgroundColor: bgMain,
      appBar: AppBar(
        backgroundColor: bgMain,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Makeover Requests',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Manage your active projects',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textPrimary),
            onPressed: _fetchRequests,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(Icons.logout, color: textPrimary),
            tooltip: 'Logout',
            onPressed: () {
              AuthApiService.logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
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
            color: bgMain,
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search by room type, title, description...',
                    hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: textSecondary, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: textSecondary, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _fetchRequests();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1F1A17) : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(color: cardBorder)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: const BorderSide(color: accentTerracotta, width: 1.5)),
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
                          selectedColor: accentTerracotta,
                          backgroundColor: isDark ? const Color(0xFF1F1A17) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? accentTerracotta : cardBorder,
                            ),
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : textPrimary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
                            color: textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    DropdownButton<String>(
                      value: _selectedSort,
                      underline: const SizedBox(),
                      dropdownColor: cardBg,
                      icon: Icon(Icons.keyboard_arrow_down, color: textSecondary, size: 18),
                      style: TextStyle(
                          color: textPrimary,
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentTerracotta,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
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
                      : SmoothMouseScroll(
                          controller: _scrollController,
                          child: ListView.builder(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            padding: const EdgeInsets.all(12),
                            itemCount: _requests.length,
                            itemBuilder: (context, index) {
                            final req = _requests[index];
                            final mainPhoto = req.photos.isNotEmpty
                                ? req.photos.first.photoUrl
                                : 'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?q=80&w=800&auto=format&fit=crop';
                            final isDraft = req.status == 'Draft';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: cardBorder, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
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
                                                color: isDark ? const Color(0xFF2C2420) : const Color(0xFFF0EAE1),
                                                child: Icon(
                                                    Icons.meeting_room,
                                                    color: textSecondary),
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
                                                        style: GoogleFonts.playfairDisplay(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: textPrimary,
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
                                                                    req.status).withOpacity(0.5)),
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
                                                const SizedBox(height: 6),
                                                Text(
                                                    '🏠 ${req.roomType} • ${req.roomSize.toStringAsFixed(0)} sq ft',
                                                    style: TextStyle(
                                                        color: textSecondary,
                                                        fontSize: 12)),
                                                const SizedBox(height: 2),
                                                Text(
                                                    '💰 Budget: LKR ${req.budgetLkr.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                        color: textPrimary,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 12)),
                                                const SizedBox(height: 4),
                                                Text(
                                                    '🖼️ ${req.photos.length} Photos & Moodboards',
                                                    style: TextStyle(
                                                        color: textSecondary,
                                                        fontSize: 11)),
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
