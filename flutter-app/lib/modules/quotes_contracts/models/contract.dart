import 'quote.dart';

class Contract {
  final String id;
  final String? quoteId;
  final String? projectRequestId;
  final String? designerId;
  final String? clientId;
  final String status;
  final double totalAmount;
  final String? terms;
  final String? termsSummary;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? signedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Quote? quote;
  final String? designerDisplayName;
  final String? designerEmail;
  final String? clientDisplayName;
  final String? clientEmail;
  final String? projectReferenceCode;
  final String? description;
  final List<DesignerRecommendation> recommendedDesigners;

  Contract({
    required this.id,
    this.quoteId,
    this.projectRequestId,
    this.designerId,
    this.clientId,
    this.status = 'Draft',
    required this.totalAmount,
    this.terms,
    this.termsSummary,
    this.startDate,
    this.endDate,
    this.signedAt,
    this.createdAt,
    this.updatedAt,
    this.quote,
    this.designerDisplayName,
    this.designerEmail,
    this.clientDisplayName,
    this.clientEmail,
    this.projectReferenceCode,
    this.description,
    this.recommendedDesigners = const [],
  });

  factory Contract.fromJson(Map<String, dynamic> json) {
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

    double total = (json['totalAmount'] is num)
        ? (json['totalAmount'] as num).toDouble()
        : double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0;

    DateTime? signed;
    if (json['signedAt'] != null) {
      signed = DateTime.tryParse(json['signedAt'].toString());
    }
    DateTime? created;
    if (json['createdAt'] != null) {
      created = DateTime.tryParse(json['createdAt'].toString());
    }
    DateTime? updated;
    if (json['updatedAt'] != null) {
      updated = DateTime.tryParse(json['updatedAt'].toString());
    }
    DateTime? start;
    if (json['startDate'] != null) {
      start = DateTime.tryParse(json['startDate'].toString());
    }
    DateTime? end;
    if (json['endDate'] != null) {
      end = DateTime.tryParse(json['endDate'].toString());
    }

    Quote? linkedQuote;
    if (json['quote'] != null && json['quote'] is Map) {
      try {
        linkedQuote = Quote.fromJson(Map<String, dynamic>.from(json['quote'] as Map));
      } catch (e) {
        // ignore quote parse error
      }
    }

    final rawRecs = json['recommendedDesigners'] as List<dynamic>? ?? [];
    final recsList = <DesignerRecommendation>[];
    for (final r in rawRecs) {
      if (r is Map) {
        try {
          recsList.add(DesignerRecommendation.fromJson(Map<String, dynamic>.from(r)));
        } catch (_) {}
      }
    }

    return Contract(
      id: json['id']?.toString() ?? '',
      quoteId: json['quoteId']?.toString(),
      projectRequestId: json['projectRequestId']?.toString(),
      designerId: json['designerId']?.toString(),
      clientId: json['clientId']?.toString(),
      status: statusStr,
      totalAmount: total,
      terms: json['terms']?.toString(),
      termsSummary: json['termsSummary']?.toString() ?? linkedQuote?.scopeSummary ?? 'Interior Design Agreement',
      startDate: start,
      endDate: end,
      signedAt: signed,
      createdAt: created,
      updatedAt: updated,
      quote: linkedQuote,
      designerDisplayName: json['designerDisplayName']?.toString() ?? linkedQuote?.designerDisplayName,
      designerEmail: json['designerEmail']?.toString() ?? linkedQuote?.designerEmail,
      clientDisplayName: json['clientDisplayName']?.toString() ?? linkedQuote?.clientDisplayName,
      clientEmail: json['clientEmail']?.toString() ?? linkedQuote?.clientEmail,
      projectReferenceCode: json['projectReferenceCode']?.toString() ?? linkedQuote?.projectReferenceCode,
      description: json['description']?.toString() ?? linkedQuote?.description,
      recommendedDesigners: recsList.isNotEmpty ? recsList : (linkedQuote?.recommendedDesigners ?? const []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (quoteId != null) 'quoteId': quoteId,
      if (projectRequestId != null) 'projectRequestId': projectRequestId,
      if (designerId != null) 'designerId': designerId,
      if (clientId != null) 'clientId': clientId,
      'status': status,
      'totalAmount': totalAmount,
      if (terms != null) 'terms': terms,
      if (termsSummary != null) 'termsSummary': termsSummary,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      if (signedAt != null) 'signedAt': signedAt!.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (quote != null) 'quote': quote!.toJson(),
      if (designerDisplayName != null) 'designerDisplayName': designerDisplayName,
      if (designerEmail != null) 'designerEmail': designerEmail,
      if (clientDisplayName != null) 'clientDisplayName': clientDisplayName,
      if (clientEmail != null) 'clientEmail': clientEmail,
      if (projectReferenceCode != null) 'projectReferenceCode': projectReferenceCode,
      if (description != null) 'description': description,
      if (recommendedDesigners.isNotEmpty)
        'recommendedDesigners': recommendedDesigners.map((e) => e.toJson()).toList(),
    };
  }

  Contract copyWith({
    String? id,
    String? quoteId,
    String? projectRequestId,
    String? designerId,
    String? clientId,
    String? status,
    double? totalAmount,
    String? terms,
    String? termsSummary,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? signedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Quote? quote,
    String? designerDisplayName,
    String? designerEmail,
    String? clientDisplayName,
    String? clientEmail,
    String? projectReferenceCode,
    String? description,
    List<DesignerRecommendation>? recommendedDesigners,
  }) {
    return Contract(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      projectRequestId: projectRequestId ?? this.projectRequestId,
      designerId: designerId ?? this.designerId,
      clientId: clientId ?? this.clientId,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      terms: terms ?? this.terms,
      termsSummary: termsSummary ?? this.termsSummary,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      signedAt: signedAt ?? this.signedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      quote: quote ?? this.quote,
      designerDisplayName: designerDisplayName ?? this.designerDisplayName,
      designerEmail: designerEmail ?? this.designerEmail,
      clientDisplayName: clientDisplayName ?? this.clientDisplayName,
      clientEmail: clientEmail ?? this.clientEmail,
      projectReferenceCode: projectReferenceCode ?? this.projectReferenceCode,
      description: description ?? this.description,
      recommendedDesigners: recommendedDesigners ?? this.recommendedDesigners,
    );
  }
}
