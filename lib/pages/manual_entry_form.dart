import 'package:flutter/material.dart';
import 'package:airon_chef/pages/manual_entry_page.dart';
import 'package:airon_chef/services/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:airon_chef/utils/string_extensions.dart';

class ManualEntryForm extends StatefulWidget {
  final String initialName;
  final int initialQuantity;
  final String initialCategory;
  final DateTime? initialExpiryDate;

  const ManualEntryForm({
    Key? key,
    this.initialName = '',
    this.initialQuantity = 1,
    this.initialCategory = 'Other',
    this.initialExpiryDate,
  }) : super(key: key);

  @override
  State<ManualEntryForm> createState() => _ManualEntryFormState();
}

class _ManualEntryFormState extends State<ManualEntryForm> {
  final _formKey = GlobalKey<FormState>();

  final _ingredientController = TextEditingController();
  late TextEditingController _nameController;
  int _quantity = 1;
  String? _selectedCategory;
  DateTime? _expiryDate;

  final List<String> _categories = [
    'Vegetable',
    'Fruit',
    'Meat',
    'Dairy',
    'Spice',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _quantity = widget.initialQuantity;
    _selectedCategory = widget.initialCategory;
    _expiryDate = widget.initialExpiryDate;
  }

  @override
  void dispose() {
    _ingredientController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _addToPantry() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim().toTitleCase();
      final qty = _quantity;
      final cat = _selectedCategory!;
      final expStr = _expiryDate?.toIso8601String();

      // Insert or replace into your SQLite pantry table
      await DatabaseHelper.instance.addPantryItem(
        name: name,
        quantity: qty,
        category: cat,
        expiryDate: expStr,
      );

      // Pop back, passing the details if you need them
      Navigator.pop(context, {
        'name': name,
        'quantity': qty,
        'category': cat,
        'expiry': expStr,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6B4EFF), Color(0xFF9747FF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                // Your logo in the center
                Image.asset('assets/logo.png', height: 32),
                const Spacer(),
                const SizedBox(width: 48), // balance the back-arrow size
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3053BD), Color(0xFFBD4DE5)],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'Text Input',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Ingredient Name
                        const Text(
                          'Ingredient Name:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: 'Enter ingredient name',
                            prefixIcon: Icon(Icons.emoji_food_beverage),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          validator:
                              (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Please enter a name'
                                      : null,
                        ),
                        const SizedBox(height: 24),

                        // Quantity
                        const Text(
                          'Quantity:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed:
                                  _quantity > 1
                                      ? () => setState(() => _quantity--)
                                      : null,
                            ),
                            Text(
                              '$_quantity',
                              style: const TextStyle(fontSize: 18),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => setState(() => _quantity++),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Category
                        const Text(
                          'Category:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items:
                              _categories
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                          value: _selectedCategory,
                          onChanged:
                              (v) => setState(() => _selectedCategory = v),
                          validator:
                              (v) => v == null ? 'Please choose one' : null,
                        ),
                        const SizedBox(height: 24),

                        // Expiration Date (optional)
                        const Text(
                          'Expiration Date (Optional):',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: _pickExpiryDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            child: Text(
                              _expiryDate == null
                                  ? 'Expiry Date'
                                  : DateFormat.yMMMd().format(_expiryDate!),
                              style: TextStyle(
                                color:
                                    _expiryDate == null
                                        ? Colors.grey
                                        : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Add to Pantry button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _addToPantry,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B4EFF),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Add to Pantry',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
