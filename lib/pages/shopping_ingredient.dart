class ShoppingIngredient {
  String name;
  bool bought;

  ShoppingIngredient({
    required this.name,
    this.bought = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'bought': bought,
  };

  static ShoppingIngredient fromJson(Map<String, dynamic> json) {
    return ShoppingIngredient(
      name: json['name'] as String,
      bought: json['bought'] as bool? ?? false,
    );
  }
}