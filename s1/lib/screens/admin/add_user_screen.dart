import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../models/user.dart';

class AddUserScreen extends StatefulWidget {
  final User? user; // Pass user for editing, null for adding
  const AddUserScreen({Key? key, this.user}) : super(key: key);

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _userIDController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  UserRole _selectedRole = UserRole.student;
  bool _isActive = true;
  bool _isLoading = false;

  // User from route extra
  User? _user;
  bool _didInitialize = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _populateFormIfEditing();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitialize) {
      final Object? extra = GoRouterState.of(context).extra;
      if (extra != null && extra is User && _user == null) {
        _user = extra;
        _populateFormIfEditing();
      }
      _didInitialize = true;
    }
  }

  void _populateFormIfEditing() {
    if (_user != null) {
      _nameController.text = _user!.name;
      _emailController.text = _user!.email;
      _phoneController.text = _user!.phone ?? '';
      _userIDController.text = _user!.userID ?? '';
      _departmentController.text = _user!.department ?? '';
      _selectedRole = _user!.role;
      _isActive = _user!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _userIDController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);

      String userID = _user?.userID ?? '';
      if (_user == null) {
        // Only generate a new userID for new users
        userID = await userProvider.getNextUserID(_selectedRole);
      }
      _userIDController.text = userID;

      final user = User(
        id: _user?.id ?? '', // Empty for new users, will be set by Firestore
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: _selectedRole,
        isActive: _isActive,
        phone:
            _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
        department:
            _departmentController.text.trim().isEmpty
                ? null
                : _departmentController.text.trim(),
        userID: _userIDController.text.trim(),
      );

      bool success;
      if (_user == null) {
        // Add new user
        success = await userProvider.addUser(user);
      } else {
        // Update existing user
        success = await userProvider.updateUser(user);
      }

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_user == null ? 'User added' : 'User updated'} successfully',
            ),
          ),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userProvider.error ??
                  'Failed to ${_user == null ? 'add' : 'update'} user',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_user == null ? 'Add New User' : 'Edit User'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter full name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter email address',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone (Optional)',
                  hintText: 'Enter phone number',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),
              // User ID (shown for all roles)
              TextFormField(
                controller: _userIDController,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'User ID',
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 16),
              // Role Selection
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UserRole>(
                    value: _selectedRole,
                    onChanged: (UserRole? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedRole = newValue;
                        });
                      }
                    },
                    items:
                        UserRole.values.map((UserRole role) {
                          return DropdownMenuItem<UserRole>(
                            value: role,
                            child: Text(role.capitalize()),
                          );
                        }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Department
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department (Optional)',
                  hintText: 'Enter department',
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),
              // Active status
              Row(
                children: [
                  const Text('Active Account'),
                  const Spacer(),
                  Switch(
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Submit button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveUser,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                          _user == null ? 'Add User' : 'Update User',
                          style: const TextStyle(fontSize: 16),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
