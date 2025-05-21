import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

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
                                      user.profilePictureUrl!,
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
                                _buildActionButton(
                                  'Edit Profile',
                                  Icons.edit,
                                  isLoading
                                      ? null
                                      : () => context.push('/edit-profile'),
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
                                        // TODO: Navigate to notifications settings
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
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 0, // Change this per screen
            onTap: (index) {
              if (index == 0) context.go('/student');
              if (index == 1) context.go('/student/chat');
              if (index == 2) context.go('/student/profile');
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
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(text, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
