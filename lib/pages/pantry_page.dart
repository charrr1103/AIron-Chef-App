import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:airon_chef/widgets/pantry_item.dart';
import 'package:airon_chef/services/database_helper.dart';
import './all_recipe_page.dart';
import './shopping_list_page.dart';
import 'profile_page.dart';
import '../services/recipe_service.dart';
import './generated_recipe_page.dart';
import '../services/ingredient_images_service.dart';

class PantryPage extends StatefulWidget {
  const PantryPage({super.key});

  @override
  State<PantryPage> createState() => _PantryPageState();
}

class _PantryPageState extends State<PantryPage> {
  final _recipeService = RecipeService();
  bool _loadingRecipes = false;
  List<PantryItem> pantryItems = [];
  final imageService = IngredientImageService();

  @override
  void initState() {
    super.initState();
    _loadPantryItems();
  }

  // When image fail to load
  Widget _fallbackAsset(PantryItem item) {
    return Image.asset(
      'assets/ingredients/${item.name.toLowerCase().replaceAll(" ", "_")}.jpg',
      width: 50,
      height: 50,
      fit: BoxFit.cover,
      errorBuilder:
          (_, __, ___) => const Icon(
            Icons.image_not_supported,
          ), // Show image not support if the image not in assets
    );
  }

  Future<void> _loadPantryItems() async {
    pantryItems = await DatabaseHelper.instance.getAllPantryItems();
    setState(() {});
  }

  //edit ingredient dialog
  Future<void> _editIngredient(int index) async {
    final item = pantryItems[index];
    final nameController = TextEditingController(text: item.name);
    final quantityController = TextEditingController(
      text: item.quantity.toString(),
    );
    final categoryController = TextEditingController(text: item.category);
    DateTime? selectedDate = item.expiryDate;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Edit Ingredient',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Expiry Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          selectedDate != null
                              ? selectedDate!.toLocal().toString().split(' ')[0]
                              : 'Pick a date',
                          style: TextStyle(
                            color:
                                selectedDate != null
                                    ? Colors.black
                                    : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final newName = nameController.text.trim();
                            final newQty =
                                //convert string to integer, return 1 if invalid input
                                int.tryParse(quantityController.text.trim()) ??
                                1;
                            final newCategory = categoryController.text.trim();

                            if (newName.isNotEmpty) {
                              await DatabaseHelper.instance.deleteIngredient(
                                item.name,
                              );
                              final updatedItem = item.copyWith(
                                name: newName,
                                quantity: newQty,
                                category: newCategory,
                                expiryDate: selectedDate,
                                updatedAt:
                                    DateTime.now().millisecondsSinceEpoch,
                              );
                              await DatabaseHelper.instance.insertPantryItem(
                                updatedItem,
                              );
                              await _loadPantryItems();
                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ingredient updated'),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF004AAD),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  //remove ingredient dialog
  Future<void> _deleteIngredient(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Delete Ingredient',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Are you sure you want to delete this ingredient?',
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteIngredient(
        pantryItems[index].name,
      ); //delete in db and load pantry
      await _loadPantryItems();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingredient deleted')));
    }
  }

  //generate recipe
  void _generateRecipe() async {
    final names =
        pantryItems.where((i) => i.isSelected).map((i) => i.name).toList();
    if (names.isEmpty) return;

    setState(() => _loadingRecipes = true);
    try {
      final recipes = await _recipeService.searchRecipes(names);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => GeneratedRecipePage(
                recipes: recipes,
                ingredientQuery: names.join(', '),
              ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading recipes: $e')));
    } finally {
      setState(() => _loadingRecipes = false);
    }
  }

  Future<String?> fetchUnsplashImage(String name) async {
    final url = Uri.https('api.unsplash.com', '/search/photos', {
      'query': '$name food',
      'per_page': '1',
      'orientation': 'squarish',
      'client_id': 'BG_jaAJgeU7OwfFcInZyX0bO5OEov_kzVJfZYpHbqdE',
    });
    final resp = await http.get(url);
    if (resp.statusCode == 403) return null;
    if (resp.statusCode != 200) {
      throw Exception('Unsplash error: ${resp.statusCode}');
    }
    final data = json.decode(resp.body);
    final results = data['results'] as List;
    return results.isNotEmpty ? results[0]['urls']['small'] as String : null;
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
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                ),
          ),
        ],
      ),
      body:
          _loadingRecipes
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 200,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF004AAD), Color(0xFFCB6CE6)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Pantry',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: pantryItems.length,
                      itemBuilder: (context, index) {
                        final item = pantryItems[index];
                        final isExpiringSoon =
                            item.expiryDate != null &&
                            item.expiryDate!
                                    .difference(DateTime.now())
                                    .inDays <=
                                3;
                        //calculate the item expire date
                        final daysLeft =
                            item.expiryDate?.difference(DateTime.now()).inDays;

                        return Card(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: item.isSelected,
                                  onChanged:
                                      (value) => setState(
                                        () => item.isSelected = value ?? false,
                                      ),
                                ),

                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: FutureBuilder<String?>(
                                    future: imageService.getImageUrl(item.name),
                                    builder: (ctx, snap) {
                                      if (snap.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SizedBox(
                                          width: 50,
                                          height: 50,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      }
                                      final url = snap.data;
                                      if (url != null) {
                                        return Image.network(
                                          url,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) =>
                                                  _fallbackAsset(item),
                                        );
                                      }
                                      return _fallbackAsset(item);
                                    },
                                  ),
                                ),

                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (isExpiringSoon && daysLeft != null)
                                        Text(
                                          'Expiring in $daysLeft day${daysLeft == 1 ? '' : 's'}',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                          ),
                                          onPressed: () async {
                                            final currentQty =
                                                pantryItems[index].quantity;

                                            if (currentQty <= 1) {
                                              //ensure no negative quantity
                                              final confirm = await showDialog<
                                                bool
                                              >(
                                                context: context,
                                                builder:
                                                    (context) => Dialog(
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                      ),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              20,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                        ),
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            const Text(
                                                              'Remove Ingredient',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 18,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 16,
                                                            ),
                                                            const Text(
                                                              'Quantity is 1. Do you want to remove this ingredient from your pantry?',
                                                            ),
                                                            const SizedBox(
                                                              height: 24,
                                                            ),
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .end,
                                                              children: [
                                                                TextButton(
                                                                  onPressed:
                                                                      () => Navigator.pop(
                                                                        context,
                                                                        false,
                                                                      ),
                                                                  child:
                                                                      const Text(
                                                                        'Cancel',
                                                                      ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                                ElevatedButton(
                                                                  onPressed:
                                                                      () => Navigator.pop(
                                                                        context,
                                                                        true,
                                                                      ),
                                                                  style: ElevatedButton.styleFrom(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .red,
                                                                    foregroundColor:
                                                                        Colors
                                                                            .white,
                                                                  ),
                                                                  child:
                                                                      const Text(
                                                                        'Remove',
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                              );

                                              if (confirm == true) {
                                                await DatabaseHelper.instance
                                                    .deleteIngredient(
                                                      pantryItems[index].name,
                                                    );
                                                await _loadPantryItems();
                                              }

                                              return;
                                            }

                                            // normal quantity decrement
                                            final updatedItem =
                                                pantryItems[index].copyWith(
                                                  quantity: currentQty - 1,
                                                  updatedAt:
                                                      DateTime.now()
                                                          .millisecondsSinceEpoch,
                                                );

                                            setState(() {
                                              pantryItems[index] = updatedItem;
                                            });

                                            await DatabaseHelper.instance
                                                .insertPantryItem(updatedItem);
                                          },
                                        ),
                                        Text(
                                          item.quantity.toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                          ),
                                          onPressed: () async {
                                            final updatedItem =
                                                pantryItems[index].copyWith(
                                                  quantity:
                                                      pantryItems[index]
                                                          .quantity +
                                                      1,
                                                  updatedAt:
                                                      DateTime.now()
                                                          .millisecondsSinceEpoch,
                                                );

                                            setState(() {
                                              pantryItems[index] = updatedItem;
                                            });

                                            await DatabaseHelper.instance
                                                .insertPantryItem(updatedItem);
                                          },
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 18,
                                          ),
                                          onPressed:
                                              () => _editIngredient(index),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                          ),
                                          onPressed:
                                              () => _deleteIngredient(index),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: ElevatedButton.icon(
                      onPressed: _generateRecipe,
                      icon: const Icon(Icons.auto_awesome, color: Colors.white),
                      label: const Text(
                        'Generate Recipe',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4EFF),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF19006d),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 1,
        onTap: (index) {
          if (index != 1) {
            Navigator.pop(context);
            if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AllRecipePage()),
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
