import 'package:flutter/material.dart';
import '../widgets/gradient_text.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFAF3E0),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GradientText('ARdrobe'),
              SizedBox(height: 20),
              Text(
                'Main Screen - Coming Soon',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Poppins',
                  color: Color(0xFF4B4B4B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
