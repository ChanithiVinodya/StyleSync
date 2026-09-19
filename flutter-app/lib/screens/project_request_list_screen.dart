import 'package:flutter/material.dart';
import '../services/project_request_api.dart';
import '../models/project_request.dart';
import 'create_project_request_screen.dart';
import 'style_analysis_result_screen.dart';

class ProjectRequestListScreen extends StatefulWidget {
  const ProjectRequestListScreen({Key? key}) : super(key: key);

  @override
  State<ProjectRequestListScreen> createState() => _ProjectRequestListScreenState();
}

class _ProjectRequestListScreenState extends State<ProjectRequestListScreen> {
  final _apiService = ProjectRequestApiService();
  List<ProjectRequestModel> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.fetchAllRequests();
      setState(() {
        _requests = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ProposalReady':
        return Colors.green;
      case 'Submitted':
      case 'AIAnalysis':
        return Colors.orange;
      case 'Draft':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StyleSync - My Room Makeovers'),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRequests,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _requests.isEmpty
                ? const Center(child: Text('No room makeover requests yet.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final req = _requests[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('🏠 ${req.roomType}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(req.status).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  req.status,
                                  style: TextStyle(
                                    color: _getStatusColor(req.status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text('Dimensions: ${req.lengthFeet} × ${req.widthFeet} × ${req.heightFeet} ft'),
                              Text('Budget: LKR ${req.budgetLkr.toStringAsFixed(0)}'),
                              if (req.styleAnalysis != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    '🎨 AI Style: ${req.styleAnalysis!.primaryStyle} (${req.styleAnalysis!.confidenceScore.toStringAsFixed(0)}%)',
                                    style: const TextStyle(
                                        color: Colors.indigo, fontWeight: FontWeight.w600),
                                  ),
                                ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StyleAnalysisResultScreen(requestId: req.id),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateProjectRequestScreen()),
          ).then((_) => _fetchRequests());
        },
        backgroundColor: Colors.indigo.shade900,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Request', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
