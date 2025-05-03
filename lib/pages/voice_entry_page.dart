import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:avatar_glow/avatar_glow.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'pantry_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/pantry_item.dart';
import 'package:airon_chef/services/database_helper.dart';
import 'package:airon_chef/utils/string_extensions.dart';

class VoiceEntryPage extends StatefulWidget {
  const VoiceEntryPage({super.key});

  @override
  State<VoiceEntryPage> createState() => _VoiceEntryPageState();
}

class _VoiceEntryPageState extends State<VoiceEntryPage> {
  late final stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isCancelled = false;
  String _recognizedText = '';

  List<String> _ingredients = [];
  List<String> _dict = [];
  Set<String> _selectedIngredients = {};

  static const _filterWords = {
    'i',
    'want',
    'to',
    'add',
    'have',
    'has',
    'some',
    'a',
    'also',
  };

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadDictionary();
    _initSpeech();
  }

  Future<void> _loadDictionary() async {
    final jsonString = await rootBundle.loadString('assets/ingredients.json');
    final List<dynamic> jsonData = json.decode(jsonString);
    _dict =
        jsonData.cast<String>()
          ..sort((a, b) => b.split(' ').length.compareTo(a.split(' ').length));
    debugPrint('Loaded dictionary: $_dict');
  }

  Future<void> _initSpeech() async {
    await _speech.initialize(
      onError: (err) => debugPrint('Speech init error: $err'),
      onStatus: (status) => debugPrint('Speech status: $status'),
    );
  }

  Future<void> _confirmSelection() async {
    // Load current pantry items from database
    final existingItems = await DatabaseHelper.instance.getAllPantryItems();

    for (final name in _selectedIngredients) {
      final alreadyExists = existingItems.any(
        (item) => item.name.toLowerCase() == name.toLowerCase(),
      );

      if (!alreadyExists) {
        await DatabaseHelper.instance.insertPantryItem(
          PantryItem(
            id: 0,
            name: name.toTitleCase(),
            quantity: 1,
            category: 'Other',
            expiryDate: DateTime.now().add(const Duration(days: 5)),
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PantryPage()),
    );
  }

  void _showMergeDialog() {
    final Set<String> toMerge = {};
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Merge Items'),
          content: StatefulBuilder(
            builder: (context, setState) {
              // whenever selection changes, update the text field
              void _updateController() {
                controller.text = toMerge.join(' ');
              }

              return SizedBox(
                width: double.maxFinite,
                height: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'Merged Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Scrollbar(
                        child: ListView(
                          children:
                              _ingredients.map((name) {
                                return CheckboxListTile(
                                  title: Text(name),
                                  value: toMerge.contains(name),
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked == true) {
                                        toMerge.add(name);
                                      } else {
                                        toMerge.remove(name);
                                      }
                                      _updateController();
                                    });
                                  },
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final merged = controller.text.trim();
                if (merged.isNotEmpty) {
                  setState(() {
                    _ingredients.removeWhere((i) => toMerge.contains(i));
                    _selectedIngredients.removeAll(toMerge);
                    _ingredients.add(merged);
                    _selectedIngredients.add(merged);
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Merge & Add'),
            ),
          ],
        );
      },
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
              colors: [Color(0xFF6B4EFF), Color(0xFF9747FF)],
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
          'Voice Entry',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child:
                  _ingredients.isEmpty
                      ? Center(
                        child: Text(
                          'Hold the mic and speak ingredient names',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.black54),
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: _ingredients.length,
                        itemBuilder: (context, i) {
                          final name = _ingredients[i];
                          final checked = _selectedIngredients.contains(name);
                          return Opacity(
                            opacity: checked ? 1.0 : 0.5,
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: CheckboxListTile(
                                title: Text(
                                  name,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                value: checked,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                activeColor: const Color(0xFF6B4EFF),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedIngredients.add(name);
                                    } else {
                                      _selectedIngredients.remove(name);
                                    }
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
            ),

            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: 16,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Mic button
                    AvatarGlow(
                      animate: _isListening,
                      glowColor: const Color(0xFF6B4EFF),
                      child: GestureDetector(
                        onPanStart: (_) {
                          setState(() {
                            _recognizedText = '';
                            _isListening = true;
                            _isCancelled = false;
                          });
                          _speech.listen(
                            onResult:
                                (r) => setState(
                                  () => _recognizedText = r.recognizedWords,
                                ),
                            listenFor: const Duration(
                              seconds: 30,
                            ), // max total time
                            pauseFor: const Duration(
                              seconds: 30,
                            ), // silence timeout
                            // live updates
                            listenOptions: stt.SpeechListenOptions(
                              partialResults: true,
                              cancelOnError: false,
                              listenMode: stt.ListenMode.dictation,
                            ),
                          );
                        },
                        onPanUpdate: (details) {
                          if (details.localPosition.dy < -50 && !_isCancelled) {
                            setState(() => _isCancelled = true);
                          }
                        },
                        onPanEnd: (_) {
                          _speech.stop();

                          if (!_isCancelled && _recognizedText.isNotEmpty) {
                            String input = _recognizedText.toLowerCase();
                            final found = <String>{};
                            for (var name in _dict) {
                              if (input.contains(name)) {
                                found.add(name);
                                input = input.replaceAll(name, ' ');
                              }
                            }

                            final leftovers = input
                                .split(RegExp(r',|\band\b|\s+'))
                                .map((w) => w.trim())
                                .where(
                                  (w) =>
                                      w.isNotEmpty &&
                                      !_filterWords.contains(w) &&
                                      !found.contains(w) &&
                                      !found.contains(w),
                                );
                            found.addAll(leftovers);
                            debugPrint('Matched ingredients: $found');

                            setState(() {
                              for (var name in found) {
                                if (!_ingredients.contains(name)) {
                                  _ingredients.add(name);
                                  _selectedIngredients.add(name);
                                }
                              }
                            });
                          }

                          setState(() {
                            _isListening = false;
                            _isCancelled = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // grey out if cancelling
                            color:
                                _isCancelled
                                    ? Colors.grey
                                    : (_isListening
                                        ? Colors.red
                                        : const Color(0xFF6B4EFF)),
                          ),
                          child: Icon(
                            _isListening
                                ? (_isCancelled ? Icons.cancel : Icons.mic)
                                : Icons.mic_none,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 60),

                    IconButton(
                      icon: const Icon(Icons.merge_type, size: 32),
                      tooltip: 'Merge two items',
                      onPressed:
                          _ingredients.length >= 2 ? _showMergeDialog : null,
                    ),
                  ],
                ),
              ),
            ),

            // ── Debug “Heard” text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Heard: $_recognizedText',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _selectedIngredients.isEmpty ? null : _confirmSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4EFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'Confirm Selection',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
