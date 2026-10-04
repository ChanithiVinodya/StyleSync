import 'package:flutter/material.dart';
import 'models/quote.dart';
import 'models/contract.dart';
import 'services/quotes_contracts_service.dart';
import 'theme/qc_theme.dart';
import 'widgets/quote_card.dart';
import 'widgets/contract_card.dart';
import 'widgets/ai_draft_bottom_sheet.dart';
import 'widgets/quote_form_bottom_sheet.dart';
import 'widgets/quote_detail_bottom_sheet.dart';
import 'widgets/contract_detail_bottom_sheet.dart';

class QuotesContractsPage extends StatefulWidget {
  const QuotesContractsPage({super.key});

  @override
  State<QuotesContractsPage> createState() => _QuotesContractsPageState();
}

class _QuotesContractsPageState extends State<QuotesContractsPage> with SingleTickerProviderStateMixin {
  final _service = QuotesContractsService();

  // Active view: 0 = Quotes, 1 = Contracts
  int _activeTab = 0;

  // Quotes state
  List<Quote> _quotes = [];
  bool _isLoadingQuotes = true;
  String? _quotesError;
  String _quoteStatusFilter = 'All statuses';
  final _quoteSearchController = TextEditingController();

  // Contracts state
  List<Contract> _contracts = [];
  bool _isLoadingContracts = true;
  String? _contractsError;
  String _contractStatusFilter = 'All statuses';

  static const List<String> quoteStatusOptions = [
    'All statuses',
    'Draft',
    'Submitted',
    'ClientReview',
    'Accepted',
    'Rejected',
  ];

  static const List<String> contractStatusOptions = [
    'All statuses',
    'Active',
    'Draft',
    'PendingSignature',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _loadQuotes();
    _loadContracts();
  }

  @override
  void dispose() {
    _quoteSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadQuotes() async {
    setState(() {
      _isLoadingQuotes = true;
      _quotesError = null;
    });

    try {
      final list = await _service.listQuotes(
        status: _quoteStatusFilter == 'All statuses' ? null : _quoteStatusFilter,
        search: _quoteSearchController.text.trim().isEmpty ? null : _quoteSearchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _quotes = list;
          _isLoadingQuotes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _quotesError = e.toString();
          _isLoadingQuotes = false;
        });
      }
    }
  }

  Future<void> _loadContracts() async {
    setState(() {
      _isLoadingContracts = true;
      _contractsError = null;
    });

    try {
      final list = await _service.listContracts(
        status: _contractStatusFilter == 'All statuses' ? null : _contractStatusFilter,
      );
      if (mounted) {
        setState(() {
          _contracts = list;
          _isLoadingContracts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _contractsError = e.toString();
          _isLoadingContracts = false;
        });
      }
    }
  }

  // Quote Handlers
  void _openAiDraft() {
    AiDraftBottomSheet.show(
      context,
      onDraftCreated: (newQuote) {
        _loadQuotes();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI quote created for ${newQuote.scopeSummary}!'),
            backgroundColor: QcTheme.primary,
          ),
        );
      },
    );
  }

  void _openNewQuote({Quote? quoteToEdit}) {
    QuoteFormBottomSheet.show(
      context,
      initialQuote: quoteToEdit,
      onQuoteSaved: (saved) {
        _loadQuotes();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(quoteToEdit != null ? 'Quote updated!' : 'Quote created!'),
            backgroundColor: QcTheme.primary,
          ),
        );
      },
    );
  }

  Future<void> _handleAdvanceQuote(Quote q) async {
    final status = q.status.toLowerCase();
    String nextStatus;
    if (status == 'draft') {
      nextStatus = 'Submitted';
    } else if (status == 'submitted') {
      nextStatus = 'ClientReview';
    } else {
      nextStatus = 'Accepted';
    }

    if (nextStatus == 'Accepted') {
      await _handleAcceptQuote(q);
      return;
    }

    try {
      await _service.updateQuoteStatus(q.id, nextStatus);
      _loadQuotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quote moved to $nextStatus'), backgroundColor: QcTheme.primary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: QcTheme.danger),
        );
      }
    }
  }

  Future<void> _handleAcceptQuote(Quote q) async {
    try {
      final contract = await _service.acceptQuote(q.id);
      _loadQuotes();
      _loadContracts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quote accepted! Contract #${contract?.id ?? ""} automatically generated.'),
            backgroundColor: QcTheme.success,
            action: SnackBarAction(
              label: 'View Contracts',
              textColor: Colors.white,
              onPressed: () => setState(() => _activeTab = 1),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting quote: $e'), backgroundColor: QcTheme.danger),
        );
      }
    }
  }

  Future<void> _handleDeleteQuote(Quote q) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QcTheme.surface,
        title: const Text('Delete Quote?', style: TextStyle(color: QcTheme.textMain)),
        content: Text('Delete "${q.scopeSummary}"? This cannot be undone.', style: const TextStyle(color: QcTheme.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: QcTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: QcTheme.danger),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteQuote(q.id);
      _loadQuotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quote deleted'), backgroundColor: QcTheme.surfaceSunken),
        );
      }
    }
  }

  // Contract Handlers
  Future<void> _handleSignContract(Contract c) async {
    try {
      await _service.signContract(c.id);
      _loadContracts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contract signed and active!'), backgroundColor: QcTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign contract: $e'), backgroundColor: QcTheme.danger),
        );
      }
    }
  }

  Future<void> _handleCancelContract(Contract c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QcTheme.surface,
        title: const Text('Cancel Contract?', style: TextStyle(color: QcTheme.textMain)),
        content: Text('Cancel contract #${c.id}? It will be kept for history but marked Cancelled.', style: const TextStyle(color: QcTheme.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Active', style: TextStyle(color: QcTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: QcTheme.danger),
            child: const Text('Cancel Contract', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.cancelContract(c.id);
      _loadContracts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contract marked as Cancelled'), backgroundColor: QcTheme.surfaceSunken),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QcTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildTopAppBar(),

            // Main Content Area
            Expanded(
              child: _activeTab == 0 ? _buildQuotesTab() : _buildContractsTab(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildTopAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: QcTheme.bg,
        border: Border(bottom: BorderSide(color: QcTheme.borderSubtle, width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: QcTheme.textMuted, size: 20),
                onPressed: () {},
                tooltip: 'Back',
              ),
              const SizedBox(width: 4),
              // Rounded tile logo avatar 'S'
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF24201D),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: QcTheme.borderLight, width: 1),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'S',
                  style: TextStyle(
                    color: QcTheme.gold,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'StyleSync',
                    style: TextStyle(
                      color: QcTheme.textMain,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'DESIGNER',
                    style: TextStyle(
                      color: QcTheme.textSubtle,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Moon / Theme toggle
          IconButton(
            icon: const Icon(Icons.nightlight_round, color: QcTheme.gold, size: 20),
            onPressed: () {},
            tooltip: 'Theme: Dark',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161411),
        border: Border(top: BorderSide(color: Color(0xFF24201D), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Tab 0: Quotes
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _activeTab = 0),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _activeTab == 0 ? const Color(0xFF2E2721) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: _activeTab == 0 ? Border.all(color: const Color(0xFF38312B), width: 1) : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 18,
                        color: _activeTab == 0 ? QcTheme.gold : const Color(0xFF78716C),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Quotes',
                        style: TextStyle(
                          color: _activeTab == 0 ? QcTheme.gold : const Color(0xFF78716C),
                          fontSize: 13,
                          fontWeight: _activeTab == 0 ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Tab 1: Contracts
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _activeTab = 1),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _activeTab == 1 ? const Color(0xFF2E2721) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: _activeTab == 1 ? Border.all(color: const Color(0xFF38312B), width: 1) : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 18,
                        color: _activeTab == 1 ? QcTheme.gold : const Color(0xFF78716C),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Contracts',
                        style: TextStyle(
                          color: _activeTab == 1 ? QcTheme.gold : const Color(0xFF78716C),
                          fontSize: 13,
                          fontWeight: _activeTab == 1 ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= QUOTES TAB (Image 1) =================
  Widget _buildQuotesTab() {
    return RefreshIndicator(
      onRefresh: _loadQuotes,
      color: QcTheme.primary,
      backgroundColor: QcTheme.surface,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header: "Quotes" title & subtitle
          Text('Quotes', style: QcTheme.serifTitle(fontSize: 32)),
          const SizedBox(height: 4),
          const Text(
            'Draft, review, and turn accepted quotes into contracts.',
            style: TextStyle(
              color: QcTheme.textMuted,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons: Generate with AI & + New quote
          Row(
            children: [
              // Generate with AI
              Expanded(
                flex: 6,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: QcTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4DC48A36),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _openAiDraft,
                    icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                    label: const Text(
                      'Generate with AI',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // + New quote
              Expanded(
                flex: 5,
                child: OutlinedButton.icon(
                  onPressed: () => _openNewQuote(),
                  icon: const Icon(Icons.add, size: 16, color: QcTheme.textMain),
                  label: const Text(
                    'New quote',
                    style: TextStyle(
                      color: QcTheme.textMain,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: QcTheme.surfaceSunken,
                    side: const BorderSide(color: QcTheme.borderLight, width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search and Filter Row
          Row(
            children: [
              // Search input
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: QcTheme.surfaceSunken,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: QcTheme.border, width: 1),
                  ),
                  child: TextField(
                    controller: _quoteSearchController,
                    onSubmitted: (_) => _loadQuotes(),
                    style: const TextStyle(color: QcTheme.textMain, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search quotes...',
                      hintStyle: const TextStyle(color: QcTheme.textSubtle, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: QcTheme.textSubtle, size: 18),
                      suffixIcon: _quoteSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: QcTheme.textSubtle, size: 16),
                              onPressed: () {
                                _quoteSearchController.clear();
                                _loadQuotes();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Status Dropdown
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: QcTheme.surfaceSunken,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: QcTheme.border, width: 1),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _quoteStatusFilter,
                      isExpanded: true,
                      dropdownColor: QcTheme.surfaceSunken,
                      icon: const Icon(Icons.keyboard_arrow_down, color: QcTheme.textMuted, size: 18),
                      items: quoteStatusOptions.map((st) {
                        return DropdownMenuItem(
                          value: st,
                          child: Text(
                            st,
                            style: const TextStyle(color: QcTheme.textMain, fontSize: 12.5),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _quoteStatusFilter = val);
                          _loadQuotes();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Quotes list view
          if (_isLoadingQuotes) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: QcTheme.primary),
              ),
            ),
          ] else if (_quotesError != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x2EEF4444),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x66EF4444)),
              ),
              child: Column(
                children: [
                  Text(_quotesError!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 13)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _loadQuotes,
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                    label: const Text('Try Again', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ] else if (_quotes.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 48, color: QcTheme.borderLight),
                  const SizedBox(height: 12),
                  const Text('No quotes found', style: TextStyle(color: QcTheme.textMain, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('Create a new quote or generate one with the AI Agent.', style: TextStyle(color: QcTheme.textSubtle, fontSize: 13)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _openAiDraft,
                    icon: const Icon(Icons.auto_awesome, size: 15, color: Colors.white),
                    label: const Text('Draft with AI', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: QcTheme.primary),
                  ),
                ],
              ),
            ),
          ] else ...[
            ..._quotes.map((quote) => QuoteCard(
              quote: quote,
              onTap: () => QuoteDetailBottomSheet.show(
                context,
                quote: quote,
                onEdit: () => _openNewQuote(quoteToEdit: quote),
                onSubmit: () => _handleAdvanceQuote(quote),
                onDelete: () => _handleDeleteQuote(quote),
              ),
              onEdit: () => _openNewQuote(quoteToEdit: quote),
              onSubmit: () => _handleAdvanceQuote(quote),
              onDelete: () => _handleDeleteQuote(quote),
            )),
          ],
        ],
      ),
    );
  }

  // ================= CONTRACTS TAB (Image 2) =================
  Widget _buildContractsTab() {
    return RefreshIndicator(
      onRefresh: _loadContracts,
      color: QcTheme.primary,
      backgroundColor: QcTheme.surface,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header: "Contracts Dashboard" title & subtitle
          Text('Contracts Dashboard', style: QcTheme.serifTitle(fontSize: 30)),
          const SizedBox(height: 4),
          const Text(
            'Review agreements, track signatures, and inspect submitted quote specifications.',
            style: TextStyle(
              color: QcTheme.textMuted,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),

          // Filter Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: QcTheme.surfaceSunken,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: QcTheme.border, width: 1),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _contractStatusFilter,
                      isExpanded: true,
                      dropdownColor: QcTheme.surfaceSunken,
                      icon: const Icon(Icons.keyboard_arrow_down, color: QcTheme.textMuted, size: 18),
                      items: contractStatusOptions.map((st) {
                        return DropdownMenuItem(
                          value: st,
                          child: Text(
                            st,
                            style: const TextStyle(color: QcTheme.textMain, fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _contractStatusFilter = val);
                          _loadContracts();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Contracts list view
          if (_isLoadingContracts) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: QcTheme.primary),
              ),
            ),
          ] else if (_contractsError != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x2EEF4444),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x66EF4444)),
              ),
              child: Column(
                children: [
                  Text(_contractsError!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 13)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _loadContracts,
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                    label: const Text('Try Again', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ] else if (_contracts.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.verified_outlined, size: 48, color: QcTheme.borderLight),
                  const SizedBox(height: 12),
                  const Text('No contracts yet', style: TextStyle(color: QcTheme.textMain, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('Accept a quote in the Quotes tab to automatically generate a contract.', textAlign: TextAlign.center, style: TextStyle(color: QcTheme.textSubtle, fontSize: 13)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() => _activeTab = 0),
                    style: ElevatedButton.styleFrom(backgroundColor: QcTheme.primary),
                    child: const Text('View Quotes', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ] else ...[
            ..._contracts.map((contract) => ContractCard(
              contract: contract,
              onTap: () => ContractDetailBottomSheet.show(
                context,
                contract: contract,
                onSign: () => _handleSignContract(contract),
                onCancel: () => _handleCancelContract(contract),
              ),
              onSign: () => _handleSignContract(contract),
              onCancel: () => _handleCancelContract(contract),
            )),
          ],
        ],
      ),
    );
  }
}
