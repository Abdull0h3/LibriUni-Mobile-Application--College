//lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory LibriUniUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
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