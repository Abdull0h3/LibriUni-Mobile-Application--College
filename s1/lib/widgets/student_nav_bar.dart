import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudentNavBar extends StatelessWidget {
  final int currentIndex;
  final BuildContext context;

  const StudentNavBar({
    Key? key,
    required this.currentIndex,
    required this.context,
  }) : super(key: key);

  void _onDestinationSelected(int index) {
    switch (index) {
      case 0:
        if ((GoRouterState.of(context).fullPath ?? '/student') != '/student') {
          context.go('/student');
        }
        break;
      case 1:
        context.go('/student/ai-chat');
        break;
      case 2:
        context.go('/student/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedIconColor = isDark ? const Color(0xFFF4B400) : const Color(0xFF1A365D);
    final unselectedIconColor = isDark ? Colors.white : const Color(0xFF1A365D);
    final selectedIconInnerColor = isDark ? const Color(0xFF1A365D) : Colors.white;
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: _onDestinationSelected,
      indicatorColor: selectedIconColor,
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.home_outlined, color: unselectedIconColor),
          selectedIcon: Icon(Icons.home, color: selectedIconInnerColor),
          label: 'Home',
        ),
        NavigationDestination(
          tooltip: 'Chat with Library Staff',
          icon: Icon(Icons.support_agent_outlined, color: unselectedIconColor),
          selectedIcon: Icon(Icons.support_agent, color: selectedIconInnerColor),
          label: 'Staff Help',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined, color: unselectedIconColor),
          selectedIcon: Icon(Icons.settings, color: selectedIconInnerColor),
          label: 'Settings',
        ),
      ],
    );
  }
}
