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
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: _onDestinationSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          tooltip: 'Chat with Library Staff',
          icon: Icon(Icons.support_agent_outlined),
          selectedIcon: Icon(Icons.support_agent),
          label: 'Staff Help',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}
