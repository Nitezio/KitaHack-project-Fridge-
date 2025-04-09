class FridgeItem {
  final String name;
  final DateTime expiryDate;
  final double? quantity;
  final String? unit;
  final String? category;

  FridgeItem({
    required this.name,
    required this.expiryDate,
    this.quantity,
    this.unit,
    this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'expiryDate': expiryDate.toIso8601String(),
      'quantity': quantity,
      'unit': unit,
      'category': category,
    };
  }

  factory FridgeItem.fromJson(Map<String, dynamic> json) {
    return FridgeItem(
      name: json['name'],
      expiryDate: DateTime.parse(json['expiryDate']),
      quantity: json['quantity'] != null ? json['quantity'].toDouble() : null,
      unit: json['unit'],
      category: json['category'],
    );
  }
}