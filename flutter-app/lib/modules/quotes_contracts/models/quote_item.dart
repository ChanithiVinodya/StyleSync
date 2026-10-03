class QuoteItem {
  final String? id;
  final String description;
  final String category;
  final int quantity;
  final double unitCost;
  final double? totalCost;

  QuoteItem({
    this.id,
    required this.description,
    this.category = 'Other',
    this.quantity = 1,
    this.unitCost = 0.0,
    this.totalCost,
  });

  double get calculatedTotal => (totalCost != null && totalCost! > 0)
      ? totalCost!
      : (quantity * unitCost);

  factory QuoteItem.fromJson(Map<String, dynamic> json) {
    return QuoteItem(
      id: json['id']?.toString(),
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Other',
      quantity: (json['quantity'] is num) ? (json['quantity'] as num).toInt() : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      unitCost: (json['unitCost'] is num)
          ? (json['unitCost'] as num).toDouble()
          : (json['unit_cost'] is num)
              ? (json['unit_cost'] as num).toDouble()
              : double.tryParse(json['unitCost']?.toString() ?? json['unit_cost']?.toString() ?? '0') ?? 0.0,
      totalCost: (json['totalCost'] is num)
          ? (json['totalCost'] as num).toDouble()
          : (json['lineTotal'] is num)
              ? (json['lineTotal'] as num).toDouble()
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'description': description,
      'category': category,
      'quantity': quantity,
      'unitCost': unitCost,
      'totalCost': calculatedTotal,
    };
  }

  QuoteItem copyWith({
    String? id,
    String? description,
    String? category,
    int? quantity,
    double? unitCost,
    double? totalCost,
  }) {
    return QuoteItem(
      id: id ?? this.id,
      description: description ?? this.description,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      totalCost: totalCost ?? this.totalCost,
    );
  }
}
