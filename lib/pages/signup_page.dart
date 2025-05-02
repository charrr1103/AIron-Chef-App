import 'dart:io';
import 'dart:ui';
import './home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _showSuccessOverlay = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      key: _scaffoldMessengerKey,
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF004AAD),
                  Color(0xFFCB6CE6),
                ],
              ),
            ),
          ),
          // Blurred white layer (glass effect)
          Positioned(
            top: size.height * 0.32,
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildTextField(hintText: 'Email', controller: _emailController),
                        const SizedBox(height: 16),
                        _buildTextField(hintText: 'Full Name', controller: _nameController),
                        const SizedBox(height: 16),
                        _buildTextField(hintText: 'Username', controller: _usernameController),
                        const SizedBox(height: 16),
                        _buildTextField(
                          hintText: 'Password',
                          obscureText: _obscurePassword,
                          isPasswordField: true,
                          controller: _passwordController,
                          onToggle: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          hintText: 'Confirm Password',
                          obscureText: _obscureConfirmPassword,
                          isPasswordField: true,
                          controller: _confirmPasswordController,
                          onToggle: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () => signUpUser(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF19006D),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Have an account? ",
                              style: TextStyle(fontSize: 16),
                            ),
                            GestureDetector(
                              onTap: () {
                                // TODO: Implement navigation to login page
                              },
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4169E1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Logo + Title
          Positioned(
            top: size.height * 0.1,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Image.asset(
                  'assets/signupImg.png',
                  height: 120,
                ),
                const SizedBox(height: 5),
                const Text(
                  "Let's get started",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontFamily: 'Batangas',
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Success Overlay
          if (_showSuccessOverlay)
            Positioned.fill(
              child: Container(
                color: const Color(0xFFCB6CE6).withOpacity(0.8),
                child:  Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 50,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Account Created!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Welcome to Iron Chef',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Sign up function
  void signUpUser() async {
    if (_passwordController.text == _confirmPasswordController.text) {
      try {
        // Attempt to create user with Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Handle success: Show light purple overlay
        print('User signed up: ${userCredential.user?.email}');
        setState(() {
          _showSuccessOverlay = true;
        });

        // Navigate to the home screen after the overlay is shown (with a delay)
        Future.delayed(const Duration(seconds: 3), () {
          setState(() {
            _showSuccessOverlay = false;
          });
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => WillPopScope(
                // Wrap HomeScreen with WillPopScope
                onWillPop: () async {
                  // Override the back button behavior
                  exit(0); // Quit the app
                  return false; // Prevent default back button behavior
                },
                child: HomeScreen(), // Your Home Screen Widget
              ),
            ),
          );
        });
      } on FirebaseAuthException catch (e) {
        // Handle error: Show error message
        if (e.code == 'email-already-in-use') {
          _showErrorDialog(
            title: 'Email Already Exists',
            message: 'The email address is already in use by another account.',
          );
        } else {
          _showErrorDialog(
            title: 'Sign Up Error',
            message: 'Error creating account: ${e.message}',
          );
        }
        print("Error: ${e.message}");
      }
    } else {
      // Passwords do not match
      _showErrorDialog(
        title: 'Password Mismatch',
        message: 'Passwords do not match.',
      );
      print("Passwords do not match");
    }
  }

  // Function to show an error dialog
  void _showErrorDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF19006D), // Consistent with button color
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4169E1), // Style the button color
              ),
              child: const Text('OK'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // Rounded border
          ),
          backgroundColor: Colors.white, // Background color
        );
      },
    );
  }

  Widget _buildTextField({
    required String hintText,
    bool obscureText = false,
    bool isPasswordField = false,
    VoidCallback? onToggle,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        suffixIcon: isPasswordField
            ? IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: onToggle,
        )
            : null,
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.circular(15),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      style: const TextStyle(fontSize: 18),
    );
  }
}

