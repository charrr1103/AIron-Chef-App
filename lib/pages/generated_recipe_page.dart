import 'package:airon_chef/services/recipe_service.dart';
import 'package:flutter/material.dart';
import '../pages/all_recipe_page.dart';
import '../services/recipe_service.dart';
import '../pages/recipe_page.dart';

class GeneratedRecipePage extends StatelessWidget {
  final List<Recipe> recipes;
  final String ingredientQuery;

  const GeneratedRecipePage({
    Key? key,
    required this.recipes,
    required this.ingredientQuery,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF004AAD), Color(0xFFCB6CE6)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 8),
                  const Text(
                    'AIron Chef',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recipes that contain $ingredientQuery',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipePage(recipeId: recipe.id),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              recipe.imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, _, __) => const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          recipe.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
