import 'shopping_ingredient.dart';
import 'dart:convert';

class ShoppingList {
  final int? id; // <- make it optional
  final String title;
  final List<ShoppingIngredient> ingredients;

  ShoppingList({
    this.id, // <- add this
    required this.title,
    required this.ingredients,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
      };

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'] as int?, // <- read id if exists
      title: json['title'],
      ingredients: (jsonDecode(json['ingredients']) as List)
          .map((e) => ShoppingIngredient.fromJson(e))
          .toList(),
    );
  }
}
