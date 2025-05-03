import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/yolo.dart';
import 'package:ultralytics_yolo/yolo_result.dart';
import 'package:ultralytics_yolo/yolo_task.dart';

class ObjectDetectionService {
  static final ObjectDetectionService _instance =
      ObjectDetectionService._internal();
  factory ObjectDetectionService() => _instance;
  ObjectDetectionService._internal();

  YOLO? _yolo;
  Future<void>? _loading;
  static const double _confThreshold = 0.2;

  Future<void> _ensureLoaded() {
    // If already loaded, return completed future
    if (_yolo != null) return Future.value();

    // If a load is in progress, return the same future
    _loading ??= () async {
      _yolo = YOLO(modelPath: 'yolov8_32', task: YOLOTask.detect);
      await _yolo!.loadModel();
    }();

    return _loading!;
  }

  // Optional explicit preload (e.g. main.dart)
  Future<void> loadModel() => _ensureLoaded();

  Future<List<DetectedObject>> detectObjects(File img) async {
    await _ensureLoaded(); // guarantees _yolo is ready

    final bytes = await img.readAsBytes();
    final raw = await _yolo!.predict(bytes);

    // Manual parsing of raw map
    final List<dynamic> boxes = raw['boxes'] as List<dynamic>? ?? [];
    final List<DetectedObject> detections =
        boxes
            .map((b) {
              final x1 = (b['x1'] as num).toDouble();
              final y1 = (b['y1'] as num).toDouble();
              final x2 = (b['x2'] as num).toDouble();
              final y2 = (b['y2'] as num).toDouble();
              final String label = b['class'] as String;
              final double conf = (b['confidence'] as num).toDouble();
              final rect = Rect.fromLTWH(x1, y1, x2 - x1, y2 - y1);
              return DetectedObject(
                label: label,
                confidence: conf,
                boundingBox: rect,
              );
            })
            .where((d) => d.confidence >= _confThreshold)
            .toList();

    return detections;
  }
}

class DetectedObject {
  DetectedObject({
    required this.label,
    required this.confidence,
    required this.boundingBox,
    this.isSelected = true,
  });

  final String label;
  final double confidence;
  final Rect boundingBox;
  bool isSelected;

  String get confidencePercentage =>
      '${(confidence * 100).toStringAsFixed(1)}%';
}
