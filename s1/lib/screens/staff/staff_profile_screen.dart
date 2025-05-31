import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:s1/constants/app_colors.dart';
import 'package:s1/providers/auth_provider.dart'; // Ensure this path is correct

class StaffProfileScreen extends StatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  bool _isLoading = false;

  Future<void> _handleLogout(BuildContext context) async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isProcessingAuth) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final shouldLogout =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.primaryColor),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
          ) ??
          false;

      if (!shouldLogout) {
        setState(() => _isLoading = false);
        return;
      }

      await authProvider.signOut();

      if (mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            context.go('/login');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${e.toString()}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isLoading =
        _isLoading || authProvider.isLoading || authProvider.isProcessingAuth;

    // Fallback values if user is null, though ideally user should not be null here
    final String displayName = user?.name ?? 'Staff Member';
    final String displayEmail = user?.email ?? 'N/A';
    final String displayStaffId =
        user?.id ?? 'N/A'; // Assuming user.id is the staff ID
    final String displayPhone = user?.phone ?? 'N/A';
    final String? profilePictureUrl = user?.profilePictureUrl;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.backgroundColor, // Light Grey
          appBar: AppBar(
            title: const Text(
              'Staff Profile',
              style: TextStyle(color: AppColors.textColorLight),
            ),
            backgroundColor: AppColors.primaryColor, // Dark Blue
            iconTheme: const IconThemeData(color: AppColors.textColorLight),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: isLoading ? null : () => context.pop(),
            ),
          ),
          body:
              user == null
                  ? const Center(child: Text('Loading profile...'))
                  : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        const SizedBox(height: 20),
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.secondaryColor.withOpacity(
                            0.3,
                          ), // Yellow accent
                          backgroundImage:
                              profilePictureUrl != null &&
                                      profilePictureUrl.isNotEmpty
                                  ? NetworkImage(profilePictureUrl)
                                  : null,
                          child:
                              (profilePictureUrl == null ||
                                      profilePictureUrl.isEmpty)
                                  ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: AppColors.primaryColor,
                                  )
                                  : null,
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColorDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              displayEmail,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary, // Medium Gray
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor, // Dark Blue
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Staff', // Role badge
                                style: TextStyle(
                                  color: AppColors.textColorLight, // White
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32.0),
                        Card(
                          color: AppColors.cardBackgroundColor, // White
                          elevation: 2.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: <Widget>[
                                _buildInfoRow(
                                  icon: Icons.badge_outlined,
                                  label: 'Staff ID',
                                  value: displayStaffId,
                                ),
                                const Divider(color: AppColors.lightGray),
                                _buildInfoRow(
                                  icon: Icons.phone_outlined,
                                  label: 'Phone',
                                  value: displayPhone,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24.0),
                        Card(
                          color: AppColors.cardBackgroundColor, // White
                          elevation: 2.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
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
                                    color: AppColors.textColorDark,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildActionButton(
                                  text: 'Edit Profile',
                                  icon: Icons.edit_outlined,
                                  onTap:
                                      isLoading
                                          ? null
                                          : () {
                                            context.push('/edit-profile');
                                            // Consider refreshing data on return if needed:
                                            // .then((_) => authProvider.initializeUser());
                                          },
                                ),
                                _buildActionButton(
                                  text: 'Change Password',
                                  icon: Icons.lock_outline,
                                  onTap:
                                      isLoading
                                          ? null
                                          : () {
                                            context.push('/change-password');
                                          },
                                ),
                                _buildActionButton(
                                  text: 'Logout',
                                  icon: Icons.logout_outlined,
                                  color: AppColors.error, // Red for logout
                                  onTap:
                                      isLoading
                                          ? null
                                          : () => _handleLogout(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
        ),
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.secondaryColor),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            icon,
            color: AppColors.primaryColor,
            size: 22.0,
          ), // Dark Blue icon
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary, // Medium Gray
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textColorDark, // Very Dark Blue/Black
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required VoidCallback? onTap,
    Color color = AppColors.textColorDark, // Default to textColorDark
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color:
            color == AppColors.error ? AppColors.error : AppColors.primaryColor,
      ), // Use primaryColor for icons unless it's an error action
      title: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: 4.0,
      ),
    );
  }
}
