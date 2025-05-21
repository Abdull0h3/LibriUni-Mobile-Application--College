import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum representing user roles in the application
enum UserRole { student, staff, admin }

/// Extension to convert UserRole to and from string values
extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.student:
        return 'student';
      case UserRole.staff:
        return 'staff';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return UserRole.student;
      case 'staff':
        return UserRole.staff;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.student;
    }
  }
}

extension UserRoleStringExtension on UserRole {
  String capitalize() {
    return name[0].toUpperCase() + name.substring(1);
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;
  final String? photoUrl;
  final String? phoneNumber;

  // Additional fields needed by our screens
  final String? profilePictureUrl;
  final String? department;
  final String? phone;
  final String? userID;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.photoUrl,
    this.phoneNumber,
    this.profilePictureUrl,
    this.department,
    this.phone,
    this.userID,
  });

  /// Create a User from a Firestore document
  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: UserRoleExtension.fromString(data['role'] ?? 'student'),
      isActive: data['isActive'] ?? true,
      photoUrl: data['photoUrl'],
      phoneNumber: data['phoneNumber'],
      profilePictureUrl: data['profilePictureUrl'] ?? data['photoUrl'],
      department: data['department'],
      phone: data['phone'] ?? data['phoneNumber'],
      userID: data['userID'],
    );
  }

  /// Convert User to a Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role.name,
      'isActive': isActive,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'profilePictureUrl': profilePictureUrl,
      'department': department,
      'phone': phone,
      'userID': userID,
    };
  }

  /// Create a copy of the user with updated fields
  User copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    bool? isActive,
    String? photoUrl,
    String? phoneNumber,
    String? profilePictureUrl,
    String? department,
    String? phone,
    String? userID,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      department: department ?? this.department,
      phone: phone ?? this.phone,
      userID: userID ?? this.userID,
    );
  }
}
