import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/quote.dart';
import '../models/contract.dart';
import '../models/quote_item.dart';

class QuotesContractsService {
  static final QuotesContractsService _instance = QuotesContractsService._internal();
  factory QuotesContractsService() => _instance;

  QuotesContractsService._internal() {
    _initLocalStore();
  }

  // Base URL logic: Localhost on web/desktop, 10.0.2.2 on Android emulator
  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:5000/api';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5000/api';
      default:
        return 'http://localhost:5000/api';
    }
  }

  String baseUrl = defaultBaseUrl;
  String get _baseUrl => baseUrl;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // Local fallback caches matching screenshots
  final List<Quote> _localQuotes = [];
  final List<Contract> _localContracts = [];

  void _initLocalStore() {
    final defaultQuotes = [
      Quote(
        id: 'q-101',
        projectRequestId: 'req-001',
        designerId: 'des-001',
        scopeSummary: 'Modern bedroom refresh, 200 sq ft.',
        notes: 'Fallback estimate — generated without a live LLM call',
        isAiGenerated: false,
        status: 'Draft',
        totalCost: 180000.00,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        items: [
          QuoteItem(id: 'i-1', description: 'Wall Panel & Minimalist Bed Headboard', category: 'Carpentry', quantity: 1, unitCost: 95000, totalCost: 95000),
          QuoteItem(id: 'i-2', description: 'Warm Cove Lighting & LED Profiles', category: 'Electrical', quantity: 2, unitCost: 25000, totalCost: 50000),
          QuoteItem(id: 'i-3', description: 'Premium Matte Finish Wall Paint', category: 'Painting', quantity: 1, unitCost: 35000, totalCost: 35000),
        ],
      ),
      Quote(
        id: 'q-102',
        projectRequestId: 'req-002',
        designerId: 'des-002',
        scopeSummary: 'Minimalist bedroom refresh, 200 sq ft.',
        notes: 'Fallback estimate — generated without a live LLM call',
        isAiGenerated: true,
        status: 'Draft',
        totalCost: 150000.00,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        items: [
          QuoteItem(id: 'i-4', description: 'Design — minimalist bedroom concept & planning', category: 'Design', quantity: 1, unitCost: 15000, totalCost: 15000),
          QuoteItem(id: 'i-5', description: 'Labor — minimalist bedroom installation & craftsmanship', category: 'Labor', quantity: 1, unitCost: 45000, totalCost: 45000),
          QuoteItem(id: 'i-6', description: 'Materials — minimalist bedroom fixtures & finishes', category: 'Materials', quantity: 1, unitCost: 52500, totalCost: 52500),
          QuoteItem(id: 'i-7', description: 'Furniture — minimalist bedroom curated styling', category: 'Furniture', quantity: 1, unitCost: 37500, totalCost: 37500),
        ],
      ),
      Quote(
        id: 'q-100',
        projectRequestId: 'req-000',
        designerId: 'des-001',
        scopeSummary: 'Minimalist bedroom redesign with furniture, lighting and wall finishing',
        notes: 'Turnkey interior redesign with 3-year warranty.',
        isAiGenerated: true,
        status: 'Accepted',
        totalCost: 190000.00,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        updatedAt: DateTime.now().subtract(const Duration(days: 4)),
        items: [
          QuoteItem(id: 'i-8', description: 'Custom Oak Minimalist Wardrobe', category: 'Furniture', quantity: 1, unitCost: 100000, totalCost: 100000),
          QuoteItem(id: 'i-9', description: 'Recessed Architectural Lighting', category: 'Electrical', quantity: 4, unitCost: 12500, totalCost: 50000),
          QuoteItem(id: 'i-10', description: 'Wall panelling & painting', category: 'Materials', quantity: 1, unitCost: 40000, totalCost: 40000),
        ],
      ),
      Quote(
        id: 'q-099',
        projectRequestId: 'req-099',
        designerId: 'des-003',
        scopeSummary: 'Modern living room refresh, 200 sq ft.',
        notes: 'Cancelled quote record retained for auditing.',
        isAiGenerated: false,
        status: 'Rejected',
        totalCost: 200000.00,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        updatedAt: DateTime.now().subtract(const Duration(days: 4)),
        items: [
          QuoteItem(id: 'i-11', description: 'Living Room TV Feature Wall', category: 'Carpentry', quantity: 1, unitCost: 120000, totalCost: 120000),
          QuoteItem(id: 'i-12', description: 'Linear Lighting System', category: 'Electrical', quantity: 2, unitCost: 40000, totalCost: 80000),
        ],
      ),
    ];

    _localQuotes.addAll(defaultQuotes);

    final defaultContracts = [
      Contract(
        id: '832394',
        quoteId: 'q-100',
        projectRequestId: 'req-000',
        designerId: 'des-001',
        clientId: 'client-001',
        status: 'Active',
        totalAmount: 190000.00,
        termsSummary: 'Minimalist bedroom redesign with furniture, lighting and wall finishing',
        terms: 'Standard StyleSync Design & Execution Contract. 50% deposit paid upon signing, 50% upon final handover.',
        signedAt: DateTime.now().subtract(const Duration(days: 4)),
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        updatedAt: DateTime.now().subtract(const Duration(days: 4)),
        quote: defaultQuotes[2],
      ),
      Contract(
        id: '39b2de',
        quoteId: 'q-099',
        projectRequestId: 'req-099',
        designerId: 'des-003',
        clientId: 'client-002',
        status: 'Cancelled',
        totalAmount: 200000.00,
        termsSummary: 'Modern living room refresh, 200 sq ft.',
        terms: 'Contract was cancelled by client before signature.',
        signedAt: null,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        updatedAt: DateTime.now().subtract(const Duration(days: 4)),
        quote: defaultQuotes[3],
      ),
    ];

    _localContracts.addAll(defaultContracts);
  }

  // ================= QUOTES ENDPOINTS =================

  Future<List<Quote>> listQuotes({String? status, String? search}) async {
    try {
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty && status != 'All statuses') {
        queryParams['status'] = status;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final uri = Uri.parse('$_baseUrl/quotes').replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 4));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        List<dynamic> items = [];
        if (decoded is Map<String, dynamic> && decoded.containsKey('items')) {
          items = decoded['items'] as List<dynamic>;
        } else if (decoded is List) {
          items = decoded;
        }
        final quotes = items.map((e) => Quote.fromJson(e as Map<String, dynamic>)).toList();
        if (quotes.isNotEmpty) {
          return quotes;
        }
      }
    } catch (e) {
      debugPrint('[QuotesContractsService] Live API quotes fetch failed: $e. Using local store.');
    }

    // Local filter fallback
    var filtered = List<Quote>.from(_localQuotes);
    if (status != null && status.isNotEmpty && status != 'All statuses') {
      filtered = filtered.where((q) => q.status.toLowerCase() == status.toLowerCase()).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final query = search.trim().toLowerCase();
      filtered = filtered.where((q) => q.scopeSummary.toLowerCase().contains(query)).toList();
    }
    return filtered;
  }

  Future<Quote> createQuote(QuoteFormPayload payload) async {
    try {
      final uri = Uri.parse('$_baseUrl/quotes');
      final res = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'projectRequestId': payload.projectRequestId ?? '00000000-0000-0000-0000-000000000001',
          'designerId': payload.designerId ?? '00000000-0000-0000-0000-000000000002',
          'scopeSummary': payload.scopeSummary,
          'notes': payload.notes,
          'isAiGenerated': payload.isAiGenerated,
          'items': payload.items.map((i) => {
            'description': i.description,
            'category': i.category,
            'quantity': i.quantity,
            'unitCost': i.unitCost,
          }).toList(),
        }),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        final created = Quote.fromJson(decoded as Map<String, dynamic>);
        _localQuotes.insert(0, created);
        return created;
      }
    } catch (e) {
      debugPrint('[QuotesContractsService] createQuote API failed: $e. Writing to local store.');
    }

    // Local fallback
    final total = payload.items.fold(0.0, (sum, i) => sum + i.calculatedTotal);
    final newQuote = Quote(
      id: 'q-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      projectRequestId: payload.projectRequestId ?? 'req-custom',
      designerId: payload.designerId ?? 'des-custom',
      scopeSummary: payload.scopeSummary,
      notes: payload.notes,
      isAiGenerated: payload.isAiGenerated,
      status: 'Draft',
      totalCost: total,
      items: payload.items,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _localQuotes.insert(0, newQuote);
    return newQuote;
  }

  Future<Quote> updateQuote(String id, QuoteFormPayload payload) async {
    try {
      final uri = Uri.parse('$_baseUrl/quotes/$id');
      final res = await http.put(
        uri,
        headers: _headers,
        body: jsonEncode({
          'scopeSummary': payload.scopeSummary,
          'notes': payload.notes,
          'items': payload.items.map((i) => {
            'description': i.description,
            'category': i.category,
            'quantity': i.quantity,
            'unitCost': i.unitCost,
          }).toList(),
        }),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        final updated = Quote.fromJson(decoded as Map<String, dynamic>);
        final idx = _localQuotes.indexWhere((q) => q.id == id);
        if (idx != -1) _localQuotes[idx] = updated;
        return updated;
      }
    } catch (e) {
      debugPrint('[QuotesContractsService] updateQuote API failed: $e. Updating local store.');
    }

    final idx = _localQuotes.indexWhere((q) => q.id == id);
    if (idx != -1) {
      final total = payload.items.fold(0.0, (sum, i) => sum + i.calculatedTotal);
      final updated = _localQuotes[idx].copyWith(
        scopeSummary: payload.scopeSummary,
        notes: payload.notes,
        items: payload.items,
        totalCost: total,
        updatedAt: DateTime.now(),
      );
      _localQuotes[idx] = updated;
      return updated;
    }
    throw Exception('Quote not found');
  }

  Future<Quote> updateQuoteStatus(String id, String status) async {
    try {
      final uri = Uri.parse('$_baseUrl/quotes/$id/status');
      final res = await http.patch(
        uri,
        headers: _headers,
        body: jsonEncode({'status': status}),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        final updated = Quote.fromJson(decoded as Map<String, dynamic>);
        final idx = _localQuotes.indexWhere((q) => q.id == id);
        if (idx != -1) _localQuotes[idx] = updated;
        return updated;
      }
    } catch (e) {
      debugPrint('[QuotesContractsService] updateQuoteStatus API failed: $e.');
    }

    final idx = _localQuotes.indexWhere((q) => q.id == id);
    if (idx != -1) {
      final updated = _localQuotes[idx].copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
      _localQuotes[idx] = updated;
      return updated;
    }
    throw Exception('Quote not found');
  }

  Future<Contract?> acceptQuote(String id, {String? clientId}) async {
    try {
      final url = clientId != null
          ? '$_baseUrl/quotes/$id/accept?clientId=$clientId'
          : '$_baseUrl/quotes/$id/accept';
      final res = await http.post(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 5));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        final contract = Contract.fromJson(decoded as Map<String, dynamic>);
        _localContracts.insert(0, contract);
        final idx = _localQuotes.indexWhere((q) => q.id == id);
        if (idx != -1) {
          _localQuotes[idx] = _localQuotes[idx].copyWith(status: 'Accepted', updatedAt: DateTime.now());
        }
        return contract;
      }
    } catch (e) {
      debugPrint('[QuotesContractsService] acceptQuote API failed: $e.');
    }

    final idx = _localQuotes.indexWhere((q) => q.id == id);
    if (idx != -1) {
      final acceptedQuote = _localQuotes[idx].copyWith(
        status: 'Accepted',
        updatedAt: DateTime.now(),
      );
      _localQuotes[idx] = acceptedQuote;

      final contract = Contract(
        id: DateTime.now().millisecondsSinceEpoch.toRadixString(16).padLeft(6, '0').substring(0, 6),
        quoteId: acceptedQuote.id,
        projectRequestId: acceptedQuote.projectRequestId,
        designerId: acceptedQuote.designerId,
        clientId: clientId ?? 'client-auto',
        status: 'Active',
        totalAmount: acceptedQuote.totalCost,
        termsSummary: acceptedQuote.scopeSummary,
        terms: 'Official contract for ${acceptedQuote.scopeSummary}. 50% upfront deposit, 50% upon project completion.',
        signedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        quote: acceptedQuote,
      );
      _localContracts.insert(0, contract);
      return contract;
    }
    return null;
  }

  Future<void> deleteQuote(String id) async {
    try {
      final uri = Uri.parse('$_baseUrl/quotes/$id');
      await http.delete(uri, headers: _headers).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('[QuotesContractsService] deleteQuote API failed: $e.');
    }
    _localQuotes.removeWhere((q) => q.id == id);
  }

  // ================= AI AGENT DRAFT ENDPOINTS =================

  Future<AgentBudgetScopeResponse> previewQuoteFromAgent(AiDraftPayload payload) async {
    try {
      final uri = Uri.parse('$_baseUrl/quotes/draft-preview');
      final res = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(payload.toJson()),
      ).timeout(const Duration(seconds: 7));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        return AgentBudgetScopeResponse.fromJson(decoded as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[QuotesContractsService] previewQuoteFromAgent API failed: $e. Using deterministic algorithm.');
    }

    // Deterministic mathematical algorithm mirroring backend budget_scope_agent.py
    final target = (payload.budgetMin + payload.budgetMax) / 2 > 0
        ? (payload.budgetMin + payload.budgetMax) / 2
        : (payload.roomSizeSqft * 800);

    final splits = [
      {'cat': 'Design', 'pct': 0.10, 'desc': 'Design — ${payload.styleProfile.toLowerCase()} ${payload.roomType.toLowerCase()} concept & planning'},
      {'cat': 'Labor', 'pct': 0.30, 'desc': 'Labor — ${payload.styleProfile.toLowerCase()} ${payload.roomType.toLowerCase()} installation & craftsmanship'},
      {'cat': 'Materials', 'pct': 0.35, 'desc': 'Materials — ${payload.styleProfile.toLowerCase()} ${payload.roomType.toLowerCase()} fixtures & finishes'},
      {'cat': 'Furniture', 'pct': 0.25, 'desc': 'Furniture — ${payload.styleProfile.toLowerCase()} ${payload.roomType.toLowerCase()} curated styling'},
    ];

    final items = splits.map((s) {
      final cost = ((target * (s['pct'] as double)) / 100).round() * 100.0;
      return QuoteItem(
        id: 'ai-${s['cat']}',
        description: s['desc'] as String,
        category: s['cat'] as String,
        quantity: 1,
        unitCost: cost,
        totalCost: cost,
      );
    }).toList();

    final total = items.fold(0.0, (sum, i) => sum + i.calculatedTotal);

    return AgentBudgetScopeResponse(
      scopeSummary: '${payload.styleProfile} ${payload.roomType.toLowerCase()} refresh, ${payload.roomSizeSqft.toStringAsFixed(0)} sq ft.',
      items: items,
      notes: 'Fallback estimate — generated using deterministic category ratios (Design 10%, Labor 30%, Materials 35%, Furniture 25%).',
      estimatedTotal: total,
      withinBudget: payload.budgetMax > 0 ? (total >= payload.budgetMin && total <= payload.budgetMax) : true,
      source: 'fallback',
    );
  }

  Future<Quote> draftQuoteFromAgent(AiDraftPayload payload) async {
    try {
      final uri = Uri.parse('$_baseUrl/quotes/draft-from-agent');
      final res = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(payload.toJson()),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        final created = Quote.fromJson(decoded as Map<String, dynamic>);
        _localQuotes.insert(0, created);
        return created;
      }
    } catch (e) {
      debugPrint('[QuotesContractsService] draftQuoteFromAgent API failed: $e. Using local generation.');
    }

    final preview = await previewQuoteFromAgent(payload);
    final created = Quote(
      id: 'q-ai-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      projectRequestId: payload.projectRequestId ?? 'req-${DateTime.now().millisecondsSinceEpoch}',
      designerId: payload.designerId ?? 'des-ai',
      scopeSummary: preview.scopeSummary,
      notes: preview.notes ?? 'Fallback estimate — generated without a live LLM call',
      isAiGenerated: true,
      status: 'Draft',
      totalCost: preview.estimatedTotal,
      items: preview.items,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _localQuotes.insert(0, created);
    return created;
  }

  // ================= CONTRACTS ENDPOINTS =================

  Future<List<Contract>> listContracts({String? status}) async {
    try {
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty && status != 'All statuses') {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$_baseUrl/contracts').replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 4));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        List<dynamic> items = [];
        if (decoded is Map<String, dynamic> && decoded.containsKey('items')) {
          items = decoded['items'] as List<dynamic>;
        } else if (decoded is List) {
          items = decoded;
        }
        final list = items.map((e) => Contract.fromJson(e as Map<String, dynamic>)).toList();
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      debugPrint('[QuotesContractsService] live contracts list failed: $e. Using local store.');
    }

    var filtered = List<Contract>.from(_localContracts);
    if (status != null && status.isNotEmpty && status != 'All statuses') {
      filtered = filtered.where((c) => c.status.toLowerCase() == status.toLowerCase()).toList();
    }
    return filtered;
  }

  Future<Contract> signContract(String id) async {
    try {
      final uri = Uri.parse('$_baseUrl/contracts/$id/sign');
      final res = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({'signedAt': DateTime.now().toIso8601String()}),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        final updated = Contract.fromJson(decoded as Map<String, dynamic>);
        final idx = _localContracts.indexWhere((c) => c.id == id);
        if (idx != -1) _localContracts[idx] = updated;
        return updated;
      }
    } catch (e) {
      debugPrint('[QuotesContractsService] signContract API failed: $e.');
    }

    final idx = _localContracts.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final updated = _localContracts[idx].copyWith(
        status: 'Active',
        signedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _localContracts[idx] = updated;
      return updated;
    }
    throw Exception('Contract not found');
  }

  Future<Contract> cancelContract(String id) async {
    try {
      final uri = Uri.parse('$_baseUrl/contracts/$id/cancel');
      final res = await http.post(uri, headers: _headers).timeout(const Duration(seconds: 4));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        final updated = Contract.fromJson(decoded as Map<String, dynamic>);
        final idx = _localContracts.indexWhere((c) => c.id == id);
        if (idx != -1) _localContracts[idx] = updated;
        return updated;
      }
    } catch (e) {
      debugPrint('[QuotesContractsService] cancelContract API failed: $e.');
    }

    final idx = _localContracts.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final updated = _localContracts[idx].copyWith(
        status: 'Cancelled',
        updatedAt: DateTime.now(),
      );
      _localContracts[idx] = updated;
      return updated;
    }
    throw Exception('Contract not found');
  }
}
