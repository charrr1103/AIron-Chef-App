import 'dart:ui';
import 'package:flutter/material.dart';
import './home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Page',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;

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
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildTextField(hintText: 'Username or Email'),
                        const SizedBox(height: 16),
                        _buildTextField(
                          hintText: 'Password',
                          obscureText: _obscurePassword,
                          isPasswordField: true,
                          onToggle: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () {
                            // TODO: Implement login functionality
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF19006D),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Divider(
                                    color: Colors.white,
                                    thickness: 1,
                                    endIndent: 10,
                                  ),
                                ),
                                const Text(
                                  "OR Login with:",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(
                                    color: Colors.white,
                                    thickness: 0.9,
                                    indent: 10,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildSocialLoginButton('assets/socialmediaLogos/googleLogo.png'),
                                const SizedBox(width: 20),
                                _buildSocialLoginButton('assets/socialmediaLogos/facebookLogo.png'),
                              ],
                            ),
                          ],
                        ),


                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HomeScreen()),
                            );
                          },
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
                Image.asset(
                  'assets/loginImg.png',
                  height: 150,
                ),
                Transform.translate(
                  offset: const Offset(0, -20), // move the title upward by 10 pixels
                  child: const Text(
                    "Welcome Back!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontFamily: 'Batangas',
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    bool obscureText = false,
    bool isPasswordField = false,
    VoidCallback? onToggle,
  }) {
    return TextField(
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

  Widget _buildSocialLoginButton(String assetPath) {
    return InkWell(
      onTap: () {
        // TODO: Handle social login click
      },
      child: Container(
        width: 50,
        height: 50,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: Image.asset(assetPath),
      ),
    );
  }

}
