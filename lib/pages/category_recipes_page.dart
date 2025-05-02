import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import './recipe_page.dart';
import './recipe_filter.dart';

class CategoryRecipesPage extends StatefulWidget {
  final String category;
  final RecipeFilter filter;

  const CategoryRecipesPage({
    Key? key,
    required this.category,
    required this.filter,
  }) : super(key: key);

  @override
  State<CategoryRecipesPage> createState() => _CategoryRecipesPageState();
}

class _CategoryRecipesPageState extends State<CategoryRecipesPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    final provider = Provider.of<RecipeProvider>(context, listen: false);
    await provider.fetchCategoryRecipes(
      widget.category,
      filters: widget.filter.toQueryParameters(),
      refresh: true,
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
    // TODO: Implement pagination
    setState(() => _isLoadingMore = false);
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
              height: 150,
              width: double.infinity,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe['title'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (recipe['readyInMinutes'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.timer, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe['readyInMinutes']} mins',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
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
        title: Text(
          'Recipes with ${widget.category}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<RecipeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingIngredient(widget.category) &&
              provider.getCategoryRecipes(widget.category).isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final recipes = provider.getCategoryRecipes(widget.category);

          return GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: recipes.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == recipes.length) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildRecipeCard(recipes[index]);
            },
          );
        },
      ),
    );
  }
} 