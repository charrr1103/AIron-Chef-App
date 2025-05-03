import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import './recipe_page.dart';

class IngredientRecipesPage extends StatefulWidget {
  final String ingredient;
  final Map<String, dynamic> filters;

  const IngredientRecipesPage({
    Key? key,
    required this.ingredient,
    this.filters = const {},
  }) : super(key: key);

  @override
  State<IngredientRecipesPage> createState() => _IngredientRecipesPageState();
}

class _IngredientRecipesPageState extends State<IngredientRecipesPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadInitialRecipes();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialRecipes() {
    final provider = Provider.of<RecipeProvider>(context, listen: false);
    provider.fetchRecipesForIngredient(
      widget.ingredient,
      filters: widget.filters,
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      _loadMoreRecipes();
    }
  }

  Future<void> _loadMoreRecipes() async {
    setState(() => _isLoadingMore = true);
    setState(() => _isLoadingMore = false);
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
        title: Text(
          'Recipes with ${widget.ingredient}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<RecipeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingIngredient(widget.ingredient) &&
              provider.getRecipesForIngredient(widget.ingredient).isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final error = provider.getError(widget.ingredient);
          if (error != null) {
            return Center(child: Text(error));
          }

          final recipes = provider.getRecipesForIngredient(widget.ingredient);

          return GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: recipes.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == recipes.length) {
                return const Center(child: CircularProgressIndicator());
              }

              final recipe = recipes[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipePage(recipeId: recipe['id']),
                    ),
                  );
                },
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(recipe['image'], fit: BoxFit.cover),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Text(
                            recipe['title'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
