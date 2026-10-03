import 'quote_item.dart';

class Quote {
  final String id;
  final String projectRequestId;
  final String designerId;
  final String scopeSummary;
  final String? notes;
  final bool isAiGenerated;
  final String status;
  final double totalCost;
  final List<QuoteItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Quote({
    required this.id,
    required this.projectRequestId,
    required this.designerId,
    required this.scopeSummary,
    this.notes,
    this.isAiGenerated = false,
    this.status = 'Draft',
    required this.totalCost,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    String statusStr = 'Draft';
    if (json['status'] != null) {
      if (json['status'] is String) {
        statusStr = json['status'];
      } else if (json['status'] is Map) {
        statusStr = json['status']['name'] ?? json['status']['value'] ?? 'Draft';
      } else {
        statusStr = json['status'].toString();
      }
    }

    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems.map((e) => QuoteItem.fromJson(e as Map<String, dynamic>)).toList();

    double total = (json['totalCost'] is num)
        ? (json['totalCost'] as num).toDouble()
        : double.tryParse(json['totalCost']?.toString() ?? '0') ?? 0.0;

    if (total == 0 && itemsList.isNotEmpty) {
      total = itemsList.fold(0.0, (sum, i) => sum + i.calculatedTotal);
    }

    DateTime? created;
    if (json['createdAt'] != null) {
      created = DateTime.tryParse(json['createdAt'].toString());
    }
    DateTime? updated;
    if (json['updatedAt'] != null) {
      updated = DateTime.tryParse(json['updatedAt'].toString());
    }

    return Quote(
      id: json['id']?.toString() ?? '',
      projectRequestId: json['projectRequestId']?.toString() ?? '',
      designerId: json['designerId']?.toString() ?? '',
      scopeSummary: json['scopeSummary']?.toString() ?? 'Untitled Scope',
      notes: json['notes']?.toString(),
      isAiGenerated: json['isAiGenerated'] == true,
      status: statusStr,
      totalCost: total,
      items: itemsList,
      createdAt: created,
      updatedAt: updated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectRequestId': projectRequestId,
      'designerId': designerId,
      'scopeSummary': scopeSummary,
      if (notes != null) 'notes': notes,
      'isAiGenerated': isAiGenerated,
      'status': status,
      'totalCost': totalCost,
      'items': items.map((e) => e.toJson()).toList(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  Quote copyWith({
    String? id,
    String? projectRequestId,
    String? designerId,
    String? scopeSummary,
    String? notes,
    bool? isAiGenerated,
    String? status,
    double? totalCost,
    List<QuoteItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Quote(
      id: id ?? this.id,
      projectRequestId: projectRequestId ?? this.projectRequestId,
      designerId: designerId ?? this.designerId,
      scopeSummary: scopeSummary ?? this.scopeSummary,
      notes: notes ?? this.notes,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      status: status ?? this.status,
      totalCost: totalCost ?? this.totalCost,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AiDraftPayload {
  final String? projectRequestId;
  final String? designerId;
  final String roomType;
  final double roomSizeSqft;
  final double budgetMin;
  final double budgetMax;
  final String styleProfile;
  final double styleConfidence;
  final String? preferences;

  AiDraftPayload({
    this.projectRequestId,
    this.designerId,
    required this.roomType,
    required this.roomSizeSqft,
    required this.budgetMin,
    required this.budgetMax,
    required this.styleProfile,
    this.styleConfidence = 0.88,
    this.preferences,
  });

  Map<String, dynamic> toJson() {
    return {
      'projectRequestId': projectRequestId,
      'designerId': designerId,
      'roomType': roomType,
      'roomSizeSqft': roomSizeSqft,
      'budgetMin': budgetMin,
      'budgetMax': budgetMax,
      'styleProfile': styleProfile,
      'styleConfidence': styleConfidence,
      'preferences': preferences,
    };
  }
}

class AgentBudgetScopeResponse {
  final String scopeSummary;
  final List<QuoteItem> items;
  final String? notes;
  final double estimatedTotal;
  final bool withinBudget;
  final String source;

  AgentBudgetScopeResponse({
    required this.scopeSummary,
    required this.items,
    this.notes,
    required this.estimatedTotal,
    this.withinBudget = true,
    this.source = 'llm',
  });

  factory AgentBudgetScopeResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? [];
    final itemsList = rawItems.map((e) => QuoteItem.fromJson(e as Map<String, dynamic>)).toList();
    
    final scope = json['scopeSummary']?.toString() ??
        json['scope_summary']?.toString() ??
        'AI Estimated Scope';

    final total = (json['estimatedTotal'] is num)
        ? (json['estimatedTotal'] as num).toDouble()
        : (json['estimated_total'] is num)
            ? (json['estimated_total'] as num).toDouble()
            : itemsList.fold(0.0, (sum, i) => sum + i.calculatedTotal);

    final within = json['withinBudget'] == true || json['within_budget'] == true;

    return AgentBudgetScopeResponse(
      scopeSummary: scope,
      items: itemsList,
      notes: json['notes']?.toString(),
      estimatedTotal: total,
      withinBudget: within,
      source: json['source']?.toString() ?? 'llm',
    );
  }
}

class QuoteFormPayload {
  final String scopeSummary;
  final String? notes;
  final List<QuoteItem> items;
  final String? projectRequestId;
  final String? designerId;
  final bool isAiGenerated;

  QuoteFormPayload({
    required this.scopeSummary,
    this.notes,
    required this.items,
    this.projectRequestId,
    this.designerId,
    this.isAiGenerated = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'scopeSummary': scopeSummary,
      if (notes != null) 'notes': notes,
      'items': items.map((i) => i.toJson()).toList(),
      if (projectRequestId != null) 'projectRequestId': projectRequestId,
      if (designerId != null) 'designerId': designerId,
      'isAiGenerated': isAiGenerated,
    };
  }
}
