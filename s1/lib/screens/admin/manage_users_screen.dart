import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../models/user.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({Key? key}) : super(key: key);

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
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
      userProvider.clearFilters();
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

  void _addNewUser() {
    // Navigate to add user screen
    context.push('/admin/users/add');
  }

  void _editUser(User user) {
    // Navigate to add user screen with user parameter
    context.push('/admin/users/add', extra: user);
  }

  void _deleteUser(User user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete User'),
            content: Text('Are you sure you want to delete "${user.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final userProvider = Provider.of<UserProvider>(
                    context,
                    listen: false,
                  );
                  await userProvider.deleteUser(user.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User deleted successfully')),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  String _getUserRoleText(UserRole role) {
    return role.capitalize();
  }

  Color _getUserRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppColors.error;
      case UserRole.staff:
        return AppColors.warning;
      case UserRole.student:
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final users = userProvider.filteredUsers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
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
                          margin: const EdgeInsets.only(bottom: 16.0),
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
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getUserRoleColor(
                                      user.role,
                                    ).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getUserRoleText(user.role),
                                    style: TextStyle(
                                      color: _getUserRoleColor(user.role),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editUser(user),
                                  color: AppColors.primary,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteUser(user),
                                  color: AppColors.error,
                                ),
                              ],
                            ),
                            onTap: () => _editUser(user),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewUser,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
