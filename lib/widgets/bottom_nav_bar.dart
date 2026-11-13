import 'package:flutter/material.dart';
import '../screens/wardrobe_dashboard.dart';
import '../screens/favorites_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/notification_screen.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final String email;
  final List<Map<String, dynamic>>? notifications;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.email,
    this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavBarItem(context, Icons.home, 0),
              _buildNavBarItem(context, Icons.favorite, 1),
              _buildNavBarItem(context, Icons.calendar_today, 2),
              _buildNavBarItem(context, Icons.notifications, 3),
              _buildNavBarItem(context, Icons.person, 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem(BuildContext context, IconData icon, int index) {
    return GestureDetector(
      onTap: () => _handleNavigation(context, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selectedIndex == index
              ? const Color(0xFFFFE4E1) // Light peach color
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: selectedIndex == index ? const Color(0xFFA4D3A0) : Colors.grey,
          size: 24,
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    if (index == selectedIndex) return;

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WardrobeDashboard(email: email),
        ),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FavoritesScreen(email: email),
        ),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CalendarScreen(email: email),
        ),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationScreen(
            email: email,
          ),
        ),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(email: email),
        ),
      );
    }
    // Add other navigation cases as needed
  }
}
