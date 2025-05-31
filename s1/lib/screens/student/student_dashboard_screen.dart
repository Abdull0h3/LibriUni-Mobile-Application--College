import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch notifications for the current user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        Provider.of<NotificationProvider>(
          context,
          listen: false,
        ).fetchNotifications(authProvider.user!.id);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update current index based on route
    final String path = GoRouterState.of(context).fullPath ?? '/student';
    if (path.startsWith('/student/ai-chat')) {
      setState(() => _currentIndex = 1);
    } else if (path.startsWith('/student/profile')) {
      setState(() => _currentIndex = 2);
    } else {
      setState(() => _currentIndex = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.user?.name ?? 'Student';
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final unreadCount = notificationProvider.getUnreadCount();

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $userName'),
        actions: [
          Badge(
            label: Text(unreadCount.toString()),
            isLabelVisible: unreadCount > 0,
            child: IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                context.push('/student/notifications');
              },
            ),
          ),
          // Replaced PopupMenuButton with IconButton for direct navigation
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.secondary, // Assuming AppColors.secondary is defined
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                style: const TextStyle(color: AppColors.white), // Assuming AppColors.white is defined
              ),
            ),
            tooltip: 'Profile Settings', // Added tooltip for clarity
            onPressed: () {
              context.push('/student/profile'); // Navigate directly to profile
            },
          ),
          const SizedBox(width: 16), // Keep consistent spacing
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search books, journals, or rooms...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildDashboardCard(
                    icon: Icons.book,
                    title: 'Search Books',
                    onTap: () => context.push('/student/books'),
                  ),
                  _buildDashboardCard(
                    icon: Icons.event_available,
                    title: 'Reserve Room',
                    onTap: () => context.push('/student/rooms'),
                  ),
                  _buildDashboardCard(
                    icon: Icons.bookmark,
                    title: 'My Borrowed Books',
                    onTap: () => context.push('/student/borrowed'),
                  ),
                  _buildDashboardCard(
                    icon: Icons.room,
                    title: 'My Reserved Rooms',
                    onTap: () => context.push('/student/reserved-rooms'),
                  ),
                ],
              ),
            ),
            _buildInfoCard(
              icon: Icons.timer,
              title: 'Reminders',
              content: '2 books due in 3 days',
              color: AppColors.warning,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.announcement,
              title: 'Announcements',
              content: 'Discussion room renovation notice',
              color: AppColors.info,
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          // setState(() => _currentIndex = index); // Handled by didChangeDependencies on route change
          switch (index) {
            case 0:
              // Only navigate if not already on the base student dashboard
              if ((GoRouterState.of(context).fullPath ?? '/student') != '/student') {
                context.go('/student');
              }
              break;
            case 1:
              final user = authProvider.user;
              if (user != null) {
                // Check if already on the chat screen to avoid pushing multiple times if desired
                // For now, it pushes, which is fine.
                context.push(
                  '/student/chat',
                  extra: {'studentId': user.id, 'studentName': user.name},
                );
              }
              break;
            case 2:
              // Only navigate if not already on the profile screen
              if (! (GoRouterState.of(context).fullPath?.startsWith('/student/profile') ?? false) ) {
                context.go('/student/profile');
              }
              break;
          }
        },
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
      ),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(content),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
