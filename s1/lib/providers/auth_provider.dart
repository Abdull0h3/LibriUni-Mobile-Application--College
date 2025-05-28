import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';

class AuthProvider with ChangeNotifier {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _pendingRegistration =
      false; // Flag to track registration without auto-login
  bool _isProcessingAuthRequest =
      false; // Flag to prevent duplicate auth requests

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.role == UserRole.admin;
  bool get isStaff =>
      _user?.role == UserRole.staff || _user?.role == UserRole.admin;
  bool get isStudent => _user?.role == UserRole.student;
  bool get hasPendingRegistration => _pendingRegistration;
  bool get isProcessingAuth => _isProcessingAuthRequest;

  // Initialize user on app startup
  Future<void> initializeUser() async {
    final auth.User? firebaseUser = _firebaseAuth.currentUser;

    if (firebaseUser != null) {
      try {
        await _fetchUserData(firebaseUser.uid);
      } catch (e) {
        _error = e.toString();
      }
    }
    notifyListeners();
  }

  // Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    // Prevent multiple simultaneous sign-in attempts
    if (_isProcessingAuthRequest) return false;

    try {
      _isProcessingAuthRequest = true;
      _isLoading = true;
      _error = null;
      _pendingRegistration = false;
      notifyListeners();

      // Set timeout for Firebase operations
      final auth.UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Login timed out. Please check your internet connection.',
              );
            },
          );

      if (userCredential.user != null) {
        await _fetchUserData(userCredential.user!.uid);
        _isLoading = false;
        _isProcessingAuthRequest = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      _isProcessingAuthRequest = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _isProcessingAuthRequest = false;
      _error = _formatAuthError(e.toString());
      notifyListeners();
      return false;
    }
  }

  // Register new user without auto-login
  Future<bool> register(String email, String password, String name) async {
    // Prevent multiple simultaneous registration attempts
    if (_isProcessingAuthRequest) return false;

    try {
      _isProcessingAuthRequest = true;
      _isLoading = true;
      _error = null;
      _pendingRegistration = true;
      notifyListeners();

      final auth.UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Registration timed out. Please check your internet connection.',
              );
            },
          );

      if (userCredential.user != null) {
        // Generate custom userID for student
        final userProvider = UserProvider();
        final userID = await userProvider.getNextUserID(UserRole.student);
        // Create user in Firestore
        final newUser = User(
          id: userCredential.user!.uid,
          name: name,
          email: email,
          role: UserRole.student, // Default role is student
          isActive: true,
          userID: userID,
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(newUser.toFirestore());

        // Important: Sign out after registration to prevent auto-login
        await _firebaseAuth.signOut();
        _pendingRegistration = false;
        _isLoading = false;
        _isProcessingAuthRequest = false;
        notifyListeners();
        return true;
      }

      _pendingRegistration = false;
      _isLoading = false;
      _isProcessingAuthRequest = false;
      notifyListeners();
      return false;
    } catch (e) {
      _pendingRegistration = false;
      _isLoading = false;
      _isProcessingAuthRequest = false;
      _error = _formatAuthError(e.toString());
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    // Prevent multiple simultaneous sign-out attempts
    if (_isProcessingAuthRequest) return;

    try {
      _isProcessingAuthRequest = true;
      _isLoading = true;
      notifyListeners();

      // Force immediate local sign-out to give immediate UI feedback
      final currentUser = _user;
      _user = null;
      notifyListeners();

      // Then perform the actual Firebase sign-out
      await _firebaseAuth.signOut().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception(
            'Signout timed out, but you have been logged out locally.',
          );
        },
      );

      _isLoading = false;
      _isProcessingAuthRequest = false;
      notifyListeners();
    } catch (e) {
      // Even if there's an error, ensure the user stays logged out locally
      _isLoading = false;
      _isProcessingAuthRequest = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData(String uid) async {
    try {
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception(
                'Fetching user data timed out. Please check your internet connection.',
              );
            },
          );

      if (userDoc.exists) {
        _user = User.fromFirestore(userDoc);
      } else {
        _error = 'User data not found';
      }
    } catch (e) {
      _error = e.toString();
      throw e;
    }
  }

  // Format auth errors to be more user-friendly
  String _formatAuthError(String errorMessage) {
    if (errorMessage.contains('user-not-found')) {
      return 'No user found with this email.';
    } else if (errorMessage.contains('wrong-password')) {
      return 'Incorrect password.';
    } else if (errorMessage.contains('email-already-in-use')) {
      return 'This email is already registered.';
    } else if (errorMessage.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorMessage.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later.';
    } else if (errorMessage.contains('timed out')) {
      return errorMessage;
    }
    return errorMessage;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Update user profile
  Future<bool> updateProfile(User updatedUser) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Update user in Firestore
      await _firestore
          .collection('users')
          .doc(updatedUser.id)
          .update(updatedUser.toFirestore());

      // Update local user state
      _user = updatedUser;
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

  // Change password
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      // Reauthenticate user before changing password
      final credential = auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(newPassword);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = _formatAuthError(e.toString());
      notifyListeners();
      return false;
    }
  }
}
