import 'package:flutter/material.dart';
import 'models/quote.dart';
import 'models/contract.dart';
import 'services/quotes_contracts_service.dart';
import 'theme/qc_theme.dart';
import 'widgets/quote_card.dart';
import 'widgets/contract_card.dart';
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
    'Stage1Released',
    'Stage2Approved',
    'Stage2ChangesRequested',
    'Stage2Rejected',
    'Draft',
  ];

  static const List<String> contractStatusOptions = [
    'All statuses',
    'PendingSignature',
    'Active',
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

  void _openQuoteDetail(Quote quote) {
    QuoteDetailBottomSheet.show(
      context,
      quote: quote,
      onStage2Decision: (action, feedback) async {
        try {
          await _service.stage2Decision(quote.id, action, feedback: feedback);
          _loadQuotes();
          _loadContracts();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(action == 'Approve' ? 'Quote approved! Contract generated.' : 'Decision recorded ($action).'),
                backgroundColor: action == 'Approve' ? QcTheme.success : QcTheme.primary,
                action: action == 'Approve'
                    ? SnackBarAction(
                        label: 'View Contract',
                        textColor: Colors.white,
                        onPressed: () => setState(() => _activeTab = 1),
                      )
                    : null,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Decision failed: $e'), backgroundColor: QcTheme.danger),
            );
          }
        }
      },
      onExport: (format) async {
        try {
          await _service.exportQuote(quote.id, format);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Exported ${format.toUpperCase()} successfully!'), backgroundColor: QcTheme.primary),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Export failed: $e'), backgroundColor: QcTheme.danger),
            );
          }
        }
      },
    );
  }

  void _openContractDetail(Contract contract) {
    ContractDetailBottomSheet.show(
      context,
      contract: contract,
      onSign: () async {
        try {
          await _service.signContract(contract.id);
          _loadContracts();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contract signed and active!'), backgroundColor: QcTheme.success),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to sign: $e'), backgroundColor: QcTheme.danger),
            );
          }
        }
      },
      onCancel: () async {
        try {
          await _service.cancelContract(contract.id);
          _loadContracts();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contract cancelled'), backgroundColor: QcTheme.surfaceSunken),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to cancel: $e'), backgroundColor: QcTheme.danger),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QcTheme.bg,
      appBar: AppBar(
        backgroundColor: QcTheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quotes & Contracts', style: QcTheme.serifTitle(fontSize: 20)),
            const Text(
              'Review itemized cost breakdowns and legal agreements',
              style: TextStyle(color: QcTheme.textSubtle, fontSize: 11),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: const BoxDecoration(
              color: QcTheme.surface,
              border: Border(bottom: BorderSide(color: QcTheme.border)),
            ),
            child: Row(
              children: [
                Expanded(child: _buildTabButton('Quotes Portal', 0, Icons.receipt_long)),
                const SizedBox(width: 8),
                Expanded(child: _buildTabButton('Contracts', 1, Icons.history_edu)),
              ],
            ),
          ),
        ),
      ),
      body: _activeTab == 0 ? _buildQuotesView() : _buildContractsView(),
    );
  }

  Widget _buildTabButton(String label, int tabIndex, IconData icon) {
    final isSelected = _activeTab == tabIndex;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tabIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? QcTheme.primary : QcTheme.surfaceSunken,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : QcTheme.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : QcTheme.textMuted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotesView() {
    return RefreshIndicator(
      onRefresh: _loadQuotes,
      color: QcTheme.primary,
      child: CustomScrollView(
        slivers: [
          // Filter / Search Toolbar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _quoteSearchController,
                    style: const TextStyle(color: QcTheme.textMain, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search quote scopes…',
                      hintStyle: const TextStyle(color: QcTheme.textSubtle, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: QcTheme.textMuted, size: 20),
                      suffixIcon: _quoteSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16, color: QcTheme.textMuted),
                              onPressed: () {
                                _quoteSearchController.clear();
                                _loadQuotes();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: QcTheme.surfaceSunken,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: QcTheme.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: QcTheme.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: QcTheme.primary)),
                    ),
                    onSubmitted: (_) => _loadQuotes(),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: quoteStatusOptions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (ctx, i) {
                        final opt = quoteStatusOptions[i];
                        final isSelected = _quoteStatusFilter == opt;
                        return ChoiceChip(
                          label: Text(opt, style: TextStyle(fontSize: 11.5, color: isSelected ? Colors.white : QcTheme.textMuted, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _quoteStatusFilter = opt);
                              _loadQuotes();
                            }
                          },
                          backgroundColor: QcTheme.surfaceSunken,
                          selectedColor: QcTheme.primary,
                          side: BorderSide(color: isSelected ? QcTheme.primary : QcTheme.borderSubtle),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quotes List State
          if (_isLoadingQuotes)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: QcTheme.primary)),
            )
          else if (_quotesError != null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 40, color: QcTheme.danger),
                      const SizedBox(height: 12),
                      Text('Error: $_quotesError', textAlign: TextAlign.center, style: const TextStyle(color: QcTheme.textMuted, fontSize: 13)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadQuotes, style: ElevatedButton.styleFrom(backgroundColor: QcTheme.primary), child: const Text('Retry')),
                    ],
                  ),
                ),
              ),
            )
          else if (_quotes.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 48, color: QcTheme.textSubtle),
                    SizedBox(height: 12),
                    Text('No quotes available', style: TextStyle(color: QcTheme.textMain, fontWeight: FontWeight.w600, fontSize: 15)),
                    SizedBox(height: 4),
                    Text('Quotes released by designers will appear here for review.', style: TextStyle(color: QcTheme.textSubtle, fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final q = _quotes[i];
                    return QuoteCard(
                      quote: q,
                      onTap: () => _openQuoteDetail(q),
                      onSubmit: () => _openQuoteDetail(q),
                      onDelete: null,
                    );
                  },
                  childCount: _quotes.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContractsView() {
    return RefreshIndicator(
      onRefresh: _loadContracts,
      color: QcTheme.primary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: contractStatusOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (ctx, i) {
                    final opt = contractStatusOptions[i];
                    final isSelected = _contractStatusFilter == opt;
                    return ChoiceChip(
                      label: Text(opt, style: TextStyle(fontSize: 11.5, color: isSelected ? Colors.white : QcTheme.textMuted, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _contractStatusFilter = opt);
                          _loadContracts();
                        }
                      },
                      backgroundColor: QcTheme.surfaceSunken,
                      selectedColor: QcTheme.primary,
                      side: BorderSide(color: isSelected ? QcTheme.primary : QcTheme.borderSubtle),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  },
                ),
              ),
            ),
          ),

          if (_isLoadingContracts)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: QcTheme.primary)),
            )
          else if (_contractsError != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 40, color: QcTheme.danger),
                    const SizedBox(height: 12),
                    Text('Error: $_contractsError', style: const TextStyle(color: QcTheme.textMuted, fontSize: 13)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadContracts, style: ElevatedButton.styleFrom(backgroundColor: QcTheme.primary), child: const Text('Retry')),
                  ],
                ),
              ),
            )
          else if (_contracts.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_edu_outlined, size: 48, color: QcTheme.textSubtle),
                    SizedBox(height: 12),
                    Text('No contracts found', style: TextStyle(color: QcTheme.textMain, fontWeight: FontWeight.w600, fontSize: 15)),
                    SizedBox(height: 4),
                    Text('Contracts generated from approved quotes will appear here.', style: TextStyle(color: QcTheme.textSubtle, fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final c = _contracts[i];
                    return ContractCard(
                      contract: c,
                      onTap: () => _openContractDetail(c),
                      onSign: () => _openContractDetail(c),
                      onCancel: () => _openContractDetail(c),
                    );
                  },
                  childCount: _contracts.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
