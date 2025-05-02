import 'package:flutter/material.dart';
import 'package:airon_chef/services/database_helper.dart';
import '../pages/shopping_list.dart';
import '../pages/shopping_ingredient.dart';
import './pantry_page.dart';
import './recipe_page.dart';
import './all_recipe_page.dart';
import 'profile_page.dart';
import 'shopping_list_detail_page.dart';

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key});

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  List<ShoppingList> shoppingLists = [];

  @override
  void initState() {
    super.initState();
    _loadShoppingLists();
  }

  Future<void> _loadShoppingLists() async {
    final lists = await DatabaseHelper.instance.getAllShoppingLists();
    setState(() {
      shoppingLists = lists;
    });
  }

Future<void> _deleteList(int index) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Delete List', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to delete this shopping list?',
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context, true),
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
    final title = shoppingLists[index].title;
    await DatabaseHelper.instance.deleteShoppingList(title);
    await _loadShoppingLists();
  }
}


Future<void> _editListTitle(int index) async {
  final oldTitle = shoppingLists[index].title;
  final controller = TextEditingController(text: oldTitle);

  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Edit List Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'List Title',
                border: OutlineInputBorder(),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004AAD),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final newTitle = controller.text.trim();
                    if (newTitle.isNotEmpty && newTitle != oldTitle) {
                      final updatedList = ShoppingList(
                        title: newTitle,
                        ingredients: shoppingLists[index].ingredients,
                      );
                      await DatabaseHelper.instance.deleteShoppingList(oldTitle);
                      await DatabaseHelper.instance.insertShoppingList(updatedList);
                      await _loadShoppingLists();
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

 Future<void> _addNewList() async {
  final controller = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('New Shopping List', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'List Title',
                border: OutlineInputBorder(),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004AAD),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final inputTitle = controller.text.trim();

                    if (inputTitle.isNotEmpty) {
                      // Capitalize each word
                      final formattedTitle = inputTitle
                        .split(' ')
                        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '')
                        .join(' ')
                        .trim() + ' Ingredients';  // add Ingredients

                      final alreadyExists = shoppingLists.any(
                        (list) => list.title.toLowerCase() == formattedTitle.toLowerCase(),
                      );

                      if (alreadyExists) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('⚠️ List with same name already exists!')),
                        );
                        return;
                      }

                      try {
                        final newList = ShoppingList(title: formattedTitle, ingredients: []);
                        await DatabaseHelper.instance.insertShoppingList(newList);
                        await _loadShoppingLists();
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('✅ List "$formattedTitle" created successfully')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error creating list: $e')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('⚠️ Title cannot be empty')),
                      );
                    }
                  },

                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
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
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF004AAD), Color(0xFFCB6CE6)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'My Shopping Lists',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF004AAD),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _addNewList,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: shoppingLists.isEmpty
                ? const Center(child: Text('No shopping lists yet.'))
                : ReorderableListView(
                    padding: const EdgeInsets.all(12),
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex -= 1;
                      setState(() {
                        final item = shoppingLists.removeAt(oldIndex);
                        shoppingLists.insert(newIndex, item);
                      });
                    },
                    children: [
                      for (int i = 0; i < shoppingLists.length; i++)
                        Card(
                          key: ValueKey(shoppingLists[i].title),
                          color: Colors.white, 
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShoppingListDetailPage(list: shoppingLists[i]),
                                ),
                              );
                            },
                            leading: const Icon(Icons.drag_indicator),
                            title: Text(
                              shoppingLists[i].title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                ...shoppingLists[i].ingredients
                                    .take(3)
                                    .map((e) => Text(e.name, style: const TextStyle(fontSize: 13))),
                                if (shoppingLists[i].ingredients.length > 3)
                                  const Text('...', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _editListTitle(i),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  onPressed: () => _deleteList(i),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E0C4C),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 3,
        onTap: (index) {
          if (index != 3) {
            Navigator.pop(context);
            if (index == 1) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PantryPage()));
            } else if (index == 2) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AllRecipePage()));
            }
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Pantry'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Recipes'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_basket), label: 'List'),
        ],
      ),
    );
  }
}
