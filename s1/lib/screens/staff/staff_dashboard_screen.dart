// lib/screens/staff_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../services/chat_service.dart';
import '../../screens/staff/staff_profile_screen.dart';

class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.user?.name ?? 'Staff';
    final staffId = authProvider.user?.id ?? '';

    // Define all dashboard items, including Scan QR
    final List<DashboardItem> dashboardItems = [
      DashboardItem(
        icon: Icons.menu_book,
        title: 'Search Catalog',
        onTap: () => context.push('/staff/search-catalog'),
      ),
      DashboardItem(
        icon: Icons.people,
        title: 'View Users',
        onTap: () => context.push('/staff/view-users'),
      ),
      DashboardItem(
        icon: Icons.collections_bookmark,
        title: 'Borrowed Items',
        onTap: () => context.push('/staff/borrowed-items'),
      ),
      DashboardItem(
        icon: Icons.event_available,
        title: 'Reserved Rooms',
        onTap: () => context.push('/staff/reserved-rooms'),
      ),
      // DashboardItem( // Removed Manage Books
      //   icon: Icons.rule_folder_outlined,
      //   title: 'Manage Books',
      //   onTap: () => context.push('/staff/manage-books'),
      // ),
      DashboardItem(
        icon: Icons.attach_money,
        title: 'Manage Fines',
        onTap: () => context.push('/staff/manage-fines'),
      ),
      DashboardItem(
        icon: Icons.campaign,
        title: 'News & Events',
        onTap: () => context.push('/staff/news-events'),
      ),
      // DashboardItem(icon: Icons.assignment_return, title: 'Checked-In Returns', onTap: () => Navigator.pushNamed(context, AppRoutes.checkedInReturns)),
      DashboardItem( // Scan QR / Check-In is now the last item in this list
        icon: Icons.qr_code_scanner,
        title: 'Scan QR / Check-In',
        onTap: () => context.push('/staff/scan-qr'),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SizedBox(
              height: 35,
              child: Image.asset(
                AppConstants.libriUniLogoPath, // Using from app_colors.dart
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Text(
                    'LibriUni',
                    style: TextStyle(
                      color: AppColors.textColorLight,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          // Message Icon
          StreamBuilder<int>(
            stream:
                staffId.isNotEmpty
                    ? ChatService().getTotalUnreadMessageCount(staffId)
                    : null,
            builder: (context, snapshot) {
              final totalUnreadCount = snapshot.data ?? 0;
              return IconButton(
                // Show a different icon if there are unread messages
                icon: Icon(
                  totalUnreadCount > 0
                      ? Icons
                          .mark_email_unread // Icon with exclamation mark
                      : Icons.message_outlined, // Regular message icon
                  size: 24, // Standard icon size
                  color:
                      totalUnreadCount > 0
                          ? AppColors.secondaryColor
                          : Colors.white, // Highlight if unread
                ),
                tooltip: 'Student Chats',
                onPressed: () {
                  if (staffId.isNotEmpty) {
                    context.push(
                      '/staff/chat',
                      extra: {'staffId': staffId, 'staffName': userName},
                    );
                  }
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30),
            onPressed: () {
              context.push('/staff/profile'); // Navigate to staff profile screen
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double screenPadding = 12.0; // Matches the padding you'll use for the content
          final double crossAxisSpacing = 12.0;
          final double mainAxisSpacing = 12.0;
          final int crossAxisCount = 2;
          final double childAspectRatio = 1.2;

          // Calculate the width available for the grid content after screen padding
          final double availableWidthForGridContent = constraints.maxWidth - (2 * screenPadding);
          
          // Calculate the width of a single cell
          final double cellWidth = (availableWidthForGridContent - ((crossAxisCount - 1) * crossAxisSpacing)) / crossAxisCount;
          // Calculate the height of a single cell
          final double cellHeight = cellWidth / childAspectRatio;

          bool isLastItemSpecial = dashboardItems.length % 2 != 0;
          int gridItemCount = isLastItemSpecial ? dashboardItems.length - 1 : dashboardItems.length;

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(screenPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (gridItemCount > 0) // Only build GridView if there are items for it
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: gridItemCount,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: crossAxisSpacing,
                        mainAxisSpacing: mainAxisSpacing,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        final item = dashboardItems[index];
                        return DashboardGridItem(
                          icon: item.icon,
                          title: item.title,
                          onTap: item.onTap,
                        );
                      },
                    ),
                  if (isLastItemSpecial) ...[
                    if (gridItemCount > 0) // Add spacing only if GridView was built
                      SizedBox(height: mainAxisSpacing), // Mimic mainAxisSpacing
                    SizedBox(
                      width: double.infinity, // This will take the full width within the Padded Column
                      height: cellHeight,    // Match the height of other grid items
                      child: DashboardGridItem(
                        icon: dashboardItems.last.icon,
                        title: dashboardItems.last.title,
                        onTap: dashboardItems.last.onTap,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Helper class for dashboard item data (keep as is)
class DashboardItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  DashboardItem({required this.icon, required this.title, required this.onTap});
}

// Widget for each item in the grid (keep as is)
class DashboardGridItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const DashboardGridItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.secondaryColor.withOpacity(0.2),
        highlightColor: AppColors.secondaryColor.withOpacity(0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 40.0, color: AppColors.secondaryColor),
            const SizedBox(height: 12.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
