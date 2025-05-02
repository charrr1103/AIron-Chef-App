import 'dart:io';
import 'package:flutter/services.dart';
import '../pages/ingredient_confirmation_screen.dart';
import 'object_detection_service.dart';

class ImageProcessingService {
  final _detector = ObjectDetectionService();

  Future<List<IngredientItem>> processImage(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      final detections = await _detector.detectObjects(imageFile);

      // Convert detections to IngredientItems
      return detections.map((detection) {
        return IngredientItem(
          name: detection.label,
          imageUrl:
              'assets/ingredients/${detection.label.toLowerCase().replaceAll(' ', '_')}.jpg',
          isSelected: true,
          confidence: detection.confidence,
          boundingBox: detection.boundingBox,
        );
      }).toList();
    } catch (e) {
      print('Error processing image: $e');
      rethrow;
    }
  }
}
