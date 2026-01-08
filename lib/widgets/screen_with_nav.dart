import 'package:flutter/material.dart';
import 'bottom_nav_bar.dart';
import '../screens/home/home_screen.dart';

/// Wrapper for screens that should show bottom navigation bar
/// Navigates back to HomeScreen when nav items are tapped
class ScreenWithNav extends StatelessWidget {
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final Widget? drawer;
  final int currentNavIndex;

  const ScreenWithNav({
    super.key,
    required this.body,
    required this.title,
    this.actions,
    this.drawer,
    this.currentNavIndex = 0,
  });

  void _handleNavTap(BuildContext context, int index) {
    // Navigate back to HomeScreen with the selected index
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomeScreen(initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: drawer,
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: body,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentNavIndex,
        onTap: (index) => _handleNavTap(context, index),
      ),
    );
  }
}

