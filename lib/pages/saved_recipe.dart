import 'package:flutter/material.dart';
import './recipe_page.dart';
import './pantry_page.dart';
import './shopping_list_page.dart';
import '../services/recipe_service.dart';

class SavedRecipePage extends StatefulWidget {
  const SavedRecipePage({super.key});

  @override
  State<SavedRecipePage> createState() => _SavedRecipePageState();
}

class _SavedRecipePageState extends State<SavedRecipePage> {
  final _recipeService = RecipeService();
  List<SavedRecipe> _savedRecipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedRecipes();
  }

  Future<void> _loadSavedRecipes() async {
    setState(() => _isLoading = true);
    final recipes = await _recipeService.getSavedRecipes();
    setState(() {
      _savedRecipes = recipes;
      _isLoading = false;
    });
  }

  Future<void> _unsaveRecipe(SavedRecipe recipe) async {
    await _recipeService.unsaveRecipe(recipe.id);
    await _loadSavedRecipes();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recipe removed from saved')),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Saved Recipes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedRecipes.isEmpty
              ? const Center(
                  child: Text(
                    'No saved recipes yet',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _savedRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = _savedRecipes[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecipePage(recipeId: recipe.id),
                          ),
                        ).then((_) => _loadSavedRecipes());
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              Card(
                                clipBehavior: Clip.antiAlias,
                                margin: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Image.network(
                                  recipe.image,
                                  fit: BoxFit.cover,
                                  height: 150,
                                  width: double.infinity,
                                ),
                              ),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.bookmark,
                                      color: Color(0xFF6B4EFF),
                                    ),
                                    onPressed: () => _unsaveRecipe(recipe),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              child: Text(
                                recipe.title,
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
                  },
                ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF19006d),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 2,
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
