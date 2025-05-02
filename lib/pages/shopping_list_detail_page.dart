import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import '../pages/shopping_list.dart';
import '../pages/shopping_ingredient.dart';
import '../services/ingredient_images_service.dart'; // ✅ make sure you have this service

class ShoppingListDetailPage extends StatefulWidget {
  final ShoppingList list;

  const ShoppingListDetailPage({super.key, required this.list});

  @override
  State<ShoppingListDetailPage> createState() => _ShoppingListDetailPageState();
}

class _ShoppingListDetailPageState extends State<ShoppingListDetailPage> {
  final GlobalKey _globalKey = GlobalKey();
  final imageService = IngredientImageService();

  void _toggleBought(int index) {
    setState(() {
      widget.list.ingredients[index].bought = !widget.list.ingredients[index].bought;
    });
  }

  Widget _fallbackAsset(ShoppingIngredient item) {
    return Image.asset(
      'assets/ingredients/${item.name.toLowerCase().replaceAll(" ", "_")}.jpg',
      width: 50,
      height: 50,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
    );
  }

  Future<void> requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        await _downloadAsImage();
        return;
      }

      final result = await Permission.manageExternalStorage.request();
      if (result.isGranted) {
        await _downloadAsImage();
      } else if (result.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable storage permission in settings.')),
        );
        openAppSettings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission not granted.')),
        );
      }
    }
  }

  void _showAddIngredientDialog() {
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
              const Text(
                'Add Ingredient',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Enter ingredient name',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: const Color(0xFFF4F4F4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
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
                    onPressed: () {
                      final name = controller.text.trim();
                      if (name.isNotEmpty) {
                        final alreadyExists = widget.list.ingredients.any(
                          (ingredient) => ingredient.name.toLowerCase() == name.toLowerCase(),
                        );
                        if (alreadyExists) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ingredient already exists')),
                          );
                          return;
                        }
                        setState(() {
                          widget.list.ingredients.add(ShoppingIngredient(name: name));
                        });
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004AAD),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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

  Future<void> _downloadAsImage() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception("Failed to get byte data from image.");
      }

      final pngBytes = byteData.buffer.asUint8List();

      final directory = Directory('/storage/emulated/0/Download');
      final filePath = '${directory.path}/${widget.list.title.replaceAll(" ", "_")}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Image saved to: $filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to save image: $e')),
      );
    }
  }

  Future<void> _shareAsText() async {
    final text = widget.list.ingredients
        .map((item) => '${item.bought ? '[x]' : '[ ]'} ${item.name}')
        .join('\n');
    Share.share('🛒 ${widget.list.title}\n\n$text');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 12),

              RepaintBoundary(
                key: _globalKey,
                child: Container(
                  color: const Color(0xFFFFFBF0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF004AAD), Color(0xFFCB6CE6)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Shopping List',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          'For ${widget.list.title.replaceAll(" Ingredients", "")}',
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.list.ingredients.length,
                        itemBuilder: (context, index) {
                          final ingredient = widget.list.ingredients[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(2, 2),
                                )
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              leading: Checkbox(
                                value: ingredient.bought,
                                onChanged: (_) => _toggleBought(index),
                              ),
                              title: Text(
                                ingredient.name,
                                style: TextStyle(
                                  decoration: ingredient.bought ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              trailing: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: FutureBuilder<String?>(
                                  future: imageService.getImageUrl(ingredient.name),
                                  builder: (ctx, snap) {
                                    if (snap.connectionState == ConnectionState.waiting) {
                                      return const SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
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
                                        errorBuilder: (_, __, ___) => _fallbackAsset(ingredient),
                                      );
                                    }
                                    return _fallbackAsset(ingredient);
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: _showAddIngredientDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Ingredient'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004AAD),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 16, top: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: requestStoragePermission,
                      tooltip: "Download as image",
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: _shareAsText,
                      tooltip: "Share as text",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
