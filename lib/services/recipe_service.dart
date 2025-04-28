import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../pages/all_recipe_page.dart';
import '../pages/recipe_page.dart';

class SavedRecipe {
  final int id;
  final String title;
  final String image;

  SavedRecipe({required this.id, required this.title, required this.image});

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'image': image};

  factory SavedRecipe.fromJson(Map<String, dynamic> json) =>
      SavedRecipe(id: json['id'], title: json['title'], image: json['image']);
}

class RecipeService {
  static const String _savedRecipesKey = 'saved_recipes';

  static const _apiKey = '22241ed41e80458382a59b010df2afae';
  static const _apiUrl = 'https://api.spoonacular.com/recipes/';

  // Singleton instance
  static final RecipeService _instance = RecipeService._internal();
  factory RecipeService() => _instance;
  RecipeService._internal();

  ///Search by ingredients
  Future<List<Recipe>> searchRecipes(List<String> ingredients) async {
    final ing = ingredients.map(Uri.encodeComponent).join(',');
    final url = Uri.parse(
      '$_apiUrl/findByIngredients'
      '?ingredients=$ing&number=10&apiKey=$_apiKey',
    );
    final resp = await http.get(url);
    if (resp.statusCode != 200) {
      throw Exception('Failed to load recipes');
    }
    final List data = json.decode(resp.body) as List;
    return data.map((j) => Recipe.fromJson(j)).toList();
  }

  /// Fetch full details for one recipe
  Future<RecipeDetails> fetchRecipeDetails(int id) async {
    final url = Uri.parse('$_apiUrl/$id/information?apiKey=$_apiKey');
    final resp = await http.get(url);
    if (resp.statusCode != 200) {
      throw Exception('Failed to load recipe details');
    }
    final data = json.decode(resp.body) as Map<String, dynamic>;
    return RecipeDetails.fromJson(data);
  }

  /// Load saved recipes from SharedPreferences
  Future<List<SavedRecipe>> getSavedRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedRecipesJson = prefs.getString(_savedRecipesKey);

    if (savedRecipesJson == null) return [];

    final List<dynamic> decodedList = json.decode(savedRecipesJson);
    return decodedList.map((item) => SavedRecipe.fromJson(item)).toList();
  }

  /// Check if a recipe is already saved
  Future<bool> isRecipeSaved(int recipeId) async {
    final savedRecipes = await getSavedRecipes();
    return savedRecipes.any((recipe) => recipe.id == recipeId);
  }

  /// Save a recipe
  Future<void> saveRecipe(SavedRecipe recipe) async {
    final savedRecipes = await getSavedRecipes();
    if (!savedRecipes.any((r) => r.id == recipe.id)) {
      savedRecipes.add(recipe);
      await _saveToPrefs(savedRecipes);
    }
  }

  /// Unsave a recipe
  Future<void> unsaveRecipe(int recipeId) async {
    final savedRecipes = await getSavedRecipes();
    savedRecipes.removeWhere((recipe) => recipe.id == recipeId);
    await _saveToPrefs(savedRecipes);
  }

  /// Save recipes to SharedPreferences
  Future<void> _saveToPrefs(List<SavedRecipe> recipes) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = json.encode(
      recipes.map((recipe) => recipe.toJson()).toList(),
    );
    await prefs.setString(_savedRecipesKey, encodedList);
  }
}
