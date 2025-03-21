import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsiveness
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.deepOrange, // Customize as needed
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Responsive Welcome Text
            Text(
              'Welcome to AIron Chef!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.07, // 7% of screen width
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenHeight * 0.02), // Spacing

            // Responsive Image (Optional)
            Image.asset(
              'assets/chef_icon.png', // Replace with your image
              width: screenWidth * 0.5,
              height: screenHeight * 0.3,
              fit: BoxFit.contain,
            ),
            SizedBox(height: screenHeight * 0.03), // Spacing

            // Get Started Button
            ElevatedButton(
              onPressed: () {
                // You can later navigate to another page here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.1,
                  vertical: screenHeight * 0.02,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Get Started',
                style: TextStyle(
                  fontSize: screenWidth * 0.05, // 5% of screen width
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
