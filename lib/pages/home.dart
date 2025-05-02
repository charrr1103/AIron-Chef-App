import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import './ingredient_confirmation_screen.dart';
import '../services/image_processing_service.dart';
import '../services/object_detection_service.dart';
import '../widgets/loading_overlay.dart';
import './pantry_page.dart';
import './all_recipe_page.dart';
import './shopping_list_page.dart';
import './voice_entry_page.dart';
import './manual_entry_page.dart';
import './profile_page.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> getCurrentUserFullName() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      return 'Guest User';
    }
    try {
      final DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['fullName'] ?? 'User';
      } else {
        return 'User';
      }
    } catch (e) {
      print("Error fetching user data: $e");
      return 'User';
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load YOLO model once at startup
  await ObjectDetectionService().loadModel();

  runApp(const MaterialApp(home: HomeScreen()));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isProcessing = false;
  String _fullName = '...';
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final fullName = await _userService.getCurrentUserFullName();
    if (mounted) {
      setState(() {
        _fullName = fullName;
      });
    }
  }

  Future<void> _processImage(String path) async {
    setState(() => _isProcessing = true);
    try {
      final service = ImageProcessingService();
      final detected = await service.processImage(path);

      setState(() => _isProcessing = false);

      // Always navigate to the confirmation screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IngredientConfirmationScreen(
            imagePath: path,
            detectedIngredients: detected,
          ),
        ),
      );

      // If user chose to retake, reopen photo entry
      if (result == 'retake') {
        _onPhotoEntry();
      }
      // If user confirmed items, show count
      else if (result is List<IngredientItem> && result.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${result.length} items added!')),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // picks from camera
  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) _processImage(photo.path);
  }

  // picks from gallery
  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) _processImage(picked.path);
  }

  void _onPhotoEntry() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pick from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBetaInfo() async {
    final labels = await rootBundle.loadString('assets/models/coco_labels.txt');

    final message = StringBuffer()
      ..writeln(
        '🚧 This app is currently in beta testing. '
            'Model accuracy is limited and only a small set of ingredients '
            'can be detected reliably. Thank you for testing!',
      )
      ..writeln('\n— Available detection classes —\n')
      ..writeln(labels.trim());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Early Access Information'),
        content: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              message.toString(),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
            title: Row(
              children: [
                Image.asset('assets/logo.png', height: 35),
                const SizedBox(width: 30),
                const Text(
                  'AIron Chef',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.account_circle, color: Colors.white),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                  _loadUserName();
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 80,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/food-banner.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, $_fullName!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add ingredients to your pantry:',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 20),
                      _buildOptionButton(
                        icon: Icons.photo_camera,
                        label: 'Photo Entry',
                        onPressed: _onPhotoEntry,
                      ),
                      const SizedBox(height: 20),
                      _buildOptionButton(
                        icon: Icons.mic,
                        label: 'Voice Entry',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VoiceEntryPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildOptionButton(
                        icon: Icons.edit_note,
                        label: 'Manual Entry',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManualEntryPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Early access info link above nav bar
                GestureDetector(
                  onTap: _showBetaInfo,
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: const Center(
                      child: Text(
                        'Early‑Access > click for more',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFF19006d),
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.kitchen),
                label: 'Pantry',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.restaurant_menu),
                label: 'Recipes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_basket),
                label: 'List',
              ),
            ],
            currentIndex: 0,
            onTap: (index) {
              if (index != 0) {
                if (index == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PantryPage()),
                  );
                } else if (index == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllRecipePage(),
                    ),
                  );
                } else if (index == 3) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ShoppingListPage(),
                    ),
                  );
                }
              }
            },
          ),
        ),
        if (_isProcessing)
          const LoadingOverlay(
            message: 'Analyzing ingredients...\nThis may take a moment',
          ),
      ],
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6B4EFF), Color(0xFF9747FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // circular icon badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: Colors.white),
            ),
            const SizedBox(width: 16),
            // label text
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // chevron
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
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

