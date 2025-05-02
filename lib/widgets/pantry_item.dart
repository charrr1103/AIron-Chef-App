class PantryItem {
  final int id;
  final String name;
  final int quantity;
  final String category;
  final DateTime? expiryDate;
  final int updatedAt;
  bool isSelected; 

  PantryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.category,
    this.expiryDate,
    required this.updatedAt,
    this.isSelected = false, 
  });


  PantryItem copyWith({
    int? id,
    String? name,
    int? quantity,
    String? category,
    DateTime? expiryDate,
    int? updatedAt,
    bool? isSelected,
  }) {
    return PantryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      expiryDate: expiryDate ?? this.expiryDate,
      updatedAt: updatedAt ?? this.updatedAt,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  factory PantryItem.fromMap(Map<String, dynamic> m) => PantryItem(
    id: m['id'] as int,
    name: m['name'] as String,
    quantity: m['quantity'] as int,
    category: m['category'] as String,
    expiryDate:
        m['expiry_date'] != null
            ? DateTime.parse(m['expiry_date'] as String)
            : null,
    updatedAt: m['updated_at'] as int,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'category': category,
    'expiry_date': expiryDate?.toIso8601String(),
    'updated_at': updatedAt,
  };
}
