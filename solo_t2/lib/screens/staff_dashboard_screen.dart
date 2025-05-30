// lib/screens/staff_dashboard_screen.dart
import 'package:flutter/material.dart';
import '/constants/app_colors.dart';
import '/routes/app_router.dart'; // Import your AppRoutes

class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the dashboard items
    final List<DashboardItem> dashboardItems = [
      DashboardItem(icon: Icons.menu_book, title: 'Search Catalog', onTap: () => Navigator.pushNamed(context, AppRoutes.searchCatalog)),
      DashboardItem(icon: Icons.people, title: 'View Users', onTap: () => Navigator.pushNamed(context, AppRoutes.viewUsers)),
      DashboardItem(icon: Icons.collections_bookmark, title: 'Borrowed Items', onTap: () => Navigator.pushNamed(context, AppRoutes.borrowedItems)),
      DashboardItem(icon: Icons.event_available, title: 'Reserved Rooms', onTap: () => Navigator.pushNamed(context, AppRoutes.reservedRooms)),
      // Added Manage Books to the dashboard for direct access as per its wireframe being prominent
      DashboardItem(icon: Icons.rule_folder_outlined, title: 'Manage Books', onTap: () => Navigator.pushNamed(context, AppRoutes.manageBooks)),
      DashboardItem(icon: Icons.attach_money, title: 'Manage Fines', onTap: () => Navigator.pushNamed(context, AppRoutes.manageFines)),
      DashboardItem(icon: Icons.qr_code_scanner, title: 'Scan QR / Check-In', onTap: () => Navigator.pushNamed(context, AppRoutes.scanQr)), // Scan QR can handle check-ins
      DashboardItem(icon: Icons.campaign, title: 'News & Events', onTap: () => Navigator.pushNamed(context, AppRoutes.newsAndEvents)),
      // DashboardItem(icon: Icons.assignment_return, title: 'Checked-In Returns', onTap: () => Navigator.pushNamed(context, AppRoutes.checkedInReturns)),
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
                    style: TextStyle(color: AppColors.textColorLight, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('User Profile'),
                  content: const Text('Welcome, Staff Member! \n(Profile page coming soon)'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search books, users, or rooms...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryColor),
                filled: true,
                fillColor: AppColors.cardBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: const BorderSide(color: AppColors.secondaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
              ),
              onChanged: (value) {
                print('Dashboard Search query: $value');
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: GridView.builder(
                itemCount: dashboardItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 1.2,
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
            ),
          ),
        ],
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}