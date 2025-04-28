import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './pantry_page.dart';
import './shopping_list_page.dart';
import './recipe_filter.dart';
import './recipe_page.dart';
import './saved_recipe.dart';
import './profile_page.dart';
import '../providers/recipe_provider.dart';
import './category_recipes_page.dart';
import 'package:airon_chef/services/database_helper.dart';
import '../widgets/pantry_item.dart';

class Recipe {
  final String title;
  final String imageUrl;
  final int id;
  final String? sourceUrl;

  Recipe({
    required this.title,
    required this.imageUrl,
    required this.id,
    this.sourceUrl,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      title: json['title'],
      imageUrl: json['image'],
      id: json['id'],
      sourceUrl: json['sourceUrl'],
    );
  }
}

class AllRecipePage extends StatefulWidget {
  final List<PantryItem>? selectedIngredients;

  const AllRecipePage({super.key, this.selectedIngredients});
  @override
  State<AllRecipePage> createState() => _AllRecipePageState();
}

class _AllRecipePageState extends State<AllRecipePage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> categories = [];
  RecipeFilter _filter = RecipeFilter();
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadPantryItems();
    // Restore search state from provider
    final provider = Provider.of<RecipeProvider>(context, listen: false);
    _searchController.text = provider.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchQuery = '';
        _isSearching = false;
      });
      await _loadRecipes();
      return;
    }

    final provider = Provider.of<RecipeProvider>(context, listen: false);
    provider.setSearchState(query, true);
    _searchController.text = query;

    await provider.fetchRecipesForIngredient(
      query,
      filters: _filter.toQueryParameters(),
      refresh: true,
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadPantryItems() async {
    setState(() => _isLoading = true);
    final pantryItems = await DatabaseHelper.instance.getAllPantryItems();
    setState(() {
      categories = pantryItems.map((item) => item.name).toList();
      _isLoading = false;
    });
    await _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    final provider = Provider.of<RecipeProvider>(context, listen: false);
    
    if (categories.isEmpty) {
      // Load all recipes if pantry is empty
      await provider.fetchRecipesForIngredient(
        'all',
        filters: _filter.toQueryParameters(),
        refresh: true,
      );
    } else {
      // Load recipes for each ingredient in pantry
      for (var category in categories) {
        await provider.fetchCategoryRecipes(
          category,
          filters: _filter.toQueryParameters(),
          refresh: true,
        );
      }
    }
    // Save the state after loading recipes
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showFilterPage() async {
    final result = await Navigator.push<RecipeFilter>(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeFilterPage(initialFilter: _filter),
      ),
    );

    if (result != null) {
      setState(() {
        _filter = result;
      });
      // Set the filter in the provider
      final provider = Provider.of<RecipeProvider>(context, listen: false);
      provider.setFilter(_filter);
      
      // Force refresh with new filters
      if (provider.isSearching) {
        await provider.fetchRecipesForIngredient(
          provider.searchQuery,
          filters: _filter.toQueryParameters(),
          refresh: true,
        );
      } else {
        await _loadRecipes();
      }
    }
  }

  void _onSeeAllPressed(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                CategoryRecipesPage(category: category, filter: _filter),
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipePage(recipeId: recipe['id']),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Image.network(
              recipe['image'],
              fit: BoxFit.cover,
              height: 120,
              width: double.infinity,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                recipe['title'],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String category, List<dynamic> recipes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'If you have $category',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _onSeeAllPressed(category),
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180, // Increased height to accommodate title
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              return Container(
                width: 160, // Slightly increased width
                margin: const EdgeInsets.only(right: 16),
                child: _buildRecipeCard(recipes[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF004AAD), Color(0xFFCB6CE6)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 35),
            const SizedBox(width: 30),
            const Text(
              'AIron Chef',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: Consumer<RecipeProvider>(
        builder: (context, provider, child) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SavedRecipePage(),
                      ),
                    );
                  },
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6B4EFF), Color(0xFFCB6CE6)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: 0,
                          bottom: 0,
                          top: 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.asset(
                              'assets/food-banner.jpg',
                              fit: BoxFit.cover,
                              width: 120,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'View Saved Recipes',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white.withOpacity(0.8),
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search recipes...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: provider.isSearching
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    provider.setSearchState('', false);
                                    _loadRecipes();
                                  },
                                )
                              : null,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () => _performSearch(_searchController.text),
                          ),
                        ),
                        onSubmitted: _performSearch,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _showFilterPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4EFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Icon(Icons.tune, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: provider.isSearching
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: GridView.builder(
                          itemCount: provider.getRecipesForIngredient(provider.searchQuery).length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 3 / 4,
                          ),
                          itemBuilder: (context, index) {
                            final recipe = provider.getRecipesForIngredient(provider.searchQuery)[index];
                            return _buildRecipeCard(recipe);
                          },
                        ),
                      )
                    : categories.isNotEmpty
                        ? ListView.builder(
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              return _buildCategorySection(
                                category,
                                provider.getCategoryRecipes(category),
                              );
                            },
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: GridView.builder(
                              itemCount: provider.getRecipesForIngredient('all').length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 3 / 4,
                              ),
                              itemBuilder: (context, index) {
                                final recipe = provider.getRecipesForIngredient('all')[index];
                                return _buildRecipeCard(recipe);
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF19006d),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 2, // Recipes tab
        onTap: (index) {
          if (index != 2) {
            Navigator.pop(context);
            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PantryPage()),
              );
            } else if (index == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShoppingListPage(),
                ),
              );
            }
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Pantry'),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_basket),
            label: 'List',
          ),
        ],
      ),
    );
  }
}
