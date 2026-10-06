import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../modules/requests/models/request_models.dart';
import '../../modules/requests/providers/requests_provider.dart';
import 'new_request_screen.dart';
import 'request_detail_screen.dart';
import '../progress/project_timeline_screen.dart';

class MyRequestsScreen extends ConsumerStatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  ConsumerState<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends ConsumerState<MyRequestsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  final List<RequestSummary> _requests = [];
  bool _isLoading = false;
  bool _isError = false;
  bool _hasMore = true;
  int _page = 1;

  RequestStatus? _statusFilter;
  String _sortOption = 'newest';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _fetchRequests(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore && !_isError) {
        _fetchRequests();
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchRequests(refresh: true);
    });
  }

  Future<void> _fetchRequests({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _requests.clear();
        _hasMore = true;
        _isError = false;
      });
    }

    if (!_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(requestsRepositoryProvider);
      String? sortBy;
      String? sortDir;

      switch (_sortOption) {
        case 'newest':
          sortBy = 'createdAt';
          sortDir = 'desc';
          break;
        case 'oldest':
          sortBy = 'createdAt';
          sortDir = 'asc';
          break;
        case 'budget_desc':
          sortBy = 'budget';
          sortDir = 'desc';
          break;
        case 'budget_asc':
          sortBy = 'budget';
          sortDir = 'asc';
          break;
      }

      final query = <String, dynamic>{
        'page': _page,
        'pageSize': 10,
        if (_searchController.text.isNotEmpty) 'search': _searchController.text,
        if (_statusFilter != null) 'status': [_statusFilter!.toJson()], // Backend takes a List
        if (sortBy != null) 'sortBy': sortBy,
        if (sortDir != null) 'sortDir': sortDir,
      };

      final result = await repo.listRequests(query: query);

      if (mounted) {
        setState(() {
          _requests.addAll(result.items);
          _hasMore = result.page * result.pageSize < result.totalCount;
          _page++;
          _isError = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteDraft(String id) async {
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
        await ref.read(requestsRepositoryProvider).deleteDraft(id);
        _fetchRequests(refresh: true);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete draft')));
      }
    }
  }

  Widget _buildStatusFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _statusFilter == null,
            onSelected: (val) {
              if (val) {
                setState(() => _statusFilter = null);
                _fetchRequests(refresh: true);
              }
            },
          ),
          const SizedBox(width: 8),
          ...RequestStatus.values.map((s) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(s.label),
                selected: _statusFilter == s,
                onSelected: (val) {
                  setState(() => _statusFilter = val ? s : null);
                  _fetchRequests(refresh: true);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search requests...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortOption,
                    icon: const Icon(Icons.sort),
                    items: const [
                      DropdownMenuItem(value: 'newest', child: Text('Newest')),
                      DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
                      DropdownMenuItem(value: 'budget_desc', child: Text('Budget (High-Low)')),
                      DropdownMenuItem(value: 'budget_asc', child: Text('Budget (Low-High)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _sortOption = val);
                        _fetchRequests(refresh: true);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          _buildStatusFilter(),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchRequests(refresh: true),
              child: _buildListContent(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NewRequestScreen()))
              .then((_) => _fetchRequests(refresh: true));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListContent() {
    if (_requests.isEmpty && !_isLoading && !_isError) {
      final isFiltered = _searchController.text.isNotEmpty || _statusFilter != null;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isFiltered ? Icons.search_off : Icons.inbox, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    isFiltered ? 'No results for your filters' : 'You have no requests yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                  ),
                  if (!isFiltered) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NewRequestScreen()))
                            .then((_) => _fetchRequests(refresh: true));
                      },
                      child: const Text('Create your first request'),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_isError && _requests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Failed to load requests'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _fetchRequests(refresh: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80, top: 8, left: 16, right: 16),
      itemCount: _requests.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _requests.length) {
          if (_isError) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: TextButton(
                  onPressed: () => _fetchRequests(),
                  child: const Text('Failed to load more. Tap to retry.'),
                ),
              ),
            );
          }
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final req = _requests[index];
        return _buildRequestCard(req);
      },
    );
  }

  Widget _buildRequestCard(RequestSummary req) {
    final fmt = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0);
    final isDraft = req.status == RequestStatus.draft;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailScreen(id: req.id)))
              .then((_) => _fetchRequests(refresh: true));
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (req.thumbnailUrl != null)
              SizedBox(
                width: 100,
                height: 100,
                child: Image.network(req.thumbnailUrl!, fit: BoxFit.cover,
                  errorBuilder: (ctx, err, trace) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
                ),
              )
            else
              Container(
                width: 100,
                height: 100,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image, color: Colors.grey),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            req.referenceNumber,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(req.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            req.status.label,
                            style: TextStyle(color: _getStatusColor(req.status), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(req.roomType.label, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      fmt.format(req.budget),
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text('Updated: ${DateFormat.yMd().add_jm().format(req.updatedAt.toLocal())}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            if (isDraft)
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'edit') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => NewRequestScreen(editId: req.id)))
                        .then((_) => _fetchRequests(refresh: true));
                  } else if (val == 'delete') {
                    _deleteDraft(req.id);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              )
            else
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'progress') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProjectTimelineScreen(projectId: req.id)),
                    );
                  } else if (val == 'details') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailScreen(id: req.id)))
                        .then((_) => _fetchRequests(refresh: true));
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'progress',
                    child: Row(
                      children: [
                        Icon(Icons.timeline_rounded, size: 18, color: Color(0xFF8C4A3E)),
                        SizedBox(width: 8),
                        Text('Track Progress'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(value: 'details', child: Text('View Details')),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.draft: return Colors.grey;
      case RequestStatus.submitted: return Colors.blue;
      case RequestStatus.aiAnalysis: return Colors.indigo;
      case RequestStatus.proposalReady: return Colors.purple;
      case RequestStatus.awaitingApproval: return Colors.orange;
      case RequestStatus.approved: return Colors.teal;
      case RequestStatus.designerAssigned: return Colors.cyan;
      case RequestStatus.inProgress: return Colors.deepOrange;
      case RequestStatus.completed: return Colors.green;
      case RequestStatus.rejected: return Colors.red;
      case RequestStatus.cancelled: return Colors.black54;
    }
  }
}
