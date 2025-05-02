import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/object_detection_view.dart';
import '../services/object_detection_service.dart';
import '../services/database_helper.dart';
import '../pages/pantry_page.dart';
import '../utils/string_extensions.dart';

class IngredientConfirmationScreen extends StatefulWidget {
  const IngredientConfirmationScreen({
    Key? key,
    required this.imagePath,
    required this.detectedIngredients,
  }) : super(key: key);

  final String imagePath;
  final List<IngredientItem> detectedIngredients;

  @override
  State<IngredientConfirmationScreen> createState() =>
      _IngredientConfirmationScreenState();
}

class _IngredientConfirmationScreenState
    extends State<IngredientConfirmationScreen> {
  late final List<IngredientItem> ingredients;

  @override
  void initState() {
    super.initState();

    final seen = <String>{};
    ingredients =
        widget.detectedIngredients.where((i) => seen.add(i.name)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final imageFile = File(widget.imagePath);

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
          onPressed: () => Navigator.pop(context, 'retake'),
        ),
        title: const Text(
          'Confirm Ingredients',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image with bounding boxes or plain image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    ingredients.isNotEmpty
                        ? ObjectDetectionView(
                          imageFile: imageFile,
                          detections:
                              ingredients
                                  .map(
                                    (i) => DetectedObject(
                                      label: i.name,
                                      confidence: i.confidence,
                                      boundingBox: i.boundingBox,
                                    ),
                                  )
                                  .toList(),
                        )
                        : Image.file(imageFile, fit: BoxFit.contain),
              ),
              const SizedBox(height: 20),
              const Text(
                'Detected Ingredients',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please confirm the detected ingredients',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // List of items or placeholder
              if (ingredients.isNotEmpty)
                ...ingredients.map((ing) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CheckboxListTile(
                      value: ing.isSelected,
                      onChanged: (v) => setState(() => ing.isSelected = v!),
                      title: Text(ing.name),
                      secondary: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          ing.imageUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Image.file(
                                imageFile,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                        ),
                      ),
                    ),
                  );
                }).toList()
              else
                const Center(
                  child: Text(
                    'No ingredients found',
                    style: TextStyle(fontSize: 20, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 20),
              const Text(
                'Take another photo?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, 'retake');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF19006d),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text('Yes'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () async {
                      // Save each selected ingredient
                      for (var ing in ingredients.where((i) => i.isSelected)) {
                        await DatabaseHelper.instance.addPantryItem(
                          name: ing.name.toTitleCase(),
                          quantity: 1,
                          category: 'Other',
                          expiryDate: null,
                        );
                      }
                      // Navigate back to pantry
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const PantryPage()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E4DD8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text('Add to Pantry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IngredientItem {
  final String name;
  final String imageUrl;
  bool isSelected;
  final double confidence;
  final Rect boundingBox;

  IngredientItem({
    required this.name,
    required this.imageUrl,
    this.isSelected = false,
    required this.confidence,
    required this.boundingBox,
  });
}
