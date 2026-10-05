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

  final List<Quote> _localQuotes = [];
  final List<Contract> _localContracts = [];

  void _initLocalStore() {
    final releasedQuote = Quote(
      id: 'f315971a-0000-0000-0000-000000000001',
      projectRequestId: '7c88187a-7133-4fd2-0000-000000000001',
      designerId: '22222222-2222-2222-2222-222222222222',
      scopeSummary: 'Minimalist bedroom redesign with furniture, lighting and wall finishing',
      notes: 'Released proposal approved by Admin for Client Stage 2 decision.',
      isAiGenerated: false,
      status: 'Stage1Released',
      totalCost: 190000.00,
      createdAt: DateTime(2026, 9, 29),
      updatedAt: DateTime(2026, 9, 29),
      currentVersion: QuoteVersion(
        id: 'v-1',
        versionNumber: 1,
        authorId: '22222222-2222-2222-2222-222222222222',
        authorRole: 'Designer',
        materialsSubtotal: 110000,
        laborSubtotal: 45000,
        designFee: 15500,
        contingencyAmount: 8525,
        taxAmount: 10975,
        totalCost: 190000,
        createdAt: DateTime(2026, 9, 29),
        items: [
          QuoteVersionItem(id: 'i-w1', description: 'Wardrobe & Storage', category: 'Furniture', quantity: 1, unitCost: 45000, lineTotal: 45000),
          QuoteVersionItem(id: 'i-w2', description: 'Bed frame', category: 'Furniture', quantity: 1, unitCost: 65000, lineTotal: 65000),
          QuoteVersionItem(id: 'i-w3', description: 'Wall painting & finishing', category: 'Labor', quantity: 1, unitCost: 45000, lineTotal: 45000),
        ],
      ),
      items: [
        QuoteItem(id: 'i-w1', description: 'Wardrobe & Storage', category: 'Furniture', quantity: 1, unitCost: 45000, totalCost: 45000),
        QuoteItem(id: 'i-w2', description: 'Bed frame', category: 'Furniture', quantity: 1, unitCost: 65000, totalCost: 65000),
        QuoteItem(id: 'i-w3', description: 'Wall painting & finishing', category: 'Labor', quantity: 1, unitCost: 45000, totalCost: 45000),
      ],
    );

    _localQuotes.add(releasedQuote);

    final contract = Contract(
      id: '83239481-0000-0000-0000-000000000001',
      quoteId: releasedQuote.id,
      projectRequestId: releasedQuote.projectRequestId,
      designerId: releasedQuote.designerId,
      clientId: '11111111-1111-1111-1111-111111111111',
      status: 'PendingSignature',
      totalAmount: 190000.00,
      termsSummary: 'Minimalist bedroom redesign with furniture, lighting and wall finishing',
      terms: 'Official StyleSync Agreement. 50% advance deposit due upon signing, 50% upon handover.',
      signedAt: null,
      createdAt: DateTime(2026, 9, 29),
      updatedAt: DateTime(2026, 9, 29),
      quote: releasedQuote,
    );

    _localContracts.add(contract);
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

  Future<Quote?> getQuote(String id) async {
    try {
      final uri = Uri.parse('$_baseUrl/quotes/$id');
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 4));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        return Quote.fromJson(decoded as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[QuotesContractsService] getQuote API failed: $e.');
    }
    final idx = _localQuotes.indexWhere((q) => q.id == id);
    return idx != -1 ? _localQuotes[idx] : null;
  }

  // Stage 2 Decision (Client: Approve, RequestChanges, Reject)
  Future<dynamic> stage2Decision(String id, String action, {String? feedback}) async {
    try {
      final uri = Uri.parse('$_baseUrl/quotes/$id/stage2-decision');
      final res = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': action,
          'feedback': feedback,
        }),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (action == 'Approve') {
          final contract = Contract.fromJson(decoded as Map<String, dynamic>);
          _localContracts.insert(0, contract);
          final idx = _localQuotes.indexWhere((q) => q.id == id);
          if (idx != -1) {
            _localQuotes[idx] = _localQuotes[idx].copyWith(status: 'Stage2Approved', updatedAt: DateTime.now());
          }
          return contract;
        }
        return decoded;
      }
    } catch (e) {
      debugPrint('[QuotesContractsService] stage2Decision API failed: $e.');
    }

    final idx = _localQuotes.indexWhere((q) => q.id == id);
    if (idx != -1) {
      if (action == 'Approve') {
        final approvedQuote = _localQuotes[idx].copyWith(status: 'Stage2Approved', updatedAt: DateTime.now());
        _localQuotes[idx] = approvedQuote;

        final contract = Contract(
          id: 'cnt-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
          quoteId: approvedQuote.id,
          projectRequestId: approvedQuote.projectRequestId,
          designerId: approvedQuote.designerId,
          clientId: 'client-1',
          status: 'PendingSignature',
          totalAmount: approvedQuote.totalCost,
          termsSummary: approvedQuote.scopeSummary,
          terms: 'Official contract for ${approvedQuote.scopeSummary}. 50% upfront deposit, 50% upon project completion.',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          quote: approvedQuote,
        );
        _localContracts.insert(0, contract);
        return contract;
      } else if (action == 'RequestChanges') {
        final changedQuote = _localQuotes[idx].copyWith(status: 'Stage2ChangesRequested', updatedAt: DateTime.now());
        _localQuotes[idx] = changedQuote;
        return {'message': 'Revision requested'};
      } else {
        final rejectedQuote = _localQuotes[idx].copyWith(status: 'Stage2Rejected', updatedAt: DateTime.now());
        _localQuotes[idx] = rejectedQuote;
        return {'message': 'Quote rejected'};
      }
    }
    throw Exception('Quote not found');
  }

  // Export quote PDF/CSV
  Future<String> exportQuote(String id, String format) async {
    try {
      final uri = Uri.parse('$_baseUrl/quotes/$id/export?format=$format');
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 4));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return res.body;
      }
    } catch (e) {
      debugPrint('[QuotesContractsService] exportQuote API failed: $e.');
    }
    final quote = await getQuote(id);
    return 'StyleSync Quotation Export\nQuote ID: ${quote?.id}\nScope: ${quote?.scopeSummary}\nTotal: LKR ${quote?.totalCost}';
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

  Future<Contract?> getContract(String id) async {
    try {
      final uri = Uri.parse('$_baseUrl/contracts/$id');
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 4));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        return Contract.fromJson(decoded as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[QuotesContractsService] getContract API failed: $e.');
    }
    final idx = _localContracts.indexWhere((c) => c.id == id);
    return idx != -1 ? _localContracts[idx] : null;
  }
}
