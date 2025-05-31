import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/student_nav_bar.dart';
import '../staff/news_and_events_screen.dart';
import '../../providers/theme_provider.dart';

// Made by Faisal: Updated for dark mode support and added theme toggle in student profile.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;

  Future<void> _handleLogout(BuildContext context) async {
    // Immediately set local loading state to prevent multiple clicks
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check if auth is already processing a request
    if (authProvider.isProcessingAuth) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Show a confirmation dialog
      final shouldLogout =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false, // Prevent dismissal by clicking outside
            builder:
                (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
          ) ??
          false;

      if (!shouldLogout) {
        setState(() => _isLoading = false);
        return;
      }

      // If confirmed, proceed with logout
      await authProvider.signOut();

      // Navigate after signOut has been called
      if (mounted) {
        // Delay slightly to allow state to update
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            context.go('/login');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isLoading = _isLoading || authProvider.isLoading;

    Future<void> navigateToEditProfile() async {
      await Navigator.of(context).pushNamed('/edit-profile');
      // Refresh user data after returning from edit profile
      if (user != null) {
        await authProvider.initializeUser();
      }
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
              ), // changed context.pop() to context.go()
              onPressed: isLoading ? null : () => context.go('/student'),
            ),
          ),
          body:
              user == null
                  ? const Center(
                    child: Text('Please login to view your profile'),
                  )
                  : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        // Profile picture
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child:
                              user.profilePictureUrl != null
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: Image.network(
                                      '${user.profilePictureUrl!}?v=${DateTime.now().millisecondsSinceEpoch}',
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: AppColors.primary,
                                        );
                                      },
                                    ),
                                  )
                                  : const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: AppColors.primary,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        // User name
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // User email
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Profile info card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  'User ID',
                                  user.userID ?? 'Not available',
                                ),
                                const Divider(),
                                _buildInfoRow(
                                  'Department',
                                  user.department ?? 'Not available',
                                ),
                                const Divider(),
                                _buildInfoRow(
                                  'Phone',
                                  user.phone ?? 'Not available',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Account actions
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Account Settings',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  leading: const Icon(Icons.edit),
                                  title: const Text('Edit Profile'),
                                  onTap:
                                      isLoading ? null : navigateToEditProfile,
                                ),
                                _buildActionButton(
                                  'Change Password',
                                  Icons.lock_outline,
                                  isLoading
                                      ? null
                                      : () => context.push('/change-password'),
                                ),
                                _buildActionButton(
                                  'Notifications',
                                  Icons.notifications_none,
                                  isLoading
                                      ? null
                                      : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => NewsAndEventsScreen(),
                                          ),
                                        );
                                      },
                                ),
                                // Dark mode toggle
                                Consumer<ThemeProvider>(
                                  builder: (context, themeProvider, _) {
                                    return SwitchListTile(
                                      title: const Text('Dark Mode'),
                                      secondary: Icon(
                                        themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                                        color: themeProvider.isDarkMode ? AppColors.warning : AppColors.primary,
                                      ),
                                      value: themeProvider.isDarkMode,
                                      onChanged: (value) {
                                        themeProvider.setDarkMode(value);
                                      },
                                    );
                                  },
                                ),
                                _buildActionButton(
                                  'Logout',
                                  Icons.logout,
                                  isLoading
                                      ? null
                                      : () => _handleLogout(context),
                                  color: AppColors.error,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          bottomNavigationBar: StudentNavBar(currentIndex: 2, context: context),
        ),
        // Loading overlay
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    VoidCallback? onTap, {
    Color color = AppColors.textPrimary,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLogout = color == AppColors.error;
    final iconColor = isLogout ? AppColors.error : (isDark ? AppColors.white : color);
    final textColor = isLogout ? AppColors.error : (isDark ? AppColors.white : color);
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(text, style: TextStyle(color: textColor)),
      trailing: Icon(Icons.chevron_right, color: textColor),
      onTap: onTap,
    );
  }
}
