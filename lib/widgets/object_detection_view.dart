import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/object_detection_service.dart';

class ObjectDetectionView extends StatefulWidget {
  const ObjectDetectionView({
    super.key,
    required this.imageFile,
    required this.detections,
  });

  final File imageFile;
  final List<DetectedObject> detections;

  @override
  State<ObjectDetectionView> createState() => _ObjectDetectionViewState();
}

class _ObjectDetectionViewState extends State<ObjectDetectionView> {
  late Future<ui.Image> _decoded;

  @override
  void initState() {
    super.initState();
    _decoded = _decode(widget.imageFile);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image>(
      future: _decoded,
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final img = snap.data!;
        return LayoutBuilder(
          builder: (context, constraints) {
            final scale = _containScale(
              img.width.toDouble(),
              img.height.toDouble(),
              constraints.maxWidth,
              constraints.maxHeight,
            );
            final offsetX = (constraints.maxWidth - img.width * scale) / 2;
            final offsetY = (constraints.maxHeight - img.height * scale) / 2;

            return Stack(
              children: [
                Positioned.fill(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Image.file(widget.imageFile),
                  ),
                ),
                for (final d in widget.detections)
                  Positioned(
                    left: offsetX + d.boundingBox.left * scale,
                    top: offsetY + d.boundingBox.top * scale,
                    width: d.boundingBox.width * scale,
                    height: d.boundingBox.height * scale,
                    child: _Box(label: d.label, conf: d.confidence),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<ui.Image> _decode(File f) async =>
      await decodeImageFromList(await f.readAsBytes());
}

class _Box extends StatelessWidget {
  const _Box({required this.label, required this.conf});
  final String label;
  final double conf;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: Container(
          color: Colors.black54,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          child: Text(
            '$label ${(conf * 100).toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

double _containScale(double srcW, double srcH, double maxW, double maxH) =>
    (maxW / srcW).clamp(0, maxH / srcH);
