import 'package:flutter/material.dart';
import 'bottom_nav_bar.dart';
import '../screens/home/home_screen.dart';

class ScreenWithNav extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? drawer;
  final int currentNavIndex;
  final List<Widget>? actions;

  const ScreenWithNav({
    super.key,
    required this.title,
    required this.body,
    this.drawer,
    required this.currentNavIndex,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      drawer: drawer,
      body: body,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentNavIndex,
        onTap: (index) {
          if (index != currentNavIndex) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(initialIndex: index),
              ),
            );
          }
        },
      ),
    );
  }
}
