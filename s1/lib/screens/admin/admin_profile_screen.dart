import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({Key? key}) : super(key: key);

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
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
            elevation: 0,
            backgroundColor: AppColors.primary,
            title: const Text(
              'Admin Profile',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: isLoading ? null : () => context.pop(),
            ),
          ),
          body:
              user == null
                  ? const Center(
                    child: Text('Please login to view your profile'),
                  )
                  : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white, Colors.grey[50]!],
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 24),
                          // Profile picture
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
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
                          ),
                          const SizedBox(height: 16),
                          // User name
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // User email and role badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                user.email,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Text(
                                  'Admin',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          // Admin info card
                          _buildInfoCard(
                            title: 'Admin Information',
                            children: [
                              _buildInfoRow('ID', user.id ?? 'Not available'),
                              const Divider(color: Colors.grey),
                              _buildInfoRow(
                                'Phone',
                                user.phone ?? 'Not available',
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Account settings card
                          _buildInfoCard(
                            title: 'Account Settings',
                            children: [
                              _buildActionButton(
                                'Change Password',
                                Icons.lock,
                                isLoading
                                    ? null
                                    : () => context.push('/change-password'),
                              ),
                              _buildActionButton(
                                'Update Profile',
                                Icons.edit,
                                isLoading
                                    ? null
                                    : () => context.push('/edit-profile'),
                              ),
                              _buildActionButton(
                                'Logout',
                                Icons.logout,
                                isLoading ? null : () => _handleLogout(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
        ),
        if (isLoading)
          const Opacity(
            opacity: 0.6,
            child: ModalBarrier(dismissible: false, color: Colors.black),
          ),
        if (isLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (onTap != null) // Show arrow only if action is enabled
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondary,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
