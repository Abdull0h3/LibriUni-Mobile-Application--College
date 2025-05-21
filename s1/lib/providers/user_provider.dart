import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'dart:math';

class UserAddResult {
  final bool success;
  final String? error;
  UserAddResult({required this.success, this.error});
}

class UserProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  UserRole? _roleFilter;

  // Getters
  List<User> get users => _users;
  List<User> get filteredUsers => _filteredUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  UserRole? get roleFilter => _roleFilter;

  // Fetch all users
  Future<void> fetchUsers() async {
    try {
      _isLoading = true;
      notifyListeners();

      final QuerySnapshot snapshot =
          await _firestore.collection(_collection).get();
      _users = snapshot.docs.map((doc) => User.fromFirestore(doc)).toList();
      _applyFilters();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Search users by name or email
  void searchUsers(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Filter users by role
  void filterByRole(UserRole? role) {
    _roleFilter = role;
    _applyFilters();
    notifyListeners();
  }

  // Add a new user
  Future<UserAddResult> addUser(User user, {required String password}) async {
    try {
      _isLoading = true;
      notifyListeners();
      final QuerySnapshot existingUserQuery =
          await _firestore
              .collection(_collection)
              .where('email', isEqualTo: user.email)
              .get();
      if (existingUserQuery.docs.isNotEmpty) {
        _error = 'A user with this email already exists';
        _isLoading = false;
        notifyListeners();
        return UserAddResult(success: false, error: _error);
      }
      final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
      final auth.UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: user.email, password: password)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'User creation timed out. Please check your internet connection.',
              );
            },
          );
      if (userCredential.user == null) {
        throw Exception('Failed to create authentication account');
      }
      final String userID = await getNextUserID(user.role);
      final userData = user.toFirestore();
      userData['userID'] = userID;
      await _firestore
          .collection(_collection)
          .doc(userCredential.user!.uid)
          .set(userData);
      final newUser = user.copyWith(
        id: userCredential.user!.uid,
        userID: userID,
      );
      _users.add(newUser);
      _applyFilters();
      _isLoading = false;
      notifyListeners();
      return UserAddResult(success: true);
    } on auth.FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = _formatAuthError(e.message ?? 'Authentication error occurred');
      notifyListeners();
      return UserAddResult(success: false, error: _error);
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return UserAddResult(success: false, error: _error);
    }
  }

  // Generate a secure random password
  String _generateSecurePassword() {
    const String chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
    final random = Random.secure();
    return List.generate(
      12,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // Format Firebase Auth error messages
  String _formatAuthError(String error) {
    if (error.contains('email-already-in-use')) {
      return 'This email is already registered';
    } else if (error.contains('invalid-email')) {
      return 'Invalid email address';
    } else if (error.contains('weak-password')) {
      return 'Password is too weak';
    } else if (error.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection';
    } else {
      return 'An error occurred: $error';
    }
  }

  // Update a user
  Future<bool> updateUser(User user) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore
          .collection(_collection)
          .doc(user.id)
          .update(user.toFirestore());

      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = user;
        _applyFilters();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Disable a user
  Future<bool> disableUser(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection(_collection).doc(userId).update({
        'isActive': false,
      });

      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = _users[index].copyWith(isActive: false);
        _applyFilters();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Enable a user
  Future<bool> enableUser(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection(_collection).doc(userId).update({
        'isActive': true,
      });

      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = _users[index].copyWith(isActive: true);
        _applyFilters();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete a user
  Future<bool> deleteUser(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection(_collection).doc(userId).delete();

      _users.removeWhere((user) => user.id == userId);
      _applyFilters();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Change user role
  Future<bool> changeUserRole(String userId, UserRole newRole) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection(_collection).doc(userId).update({
        'role': newRole.name,
      });

      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = _users[index].copyWith(role: newRole);
        _applyFilters();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Apply all filters to users
  void _applyFilters() {
    if (_searchQuery.isEmpty && _roleFilter == null) {
      _filteredUsers = List.from(_users);
      return;
    }

    _filteredUsers =
        _users.where((user) {
          // Filter by role if selected
          if (_roleFilter != null && user.role != _roleFilter) {
            return false;
          }

          // Filter by search query if provided
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            return user.name.toLowerCase().startsWith(query) ||
                user.email.toLowerCase().startsWith(query);
          }

          return true;
        }).toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear all filters and search
  void clearFilters() {
    _roleFilter = null;
    _searchQuery = '';
    _filteredUsers = List.from(_users);
    notifyListeners();
  }

  // Generate the next userID for a given role
  Future<String> getNextUserID(UserRole role) async {
    String prefix;
    switch (role) {
      case UserRole.admin:
        prefix = 'AD';
        break;
      case UserRole.staff:
        prefix = 'STA';
        break;
      case UserRole.student:
      default:
        prefix = 'STU';
        break;
    }
    final query =
        await _firestore
            .collection(_collection)
            .where('role', isEqualTo: role.name)
            .where('userID', isGreaterThanOrEqualTo: prefix)
            .orderBy('userID', descending: true)
            .limit(1)
            .get();
    if (query.docs.isNotEmpty) {
      final lastUserID = query.docs.first['userID'] as String?;
      if (lastUserID != null && lastUserID.startsWith(prefix)) {
        final number =
            int.tryParse(lastUserID.replaceAll(RegExp(r'\D'), '')) ?? 0;
        return '$prefix${(number + 1).toString().padLeft(2, '0')}';
      }
    }
    return '${prefix}01';
  }
}
