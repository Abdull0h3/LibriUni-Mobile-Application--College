// Made by Faisal: Updated for dark mode support and unified navigation bar for student dashboard.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../staff/news_and_events_screen.dart';
import '../staff/news_item_detail_screen.dart';
import '../../widgets/student_nav_bar.dart';

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
                // Navigate to news and events list when notification icon is pressed
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NewsAndEventsScreen(),
                  ),
                );
              },
            ),
          ),
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.secondary,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                style: const TextStyle(color: AppColors.white),
              ),
            ),
            offset: const Offset(0, 40),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  context.push('/student/profile');
                  break;
                case 'logout':
                  authProvider.signOut();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline),
                        SizedBox(width: 8),
                        Text('Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              onTap: () => context.push('/student/reminders'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: StudentNavBar(currentIndex: _currentIndex, context: context),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: isDark ? AppColors.yellow : AppColors.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.white : AppColors.textPrimary,
              ),
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
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: ListTile(
        leading: Icon(icon, color: isDark ? AppColors.yellow : color),
        title: Text(title, style: TextStyle(color: isDark ? AppColors.white : AppColors.textPrimary)),
        subtitle: Text(content, style: TextStyle(color: isDark ? AppColors.white : AppColors.textSecondary)),
        trailing: Icon(Icons.chevron_right, color: isDark ? AppColors.white : AppColors.textPrimary),
        onTap: onTap,
      ),
    );
  }

  // Example function to navigate to a specific news item detail (call this from notification tap if you have newsItem)
  void _openNewsItemDetail(BuildContext context, dynamic newsItem) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewsItemDetailScreen(newsItem: newsItem),
      ),
    );
  }
}
