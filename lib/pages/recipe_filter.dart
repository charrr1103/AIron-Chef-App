import 'package:flutter/material.dart';

class RecipeFilter {
  String? cuisine;
  String? preparationTime;
  String skillLevel = 'Easy';
  String? mealType;
  String? dietaryRestrictions;

  Map<String, dynamic> toQueryParameters() {
    final Map<String, dynamic> params = {};
    
    if (cuisine != null) params['cuisine'] = cuisine!.toLowerCase();
    if (preparationTime != null) {
      final int? maxTime = int.tryParse(preparationTime!.replaceAll(RegExp(r'[^0-9]'), ''));
      if (maxTime != null) params['maxReadyTime'] = maxTime;
    }
    if (mealType != null) params['type'] = mealType!.toLowerCase();
    if (dietaryRestrictions != null) {
      switch (dietaryRestrictions!.toLowerCase()) {
        case 'gluten free':
          params['diet'] = 'gluten-free';
          break;
        case 'ketogenic':
          params['diet'] = 'keto';
          break;
        case 'vegetarian':
          params['diet'] = 'vegetarian';
          break;
        case 'vegan':
          params['diet'] = 'vegan';
          break;
        case 'pescetarian':
          params['diet'] = 'pescetarian';
          break;
        case 'paleo':
          params['diet'] = 'paleo';
          break;
        case 'primal':
          params['diet'] = 'primal';
          break;
        case 'low fodmap':
          params['diet'] = 'low-fodmap';
          break;
        case 'whole30':
          params['diet'] = 'whole30';
          break;
      }
    }
    
    return params;
  }
}

class RecipeFilterPage extends StatefulWidget {
  final RecipeFilter initialFilter;
  
  const RecipeFilterPage({super.key, required this.initialFilter});

  @override
  State<RecipeFilterPage> createState() => _RecipeFilterPageState();
}

class _RecipeFilterPageState extends State<RecipeFilterPage> {
  late RecipeFilter filter;
  
  final List<String> cuisines = [
    'African', 'Asian', 'American', 'British', 'Chinese', 
    'European', 'French', 'German', 'Indian', 'Italian',
    'Japanese', 'Korean', 'Thai', 'Vietnamese'
  ];

  final List<String> preparationTimes = [
    '15 minutes', '30 minutes', '45 minutes', '60 minutes', '90 minutes'
  ];

  final List<String> mealTypes = [
    'Breakfast', 'Main Course', 'Side Dish', 'Dessert', 'Appetizer', 'Soup', 'Snack', 'Drink'
  ];

  final List<String> dietaryRestrictions = [
    'Gluten Free', 'Ketogenic', 'Vegetarian', 'Vegan', 'Low FODMAP'
  ];

  @override
  void initState() {
    super.initState();
    filter = widget.initialFilter;
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
          'Filter',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                filter.cuisine = null;
                filter.preparationTime = null;
                filter.skillLevel = 'Easy';
                filter.mealType = null;
                filter.dietaryRestrictions = null;
              });
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cuisine:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildDropdown(
              value: filter.cuisine,
              items: cuisines,
              hint: 'Select Cuisine',
              onChanged: (value) => setState(() => filter.cuisine = value),
            ),
            
            const SizedBox(height: 16),
            const Text('Preparation Time:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildDropdown(
              value: filter.preparationTime,
              items: preparationTimes,
              hint: 'Select Time',
              onChanged: (value) => setState(() => filter.preparationTime = value),
            ),
            
            const SizedBox(height: 16),
            const Text('Skill Level:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildSkillLevelButton('Easy', Colors.green),
                const SizedBox(width: 8),
                _buildSkillLevelButton('Medium', Colors.orange),
                const SizedBox(width: 8),
                _buildSkillLevelButton('Hard', Colors.red),
              ],
            ),
            
            const SizedBox(height: 16),
            const Text('Meal Type:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildDropdown(
              value: filter.mealType,
              items: mealTypes,
              hint: 'Select Meal Type',
              onChanged: (value) => setState(() => filter.mealType = value),
            ),
            
            const SizedBox(height: 16),
            const Text('Dietary Restrictions:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildDropdown(
              value: filter.dietaryRestrictions,
              items: dietaryRestrictions,
              hint: 'Select Dietary Restriction',
              onChanged: (value) => setState(() => filter.dietaryRestrictions = value),
            ),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, filter),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4EFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Search', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint),
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSkillLevelButton(String level, Color color) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () => setState(() => filter.skillLevel = level),
        style: ElevatedButton.styleFrom(
          backgroundColor: filter.skillLevel == level ? color : Colors.grey.shade200,
          foregroundColor: filter.skillLevel == level ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(level),
      ),
    );
  }
}
