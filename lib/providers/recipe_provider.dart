import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../pages/recipe_filter.dart';

class RecipeProvider extends ChangeNotifier {
  final Map<String, List<dynamic>> _recipesByIngredient = {};
  final Map<String, bool> _loadingStates = {};
  final Map<String, String> _errors = {};
  final Map<String, DateTime> _lastFetchTime = {};
  final Map<String, List<dynamic>> _categoryRecipes = {};
  static const Duration _cacheDuration = Duration(minutes: 30);
  
  // Multiple API keys for rotation
  final List<String> _apiKeys = [
    '3da7e45ba414478f9e8f6c3179f4b8b4',
    '70671e6206e9472b8c8b4d1397ae59c0',
    '55ed249fff1f4d7fa31c16403d030611'
  ];

  // Search state
  String _searchQuery = '';
  bool _isSearching = false;

  String get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;

  void setSearchState(String query, bool isSearching) {
    _searchQuery = query;
    _isSearching = isSearching;
    notifyListeners();
  }

  List<dynamic> getRecipesForIngredient(String ingredient) {
    final recipes = _recipesByIngredient[ingredient] ?? [];
    return _filterRecipes(recipes);
  }
  
  List<dynamic> getCategoryRecipes(String category) {
    final recipes = _categoryRecipes[category] ?? [];
    return _filterRecipes(recipes);
  }

  List<dynamic> _filterRecipes(List<dynamic> recipes) {
    if (recipes.isEmpty) return recipes;

    return recipes.where((recipe) {
      // Filter by preparation time
      if (_currentFilter?.preparationTime != null) {
        final maxTime = int.tryParse(_currentFilter!.preparationTime!.replaceAll(RegExp(r'[^0-9]'), ''));
        if (maxTime != null && recipe['readyInMinutes'] > maxTime) {
          return false;
        }
      }

      // Filter by cuisine
      if (_currentFilter?.cuisine != null) {
        final recipeCuisines = (recipe['cuisines'] as List<dynamic>?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
        if (!recipeCuisines.contains(_currentFilter!.cuisine!.toLowerCase())) {
          return false;
        }
      }

      // Filter by meal type
      if (_currentFilter?.mealType != null) {
        final recipeTypes = (recipe['dishTypes'] as List<dynamic>?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
        if (!recipeTypes.contains(_currentFilter!.mealType!.toLowerCase())) {
          return false;
        }
      }

      // Filter by dietary restrictions
      if (_currentFilter?.dietaryRestrictions != null) {
        final diets = (recipe['diets'] as List<dynamic>?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
        final filterDiet = _currentFilter!.dietaryRestrictions!.toLowerCase();
        if (!diets.contains(filterDiet)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  RecipeFilter? _currentFilter;

  void setFilter(RecipeFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  bool isLoadingIngredient(String ingredient) => 
      _loadingStates[ingredient] ?? false;
  
  String? getError(String ingredient) => _errors[ingredient];

  bool _isCacheValid(String key) {
    final lastFetch = _lastFetchTime[key];
    if (lastFetch == null) return false;
    return DateTime.now().difference(lastFetch) < _cacheDuration;
  }

  Future<Map<String, dynamic>?> _fetchWithApiKey(
    String apiKey,
    Map<String, dynamic> queryParams,
  ) async {
    try {
      final uri = Uri.https(
        'api.spoonacular.com',
        '/recipes/complexSearch',
        queryParams,
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 402) {
        return null; // Quota exceeded
      } else {
        throw Exception('Failed to load recipes');
      }
    } catch (e) {
      throw Exception('Failed to load recipes: $e');
    }
  }

  Future<void> fetchCategoryRecipes(
    String category, {
    Map<String, dynamic> filters = const {},
    bool refresh = false,
  }) async {
    // Return cached data if it's valid and not refreshing
    if (!refresh && _categoryRecipes.containsKey(category) && _isCacheValid(category)) {
      return;
    }

    _loadingStates[category] = true;
    _errors.remove(category);
    notifyListeners();

    try {
      final queryParams = {
        'query': category,
        'number': '3',
        ...filters,
        'addRecipeInformation': 'true',
      };

      bool allKeysExceeded = true;
      for (final apiKey in _apiKeys) {
        try {
          final data = await _fetchWithApiKey(apiKey, {...queryParams, 'apiKey': apiKey});
          
          if (data != null) {
            _categoryRecipes[category] = data['results'] as List;
            _lastFetchTime[category] = DateTime.now();
            allKeysExceeded = false;
            break;
          }
        } catch (e) {
          continue;
        }
      }

      if (allKeysExceeded) {
        _errors[category] = 'API quota reached. Please try again later.';
      }
    } catch (e) {
      _errors[category] = e.toString();
    } finally {
      _loadingStates[category] = false;
      notifyListeners();
    }
  }

  Future<void> fetchRecipesForIngredient(
    String ingredient, {
    Map<String, dynamic> filters = const {},
    bool refresh = false,
  }) async {
    // Return cached data if it's valid and not refreshing
    if (!refresh && _recipesByIngredient.containsKey(ingredient) && _isCacheValid(ingredient)) {
      return;
    }

    _loadingStates[ingredient] = true;
    _errors.remove(ingredient);
    notifyListeners();

    try {
      final queryParams = {
        'query': ingredient,
        'number': '10',
        ...filters,
        'addRecipeInformation': 'true',
      };

      bool allKeysExceeded = true;
      for (final apiKey in _apiKeys) {
        try {
          final data = await _fetchWithApiKey(apiKey, {...queryParams, 'apiKey': apiKey});
          
          if (data != null) {
            _recipesByIngredient[ingredient] = data['results'] as List;
            _lastFetchTime[ingredient] = DateTime.now();
            allKeysExceeded = false;
            break;
          }
        } catch (e) {
          continue;
        }
      }

      if (allKeysExceeded) {
        _errors[ingredient] = 'API quota reached. Please try again later.';
      }
    } catch (e) {
      _errors[ingredient] = e.toString();
    } finally {
      _loadingStates[ingredient] = false;
      notifyListeners();
    }
  }

  void clearRecipes() {
    _recipesByIngredient.clear();
    _categoryRecipes.clear();
    _loadingStates.clear();
    _errors.clear();
    _lastFetchTime.clear();
    notifyListeners();
  }

  void updateSearchResults(String query, List<dynamic> results) {
    _recipesByIngredient[query] = results;
    _lastFetchTime[query] = DateTime.now();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
} 