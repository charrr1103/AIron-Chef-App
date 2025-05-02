import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:airon_chef/pages/onboarding_screen.dart'; // import OnboardingScreen
import 'package:airon_chef/pages/home.dart'; // import HomeScreen
import 'package:airon_chef/services/object_detection_service.dart'; // import ObjectDetectionService
import 'package:ultralytics_yolo/yolo.dart';
import 'package:airon_chef/providers/recipe_provider.dart';
import 'package:airon_chef/services/database_helper.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> _seedTestData() async {
  final db = DatabaseHelper.instance;
  final now = DateTime.now().millisecondsSinceEpoch;

  // You can tweak these expiry dates to whatever you like, or set to null.
  await db.addPantryItem(
    name: 'Tomato',
    quantity: 3,
    category: 'Vegetable',
    expiryDate: '2025-05-15',
  );
  await db.addPantryItem(
    name: 'Potato',
    quantity: 5,
    category: 'Vegetable',
    expiryDate: null,
  );
  await db.addPantryItem(
    name: 'Chicken Breast',
    quantity: 2,
    category: 'Meat',
    expiryDate: '2025-06-01',
  );
  await db.addPantryItem(
    name: 'Mushroom',
    quantity: 1,
    category: 'Vegetable',
    expiryDate: null,
  );
  await db.addPantryItem(
    name: 'Apple',
    quantity: 4,
    category: 'Fruit',
    expiryDate: '2025-05-20',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final ok = await YOLO.checkModelExists('yolov8');
  await _seedTestData();
  debugPrint('Model found by plugin? $ok');

  await ObjectDetectionService().loadModel(); // singleton call
  await _seedTestData();

  runApp(const MyApp());


}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => RecipeProvider())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Poppins',
          textTheme: const TextTheme(
            displayLarge: TextStyle(fontFamily: 'Poppins'),
            displayMedium: TextStyle(fontFamily: 'Poppins'),
            displaySmall: TextStyle(fontFamily: 'Poppins'),
            headlineLarge: TextStyle(fontFamily: 'Poppins'),
            headlineMedium: TextStyle(fontFamily: 'Poppins'),
            headlineSmall: TextStyle(fontFamily: 'Poppins'),
            titleLarge: TextStyle(fontFamily: 'Poppins'),
            titleMedium: TextStyle(fontFamily: 'Poppins'),
            titleSmall: TextStyle(fontFamily: 'Poppins'),
            bodyLarge: TextStyle(fontFamily: 'Poppins'),
            bodyMedium: TextStyle(fontFamily: 'Poppins'),
            bodySmall: TextStyle(fontFamily: 'Poppins'),
            labelLarge: TextStyle(fontFamily: 'Poppins'),
            labelMedium: TextStyle(fontFamily: 'Poppins'),
            labelSmall: TextStyle(fontFamily: 'Poppins'),
          ),
          appBarTheme: const AppBarTheme(
            titleTextStyle: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        home: const SplashScreen(), // Start with SplashScreen
      ),
    );
  }
}

// Custom Splash Screen with Gradient Background
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // ⏳ Navigate to OnboardingScreen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const OnboardingScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF004AAD), // Left (Blue)
              Color(0xFFCB6CE6), // Right (Purple)
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Center(
          child: Image.asset("assets/logo.png", width: 270), // AIron Chef logo
        ),
      ),
    );
  }
}
