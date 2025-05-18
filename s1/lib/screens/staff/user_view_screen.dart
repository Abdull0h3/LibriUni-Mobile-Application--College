import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../models/user.dart';

class UserViewScreen extends StatefulWidget {
  const UserViewScreen({Key? key}) : super(key: key);

  @override
  State<UserViewScreen> createState() => _UserViewScreenState();
}

class _UserViewScreenState extends State<UserViewScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  List<String> _userTypes = ['All', 'Students', 'Staff', 'Admin'];
  String _selectedUserType = 'All';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.fetchUsers();

    setState(() {
      _isLoading = false;
    });
  }

  void _searchUsers(String query) {
    setState(() {
      _searchQuery = query;
    });
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.searchUsers(query);
  }

  void _filterByUserType(String userType) {
    setState(() {
      _selectedUserType = userType;
    });
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userType == 'All') {
      userProvider.filterByRole(null);
    } else {
      // Convert string to UserRole
      UserRole role;
      switch (userType.toLowerCase()) {
        case 'students':
          role = UserRole.student;
          break;
        case 'staff':
          role = UserRole.staff;
          break;
        case 'admin':
          role = UserRole.admin;
          break;
        default:
          role = UserRole.student;
      }
      userProvider.filterByRole(role);
    }
  }

  void _viewUserDetails(User user) {
    // Navigate to user details screen or show a dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('${user.name}\'s Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Email', user.email),
                const SizedBox(height: 8),
                _buildInfoRow('Role', user.role.capitalize()),
                const SizedBox(height: 8),
                _buildInfoRow('Student ID', user.studentId ?? 'N/A'),
                const SizedBox(height: 8),
                _buildInfoRow('Department', user.department ?? 'N/A'),
                const SizedBox(height: 8),
                _buildInfoRow('Phone', user.phone ?? 'N/A'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to user's borrowed books
                },
                child: const Text('View Borrowed Books'),
              ),
            ],
          ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        Text(value),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final users = userProvider.filteredUsers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Users'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchUsers('');
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _searchUsers,
            ),
          ),
          // User type filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _userTypes.length,
              itemBuilder: (context, index) {
                final userType = _userTypes[index];
                final isSelected = _selectedUserType == userType;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(userType),
                    selected: isSelected,
                    onSelected: (_) => _filterByUserType(userType),
                    backgroundColor: AppColors.lightGray,
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color:
                          isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          // User list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : users.isEmpty
                    ? const Center(child: Text('No users found'))
                    : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(
                                0.2,
                              ),
                              child: Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(user.name),
                            subtitle: Text(user.email),
                            trailing: Chip(
                              label: Text(
                                user.role?.capitalize() ?? 'User',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                              backgroundColor: AppColors.primary.withOpacity(
                                0.1,
                              ),
                            ),
                            onTap: () => _viewUserDetails(user),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
