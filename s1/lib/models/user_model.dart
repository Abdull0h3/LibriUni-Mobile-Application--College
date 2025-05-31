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
  final String? userID;

  // Additional fields needed by our screens
  final String? profilePictureUrl;
  final String? phone;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.photoUrl,
    this.phoneNumber,
    this.userID,
    this.profilePictureUrl,
    this.phone,
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
      userID: data['userID'],
      profilePictureUrl: data['profilePictureUrl'] ?? data['photoUrl'],
      phone: data['phone'] ?? data['phoneNumber'],
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
      'userID': userID,
      'profilePictureUrl': profilePictureUrl,
      'phone': phone,
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
    String? userID,
    String? profilePictureUrl,
    String? phone,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userID: userID ?? this.userID,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      phone: phone ?? this.phone,
    );
  }
}

class LibriUniUser {
  final String id; // Firestore document ID
  final String name;
  final String userIdString; // The displayable User ID (e.g., USR001)
  final String email;
  bool isActive;
  // Overdue status might be calculated dynamically or stored if preferred
  // todo: note, it was assumed it can be stored or derived.
  // List<String> overdueBookIds;

  LibriUniUser({
    required this.id,
    required this.name,
    required this.userIdString,
    required this.email,
    required this.isActive,
    // this.overdueBookIds = const [],
  });

  factory LibriUniUser.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return LibriUniUser(
      id: snapshot.id,
      name: data?['name'] ?? 'Unknown User',
      userIdString: data?['userIdString'] ?? '',
      email: data?['email'] ?? '',
      isActive: data?['isActive'] ?? false,
      // overdueBookIds: List<String>.from(data?['overdueBookIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'userIdString': userIdString,
      'email': email,
      'isActive': isActive,
      // 'overdueBookIds': overdueBookIds,
    };
  }
}
