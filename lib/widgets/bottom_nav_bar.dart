import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../utils/localization_extension.dart';

/// Shared Bottom Navigation Bar Component
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primaryBlue,
      unselectedItemColor: AppTheme.darkGray,
      backgroundColor: AppTheme.white,
      elevation: 8,
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ),
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home_rounded),
          label: context.tr('home'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.history_outlined),
          activeIcon: const Icon(Icons.history_rounded),
          label: context.tr('history'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.payments_outlined),
          activeIcon: const Icon(Icons.payments_rounded),
          label: context.tr('payments'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.inventory_2_outlined),
          activeIcon: const Icon(Icons.inventory_2_rounded),
          label: context.tr('inventory'),
        ),
      ],
    );
  }
}

