import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;

import '../pages/shopping_ingredient.dart';
import '../pages/shopping_list.dart';

class ShoppingListCard extends StatefulWidget {
  final ShoppingList list;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ShoppingListCard({
    super.key,
    required this.list,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<ShoppingListCard> createState() => _ShoppingListCardState();
}

class _ShoppingListCardState extends State<ShoppingListCard> {
  final GlobalKey _globalKey = GlobalKey();

  Future<void> _captureAndSharePng() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/${widget.list.title}.png';
      File imgFile = File(path)..writeAsBytesSync(pngBytes);

      await Share.shareXFiles([XFile(imgFile.path)], text: widget.list.title);
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _globalKey,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: ListTile(
          title: Text(
            widget.list.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            widget.list.ingredients.map((e) => e.name).take(3).join(', ') +
                (widget.list.ingredients.length > 3 ? '...' : ''),
          ),
          trailing: Wrap(
            spacing: 8,
            children: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _captureAndSharePng,
              ),
              IconButton(icon: const Icon(Icons.edit), onPressed: widget.onEdit),
              IconButton(icon: const Icon(Icons.delete), onPressed: widget.onDelete),
            ],
          ),
        ),
      ),
    );
  }
}
