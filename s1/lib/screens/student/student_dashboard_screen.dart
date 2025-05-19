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
                // Navigate to notifications
              },
            ),
          ),
          /*IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/student/profile');
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              // Navigate to chat support
            },
          ),*/
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.secondary,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
              style: const TextStyle(color: AppColors.white),
            ),
          ),
          const SizedBox(width: 16),
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
                    onTap: () {
                      // Navigate to reserved rooms
                    },
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
      // New bottomNAvigationBar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // You can later make this dynamic if needed
        onTap: (index) {
          if (index == 0) return; // Already on Home
          if (index == 1) context.push('/student/chat'); // Chat screen
          if (index == 2) {
            context.push('/student/profile'); // Settings/Profile screen
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
  // Old bottomNavigationBar
  /* bottomNavigationBar: BottomNavigationBar(
  currentIndex: 0, // You can later make this dynamic if needed
  onTap: (index) {
    if (index == 0) return; // Already on Home
    if (index == 1) context.push('/student/chat');     // Chat screen
    if (index == 2) context.push('/student/profile');  // Settings/Profile screen
  },
  items: const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
  ],
),
 */

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
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('• $content', style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
