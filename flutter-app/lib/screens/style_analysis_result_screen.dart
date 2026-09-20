import 'package:flutter/material.dart';
import '../services/project_request_api.dart';
import '../models/project_request.dart';
import '../models/style_analysis_result.dart';

class StyleAnalysisResultScreen extends StatefulWidget {
  final String requestId;

  const StyleAnalysisResultScreen({Key? key, required this.requestId}) : super(key: key);

  @override
  State<StyleAnalysisResultScreen> createState() => _StyleAnalysisResultScreenState();
}

class _StyleAnalysisResultScreenState extends State<StyleAnalysisResultScreen> {
  final _apiService = ProjectRequestApiService();
  ProjectRequestModel? _request;
  bool _isLoading = true;
  int _selectedPhotoIdx = 0; // tracks active thumbnail in the photo gallery

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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

  Color _parseHexColor(String hexString) {
    try {
      final hexMatch = RegExp(r'#([A-Fa-f0-9]{6})').firstMatch(hexString);
      if (hexMatch != null) {
        final colorStr = 'FF${hexMatch.group(1)}';
        return Color(int.parse(colorStr, radix: 16));
      }
    } catch (_) {}
    return Colors.indigo;
  }

  Widget _buildStatusHeader(String status) {
    String emoji = '🟢';
    String title = 'Proposal Ready';
    String description = 'AI Style Analysis complete! Ready for client approval.';
    Color bgColor = Colors.green.shade50;
    Color borderColor = Colors.green.shade300;
    Color textColor = Colors.green.shade900;

    switch (status) {
      case 'Draft':
        emoji = '📝'; title = 'Draft';
        description = 'Request created. Ready to submit for AI analysis.';
        bgColor = Colors.blue.shade50; borderColor = Colors.blue.shade300; textColor = Colors.blue.shade900;
        break;
      case 'Submitted':
        emoji = '📤'; title = 'Submitted';
        description = 'Request queued. Preparing AI Style Analysis Agent...';
        bgColor = Colors.amber.shade50; borderColor = Colors.amber.shade300; textColor = Colors.amber.shade900;
        break;
      case 'AIAnalysis':
        emoji = '🤖'; title = 'AI Analysis';
        description = 'Analyzing your room photos & preferences...';
        bgColor = Colors.purple.shade50; borderColor = Colors.purple.shade300; textColor = Colors.purple.shade900;
        break;
      case 'ProposalReady':
        emoji = '🟢'; title = 'Proposal Ready';
        description = 'AI Style Analysis complete! Recommendation ready.';
        bgColor = Colors.green.shade50; borderColor = Colors.green.shade300; textColor = Colors.green.shade900;
        break;
      case 'AwaitingApproval':
        emoji = '⏳'; title = 'Awaiting Approval';
        description = 'Awaiting client approval before passing to Designer Matching.';
        bgColor = Colors.orange.shade50; borderColor = Colors.orange.shade300; textColor = Colors.orange.shade900;
        break;
      case 'Approved':
        emoji = '✅'; title = 'Approved';
        description = 'Request approved! Assigned to Designer Matching.';
        bgColor = Colors.teal.shade50; borderColor = Colors.teal.shade300; textColor = Colors.teal.shade900;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Request Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
          const SizedBox(height: 4),
          Text(description, style: TextStyle(fontSize: 13, color: textColor)),
        ],
      ),
    );
  }

  /// ── TOP SECTION: All Uploaded Room Photos Gallery (Node 1 Input)
  Widget _buildOriginalPhotoSection(ProjectRequestModel request) {
    final photos = request.photos;
    // Derive photo URL purely from props — no hardcoded fallbacks
    final selectedUrl = photos.isNotEmpty ? photos[_selectedPhotoIdx.clamp(0, photos.length - 1)].photoUrl : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Text('📷', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                const Text(
                  'Original Room Photos',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    photos.isEmpty ? 'No Photos' : '${photos.length} Photo${photos.length != 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Primary large photo viewer
          ClipRRect(
            borderRadius: photos.length > 1
                ? BorderRadius.zero
                : const BorderRadius.vertical(bottom: Radius.circular(14)),
            child: selectedUrl != null
                ? Stack(
                    children: [
                      Image.network(
                        selectedUrl,
                        width: double.infinity,
                        height: 210,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, _) => _buildPhotoPlaceholder(210),
                      ),
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Photo ${_selectedPhotoIdx + 1} of ${photos.length}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  )
                : _buildPhotoPlaceholder(210),
          ),

          // Thumbnail strip — all photos, tappable
          if (photos.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, idx) {
                    final isSelected = idx == _selectedPhotoIdx;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedPhotoIdx = idx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF818CF8) : Colors.white.withOpacity(0.12),
                            width: isSelected ? 2.5 : 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Opacity(
                            opacity: isSelected ? 1.0 : 0.55,
                            child: Image.network(
                              photos[idx].photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, _) => Container(
                                color: const Color(0xFF1E293B),
                                child: const Icon(Icons.broken_image, color: Colors.white24, size: 20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Caption
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Text(
              'Input provided to Node 1 (Style Analysis Agent) for feature extraction.',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: const Color(0xFF1E293B),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined, color: Colors.white.withOpacity(0.2), size: 40),
          const SizedBox(height: 8),
          Text('No photo uploaded', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildConceptPlaceholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: const Color(0xFF1E1B4B),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.palette_outlined, color: Colors.white.withOpacity(0.18), size: 44),
          const SizedBox(height: 12),
          Text(
            'Concept render not yet generated',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Submit the request for AI analysis to generate the concept image.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.18), fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// ── MIDDLE SECTION: AI Style Analysis Metrics (Node 1 Output)
  Widget _buildAIMetricsSection(StyleAnalysisResultModel analysis) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF31104B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF818CF8).withOpacity(0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: title + confidence badge
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFFF59E0B), size: 22),
                const SizedBox(width: 8),
                const Text(
                  'AI Style Analysis (Node 1)',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${analysis.confidenceScore.toStringAsFixed(1)}% Confidence',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Primary & Secondary styles
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PRIMARY STYLE', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text('🏙️ ${analysis.primaryStyle}',
                            style: const TextStyle(color: Color(0xFFA5B4FC), fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SECONDARY ACCENT', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text('🤍 ${analysis.secondaryStyle}',
                            style: const TextStyle(color: Color(0xFFFCD34D), fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Recommended Colors
            Row(
              children: [
                const Icon(Icons.palette, color: Color(0xFF818CF8), size: 14),
                const SizedBox(width: 6),
                const Text('Palette Swatches:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: analysis.recommendedColors.map((colorText) {
                final color = _parseHexColor(colorText);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(colorText, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Detected Features
            Row(
              children: [
                const Icon(Icons.tune, color: Color(0xFF34D399), size: 14),
                const SizedBox(width: 6),
                const Text('Spatial Features:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            ...analysis.detectedFeatures.take(4).map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 14),
                  const SizedBox(width: 8),
                  Expanded(child: Text(feature, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// ── BOTTOM SECTION: 🎨 AI-Generated Concept Render (Node 2 Output)
  Widget _buildConceptRenderSection(StyleAnalysisResultModel analysis) {
    // Use actual concept render URL only — no hardcoded fallbacks
    final conceptUrl = analysis.conceptRenderUrl.isNotEmpty ? analysis.conceptRenderUrl : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.45)),
        boxShadow: [BoxShadow(color: const Color(0xFFA855F7).withOpacity(0.15), blurRadius: 24, spreadRadius: 0)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Row(
              children: [
                const Text('🎨', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI-GENERATED DESIGN CONCEPT',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Synthesized by Node 2 (Concept Image Agent) using Node 1 structured output.',
                        style: TextStyle(color: Color(0xFFA5B4FC), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFA855F7).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🤖', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    '${analysis.primaryStyle} + ${analysis.secondaryStyle} Redesign',
                    style: const TextStyle(color: Color(0xFFC084FC), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          // Concept Render Image or placeholder
          conceptUrl != null
              ? ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: Stack(
                    children: [
                      Image.network(
                        conceptUrl,
                        width: double.infinity,
                        height: 280,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, _) => _buildConceptPlaceholder(280),
                      ),
                      // Gradient overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              stops: const [0.0, 0.4, 1.0],
                              colors: [
                                const Color(0xFF0F172A).withOpacity(0.95),
                                const Color(0xFF0F172A).withOpacity(0.5),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Overlay text
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Generative AI Redesign Concept',
                                    style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                  ),
                                  Text(
                                    '${analysis.primaryStyle} & ${analysis.secondaryStyle} Room Makeover',
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: const Text('8K Photorealistic', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: _buildConceptPlaceholder(200),
                ),
          // AI Summary
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
              ),
              child: Text(
                '💬 Agent Summary: ${analysis.analysisSummary}',
                style: const TextStyle(color: Color(0xFFE0E7FF), fontSize: 13, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('🤖 Request & AI Analysis'),
        backgroundColor: const Color(0xFF1E1B4B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF818CF8)))
          : _request == null
              ? const Center(child: Text('Request not found.', style: TextStyle(color: Colors.white)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Status Lifecycle Header ──
                      _buildStatusHeader(_request!.status),

                      if (_request!.styleAnalysis != null) ...[
                        // ── TOP: 📷 Original Uploaded Room Photo(s) ──
                        _buildOriginalPhotoSection(_request!),

                        // ── MIDDLE: 🤖 AI Style Analysis Metrics (Node 1 Output) ──
                        _buildAIMetricsSection(_request!.styleAnalysis!),

                        // ── BOTTOM: 🎨 AI-Generated Concept Render (Node 2 Output) ──
                        _buildConceptRenderSection(_request!.styleAnalysis!),
                      ],

                      // ── Proceed Action Button ──
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Style analysis saved! Ready for Designer Matching (Student 1).'),
                                backgroundColor: Color(0xFF1E1B4B),
                              ),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Proceed to Designer Matching 👨‍🎨', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
