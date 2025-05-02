import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import your SignUpPage.  Make sure the path is correct.
import 'home.dart';
import 'signup_page.dart'; // <--- Import the SignUpPage
import 'login_page.dart'; // <--- Import the LoginPage
import 'home.dart'; // Import your HomeScreen

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool isLastPage = false;
  bool _hasSeenOnboarding = false; // Track if onboarding has been seen
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  // Use SharedPreferences to check if the user has seen the onboarding screen
  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    });

    // If the user is logged in or has seen the onboarding, go to the main app screen
    if (_hasSeenOnboarding || _auth.currentUser != null) {
      _navigateToMainApp();
    }
  }

  // Method to navigate to the main app screen (HomeScreen in your case)
  void _navigateToMainApp() {
    // Use pushReplacement to avoid the user being able to go back to the onboarding screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
        const HomeScreen(), // Replace with your actual main app screen
      ),
    );
  }

  // Method to set the flag that the user has seen the onboarding screen
  Future<void> _setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
  }

  @override
  Widget build(BuildContext context) {
    // If the user has already seen the onboarding screen, don't show it again
    if (_hasSeenOnboarding) {
      return const Scaffold(body: Center(child: CircularProgressIndicator())); //Or any other initial screen you want to show
    }

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                isLastPage = index == 2;
              });
            },
            children: [
              buildPage(
                  "Hi there!",
                  "AIron Chef is ready to assist and enhance your experience",
                  "assets/onboarding1.png",
                  0),
              buildPage(
                  "Smart Recipe Generator",
                  "The app will then generate recipes based on the ingredients you have",
                  "assets/onboarding2.png",
                  1),
              buildThirdPage(),
            ],
          ),
          if (!isLastPage)
            Positioned(
              bottom: 80,
              left: 20,
              child: TextButton(
                onPressed: () {
                  _controller.jumpToPage(2);
                },
                child: Text("Skip",
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: const Color(0xFF19006D))),
              ),
            ),
          if (!isLastPage)
            Positioned(
              bottom: 80,
              right: 20,
              child: ElevatedButton(
                onPressed: () {
                  _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF19006D),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                ),
                child: Text("Next",
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: Colors.white)),
              ),
            ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _controller,
                count: 3,
                effect: const WormEffect(dotHeight: 8, dotWidth: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPage(String title, String subtitle, String imagePath, int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        double screenHeight = constraints.maxHeight;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            gradient: index < 2
                ? const LinearGradient(
              colors: [
                Color(0xFF3053BD),
                Color(0xFFBD4DE5),
                Color(0xFFFFFFFF)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            )
                : null,
            color: index == 2 ? Colors.orange : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.12),
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(subtitle,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
                  textAlign: TextAlign.center),
              SizedBox(height: screenHeight * 0.02),
              Image.asset(imagePath,
                  width: screenWidth * 0.8,
                  height: screenHeight * 0.5,
                  fit: BoxFit.contain),
            ],
          ),
        );
      },
    );
  }

  Widget buildThirdPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isLandscape = constraints.maxWidth > constraints.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset("assets/onboarding3.png", fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                          fontSize: 35,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                            text: "Welcome to\n",
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.normal)),
                        TextSpan(
                            text: "AIron ",
                            style: GoogleFonts.poppins(fontSize: 30)),
                        TextSpan(
                            text: "Chef!",
                            style: GoogleFonts.poppins(fontSize: 35)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text("Snap, cook, conquer!",
                      style: TextStyle(
                          fontSize: 28,
                          fontFamily: 'Batangas',
                          color: Colors.white),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 25),
                  isLandscape
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildGlowingButton("Login", () async {
                        await _setOnboardingSeen(); // set seen when login/signup
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                        );
                      }),
                      const SizedBox(width: 10),
                      buildGradientButton("Sign Up", () async {
                        await _setOnboardingSeen();  // set seen when login/signup
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUpPage()),
                        );
                      }),
                    ],
                  )
                      : Column(
                    children: [
                      buildGlowingButton("Login", () async {
                        await _setOnboardingSeen(); // set seen when login/signup
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                        );
                      }),
                      const SizedBox(height: 10),
                      buildGradientButton("Sign Up", () async {
                        await _setOnboardingSeen(); // set seen when login/signup
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUpPage()),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildGlowingButton(String text, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
        borderRadius: BorderRadius.circular(30),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF19006D),
          padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 15),
          textStyle: GoogleFonts.poppins(fontSize: 14),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget buildGradientButton(String text, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3053BD), Color(0xFFBD4DE5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(text,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
      ),
    );
  }
}
