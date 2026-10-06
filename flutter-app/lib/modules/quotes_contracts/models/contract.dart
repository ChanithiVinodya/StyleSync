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
    );
  }
}
