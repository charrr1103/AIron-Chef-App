import 'package:airon_chef/widgets/pantry_item.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import './pantry_page.dart';
import './shopping_list_page.dart';
import '../services/recipe_service.dart';
import '../pages/shopping_list.dart';
import '../pages/shopping_ingredient.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:airon_chef/services/database_helper.dart';

class RecipeDetails {
  final int id;
  final String title;
  final String image;
  final int readyInMinutes;
  final List<String> ingredients;
  final List<String> instructions;
  final bool vegetarian;
  final bool vegan;
  final bool glutenFree;
  final bool dairyFree;

  RecipeDetails({
    required this.id,
    required this.title,
    required this.image,
    required this.readyInMinutes,
    required this.ingredients,
    required this.instructions,
    required this.vegetarian,
    required this.vegan,
    required this.glutenFree,
    required this.dairyFree,
  });

  factory RecipeDetails.fromJson(Map<String, dynamic> json) {
    List<String> parseIngredients(List<dynamic> extendedIngredients) {
      return extendedIngredients.map((ingredient) {
        final amount = ingredient['measures']['us']['amount'];
        final unit = ingredient['measures']['us']['unitShort'];
        final name = ingredient['name'];
        return '$amount ${unit.isNotEmpty ? unit + ' ' : ''}$name';
      }).toList();
    }

    List<String> parseInstructions(List<dynamic>? analyzedInstructions) {
      if (analyzedInstructions == null || analyzedInstructions.isEmpty) {
        return [];
      }
      return analyzedInstructions[0]['steps']
          .map<String>((step) => step['step'].toString())
          .toList();
    }

    return RecipeDetails(
      id: json['id'],
      title: json['title'],
      image: json['image'],
      readyInMinutes: json['readyInMinutes'],
      ingredients: parseIngredients(json['extendedIngredients']),
      instructions: parseInstructions(json['analyzedInstructions']),
      vegetarian: json['vegetarian'] ?? false,
      vegan: json['vegan'] ?? false,
      glutenFree: json['glutenFree'] ?? false,
      dairyFree: json['dairyFree'] ?? false,
    );
  }
}

class RecipePage extends StatefulWidget {
  final int recipeId;

  const RecipePage({super.key, required this.recipeId});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  bool isLoading = true;
  RecipeDetails? recipe;
  bool isSaved = false;
  final _recipeService = RecipeService();
  List<String> pantryNames = [];
  List<String> missingIngredients = [];
  int servingSize = 1;
  final FlutterTts flutterTts = FlutterTts();
  bool isReading = false;
  final GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadRecipeDetails();
    _checkIfSaved();
  }

   @override
  void dispose() {
    // flutterTts.stop();
    super.dispose();
  }

  //share recipe
  void _shareRecipe() {
    final text = '📖 ${recipe!.title}\n\n🛒 Ingredients:\n${recipe!.ingredients.join('\n')}\n\n📝 Steps:\n${recipe!.instructions.join('\n')}';
    Share.share(text);
  }

  //adjust the ppl to change the serving size 
  void _increaseServing() => setState(() => servingSize++);

  void _decreaseServing() => setState(() => servingSize > 1 ? servingSize-- : servingSize);

  double _scaleIngredient(String ingredient) {
    final parts = ingredient.split(' ');
    final amount = double.tryParse(parts[0]) ?? 1.0;
    return amount * servingSize / 2; // Assume base is 2 servings
  }

  //read recipe
  Future<void> _readRecipe() async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(1);
    await flutterTts.speak('${recipe!.title}. Ingredients: ${recipe!.ingredients.join(', ')}. Steps: ${recipe!.instructions.join(', ')}.');
  }

  String singularize(String word) {
    if (word.endsWith('es')) return word.substring(0, word.length - 2);
    if (word.endsWith('s')) return word.substring(0, word.length - 1);
    return word;
  }

  //compare the ingredient in recipe page with the pantry's available ingredients
  Future<void> _compareWithPantry() async {
    final pantryItems = await DatabaseHelper.instance.getAllPantryItems();
    final pantryNames = pantryItems
        .map((item) => item.name.toLowerCase().trim())
        .toList();

    missingIngredients.clear();

    for (final fullIngredient in recipe!.ingredients) {
      final cleaned = fullIngredient.toLowerCase().trim();

      final parts = cleaned.split(' ');
      String ingredientName;
      if (parts.length >= 3) {
        ingredientName = parts.sublist(2).join(' '); 
      } else if (parts.length >= 2) {
        ingredientName = parts.sublist(1).join(' ');
      } else {
        ingredientName = cleaned;
      }
      final pantryNames = pantryItems
          .map((item) => singularize(item.name.toLowerCase().trim()))
          .toList();

      final singularIngredient = singularize(ingredientName.toLowerCase());

      // Do a reverse contains check both ways
      final isInPantry = pantryNames.any((pantryItem) {
        return pantryItem.contains(ingredientName) ||
              ingredientName.contains(pantryItem);
      });

      if (!isInPantry) {
        missingIngredients.add(fullIngredient);
      }
    }
  }

  //Check if the recipe is saved
  Future<void> _checkIfSaved() async {
    final saved = await _recipeService.isRecipeSaved(widget.recipeId);
    setState(() => isSaved = saved);
  }

  Future<void> _toggleSave() async {
    if (recipe == null) return;

    setState(() => isSaved = !isSaved);

    if (isSaved) {
      await _recipeService.saveRecipe(
        SavedRecipe(
          id: recipe!.id,
          title: recipe!.title,
          image: recipe!.image,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe saved!')),
      );
    } else {
      await _recipeService.unsaveRecipe(widget.recipeId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe removed from saved')),
      );
    }
  }

  //download recipe as image
  Future<void> _downloadAsImage() async {
    try {
      final boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception("Unable to find boundary.");
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception("Failed to get byte data from image.");
      }

      final pngBytes = byteData.buffer.asUint8List();

      final directory = Directory('/storage/emulated/0/Download');
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      final safeTitle = recipe!.title.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
      final filePath = '${directory.path}/${safeTitle}_Recipe.png';

      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Recipe saved to: $filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to save recipe: $e')),
      );
    }
  }

  //load recipe from spoonacular api
  Future<void> _loadRecipeDetails() async {
    setState(() => isLoading = true);

    try {
      const apiKey = '6411afbeed924a12a6eacae6ed8545ac';
      // const apiKey = '70671e6206e9472b8c8b4d1397ae59c0';
      final response = await http.get(
        Uri.parse(
          'https://api.spoonacular.com/recipes/${widget.recipeId}/information'
          '?apiKey=$apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        recipe = RecipeDetails.fromJson(data);
        await _compareWithPantry(); 

        setState(() {

          isLoading = false;
        });
      } else {
        throw Exception('Failed to load recipe details');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  //generate shopping list from recipe page
  Future<void> _generateShoppingList() async {
    if (recipe == null) return;

    final allLists = await DatabaseHelper.instance.getAllShoppingLists();
    final listTitle = '${recipe!.title} Ingredients';

    final alreadyExists = allLists.any((list) => list.title == listTitle);

    // If list exists
    if (alreadyExists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('List already exists')),
        );
      }
      return;
    }


  if (missingIngredients.isEmpty) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All ingredients already in pantry')),
      );
    }
    return;
  }

    // If not exists, create a new shopping list
    final newList = ShoppingList(
    title: listTitle,
    ingredients: missingIngredients.map((name) => ShoppingIngredient(name: name)).toList(),
    );

    await DatabaseHelper.instance.insertShoppingList(newList);
    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added missing ingredients to shopping list')),
      );
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ShoppingListPage()),
      );
    }
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
          'Recipe Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
          actions: [
            IconButton(
              color: Colors.white,
              onPressed: () async {
                if (isReading) {
                  await flutterTts.stop();
                  setState(() {
                    isReading = false;
                  });
                } else {
                  await _readRecipe(); 
                  setState(() {
                    isReading = true;
                  });
                }
              },
              icon: Icon(
                isReading ? Icons.stop_circle : Icons.volume_up,
              ),
              tooltip: isReading ? 'Stop Reading' : 'Read Recipe',
            ),
             IconButton(
              icon: const Icon(Icons.download),
              color: Colors.white,
              onPressed: _downloadAsImage,
              tooltip: 'Download Recipe',
            ),
          ],
        ),
        body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : recipe == null
              ? const Center(child: Text('Failed to load recipe'))
              : SingleChildScrollView(
                child: RepaintBoundary(
                  key: _globalKey,
                  child: Container(
                  color: const Color(0xFFFFFBF0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Image.network(
                            recipe!.image,
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    // ignore: deprecated_member_use
                                    Colors.black.withOpacity(0.8),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recipe!.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.timer,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${recipe!.readyInMinutes} minutes',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                                  ),
                                  onPressed: _toggleSave,
                                ),
                                IconButton(
                                  onPressed: _shareRecipe,
                                  icon: const Icon(Icons.share),
                                  tooltip: 'Share Recipe',
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Ingredients:',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: _decreaseServing,
                                    tooltip: 'Decrease Serving',
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.people, size: 24),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$servingSize',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: _increaseServing,
                                        tooltip: 'Increase Serving',
                                      ),
                                    ],
                                  ),
                                ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: recipe!.ingredients.length,
                              itemBuilder: (context, index) {
                                final ingredient = recipe!.ingredients[index];
                                final parts = ingredient.split(' ');

                                if (parts.length < 2) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_box_outline_blank, color: Colors.grey, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            ingredient,
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                final scaledQty = _scaleIngredient(ingredient);
                                final rest = parts.sublist(1).join(' ');

                                final isInPantry = pantryNames.any((name) => rest.toLowerCase().contains(name));

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isInPantry ? Icons.check_box : Icons.check_box_outline_blank,
                                        color: isInPantry ? Colors.green : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          ' ${scaledQty.toStringAsFixed(2)} $rest',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: isInPantry ? Colors.black : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                            ElevatedButton(
                              onPressed: _generateShoppingList,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6B4EFF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text('Generate Shopping List'),
                            ),
                          ],
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch, 
                          children: [
                            if (missingIngredients.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Missing ${missingIngredients.length} ingredient(s)',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.red,
                                    fontStyle: FontStyle.normal,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Steps:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recipe!.instructions.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6B4EFF),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      recipe!.instructions[index],
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
