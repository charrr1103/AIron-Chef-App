import 'package:airon_chef/pages/home.dart';
import 'package:airon_chef/widgets/pantry_item.dart';
import 'package:flutter/material.dart';
import 'manual_entry_form.dart';
import '../services/database_helper.dart';

class ManualEntryPage extends StatefulWidget {
  const ManualEntryPage({Key? key}) : super(key: key);

  @override
  State<ManualEntryPage> createState() => _ManualEntryPageState();
}

class _ManualEntryPageState extends State<ManualEntryPage> {
  final TextEditingController _searchController = TextEditingController();

  List<PantryItem> _recentItems = [];
  List<PantryItem> _pantryItems = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadPantryData();
  }

  Future<void> _loadPantryData() async {
    _recentItems = await DatabaseHelper.instance.getRecentPantryItems();
    _pantryItems = await DatabaseHelper.instance.getAllPantryItems();
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// All pantry items matching the current query
  List<PantryItem> get _matchesItems {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return [];
    return _pantryItems
        .where((it) => it.name.toLowerCase().contains(q))
        .toList();
  }

  /// Show “add new” only when there's a query but no matches
  bool get _showAddNew =>
      _searchController.text.trim().isNotEmpty && _matchesItems.isEmpty;

  Future<void> _onAddNewIngredient(String query) async {
    // Jump to Manual Entry Form
    final initial = _searchController.text.trim();
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => ManualEntryForm(initialName: initial)),
    );
    if (result != null) {
      // pop back to whatever called ManualEntryPage, passing the form result
      await _loadPantryData();
      _searchController.clear();
      Navigator.pop(context, result);
    }
  }

  Future<void> _onSelectExisting(PantryItem item) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder:
            (_) => ManualEntryForm(
              initialName: item.name,
              initialQuantity: item.quantity,
              initialCategory: item.category,
              initialExpiryDate: item.expiryDate,
            ),
      ),
    );
    if (result != null) {
      // Navigator.pop(context, result);
      await _loadPantryData();
      _searchController.clear();
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();

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
          'Add Ingredients',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1️⃣ Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search ingredients...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // Results
            Expanded(
              child:
                  query.isEmpty
                      // Show recent when nothing typed
                      ? ListView.separated(
                        itemCount: _recentItems.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, i) {
                          final item = _recentItems[i];
                          return ListTile(
                            leading: const Icon(Icons.history),
                            title: Text(item.name),
                            onTap: () => _onSelectExisting(item),
                          );
                        },
                      )
                      // Show matches + “Add new” when query present
                      : ListView(
                        children: [
                          if (_matchesItems.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'Suggestions',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            ..._matchesItems.map(
                              (item) => ListTile(
                                leading: const Icon(Icons.kitchen),
                                title: Text(item.name),
                                onTap: () => _onSelectExisting(item),
                              ),
                            ),
                          ],
                          if (_showAddNew) ...[
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.add_circle_outline),
                              title: const Text('Add new ingredient'),
                              subtitle: Text('"$query"'),
                              onTap: () => _onAddNewIngredient(query),
                            ),
                          ],
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
