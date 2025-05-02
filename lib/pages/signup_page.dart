import 'dart:io';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Cloud Firestore
import './home.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showSuccessOverlay = false;

  // Error messages for each field
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  // Reference to the Firestore collection
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  final FirebaseAuth _auth = FirebaseAuth.instance; // Add FirebaseAuth instance

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
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
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildTextField(
                          hintText: 'Email',
                          controller: _emailController,
                          errorText: _emailError,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          hintText: 'Full Name',
                          controller: _nameController,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          hintText: 'Password',
                          obscureText: _obscurePassword,
                          isPasswordField: true,
                          controller: _passwordController,
                          errorText: _passwordError,
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
                          errorText: _confirmPasswordError,
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
                            const Text("Have an account? ", style: TextStyle(fontSize: 16)),
                            GestureDetector(
                              onTap: () {
                                //  Navigate to login page.
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(), // Use the LoginPage
                                  ),
                                );
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
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WillPopScope(
                                  onWillPop: () async {
                                    exit(0);
                                  },
                                  child: const HomeScreen(),
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(),
                          child: const Text(
                            'Continue as Guest',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              decoration: TextDecoration.underline,
                            ),
                          ),
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
                Image.asset('assets/signupImg.png', height: 120),
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
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 50, color: Colors.white),
                      SizedBox(height: 10),
                      Text(
                        'Account Created!',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Welcome to Iron Chef',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // "Continue as Guest" positioned below the blurred area
          // Removed this positioned widget
        ],
      ),
    );
  }

  // Sign up function
  void signUpUser() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _confirmPasswordError = 'Passwords do not match.';
      });
      return;
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword( // Use the FirebaseAuth instance
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Add user data to Firestore
      await _usersCollection.doc(userCredential.user!.uid).set({
        'email': _emailController.text.trim(),
        'fullName': _nameController.text.trim(),
        // Add other user data here as needed
      });


      print('User signed up: ${userCredential.user?.email}');
      setState(() {
        _showSuccessOverlay = true;
      });

      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          _showSuccessOverlay = false;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WillPopScope(
              onWillPop: () async {
                exit(0);
              },
              child: const HomeScreen(),
            ),
          ),
        );
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        setState(() {
          _emailError = 'The email is already in use.';
        });
      } else if (e.code == 'invalid-email') {
        setState(() {
          _emailError = 'Please enter a valid email.';
        });
      } else if (e.code == 'weak-password') {
        setState(() {
          _passwordError = 'Password is too weak.';
        });
      } else {
        setState(() {
          _emailError = 'Error: ${e.message}';
        });
      }
    } catch (e) {
      // Handle other potential errors, such as Firestore errors.
      print("Error saving to Firestore: $e");
      setState(() {
        _emailError = 'An error occurred during sign up.'; // A more generic error for the user
      });
    }
  }

  Widget _buildTextField({
    required String hintText,
    required TextEditingController controller,
    bool obscureText = false,
    bool isPasswordField = false,
    String? errorText,
    VoidCallback? onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
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
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          style: const TextStyle(fontSize: 18),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
      ],
    );
  }
}

