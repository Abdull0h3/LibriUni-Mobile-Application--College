import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

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
  Future<bool> addUser(User user) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if a user with the same email already exists
      final QuerySnapshot existingUserQuery =
          await _firestore
              .collection(_collection)
              .where('email', isEqualTo: user.email)
              .get();

      if (existingUserQuery.docs.isNotEmpty) {
        _error = 'A user with this email already exists';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Add the new user
      final DocumentReference docRef = await _firestore
          .collection(_collection)
          .add(user.toFirestore());

      final newUser = user.copyWith(id: docRef.id);
      _users.add(newUser);
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
            return user.name.toLowerCase().contains(query) ||
                user.email.toLowerCase().contains(query);
          }

          return true;
        }).toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
