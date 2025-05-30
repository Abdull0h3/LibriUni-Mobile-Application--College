//lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart'; // LibriUniUser

class UserService {
  final CollectionReference<LibriUniUser> _usersCollection =
      FirebaseFirestore.instance.collection('users').withConverter<LibriUniUser>(
            fromFirestore: LibriUniUser.fromFirestore,
            toFirestore: (LibriUniUser user, _) => user.toFirestore(),
          );

  // Add a new user
  Future<DocumentReference<LibriUniUser>> addUser(LibriUniUser user) async {
    // Check if userIdString already exists to ensure uniqueness if needed
    final existingUser = await getUserByUserIdString(user.userIdString);
    if (existingUser != null) {
      throw Exception('User with ID String ${user.userIdString} already exists.');
    }
    return _usersCollection.add(user);
  }

  // Update an existing user
  Future<void> updateUser(String docId, LibriUniUser user) async {
    return _usersCollection.doc(docId).set(user, SetOptions(merge: true));
  }

  // Get a user by their Firestore document ID
  Future<LibriUniUser?> getUserById(String docId) async {
    final snapshot = await _usersCollection.doc(docId).get();
    return snapshot.data();
  }

  // Get a user by their custom userIdString (e.g., USR001)
  Future<LibriUniUser?> getUserByUserIdString(String userIdString) async {
    final querySnapshot = await _usersCollection.where('userIdString', isEqualTo: userIdString).limit(1).get();
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data();
    }
    return null;
  }

  // Get a stream of all users
  Stream<List<LibriUniUser>> getUsersStream() {
    return _usersCollection.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // Search users (simple name or email search)
  Stream<List<LibriUniUser>> searchUsersStream(String query) {
    if (query.isEmpty) {
      return getUsersStream();
    }
    // This is a simplified search. For robust search, consider dedicated search services
    // or structuring your data (e.g., lowercase fields for searching).
    return getUsersStream().map((users) => users.where((user) =>
      user.name.toLowerCase().contains(query.toLowerCase()) ||
      user.email.toLowerCase().contains(query.toLowerCase()) ||
      user.userIdString.toLowerCase().contains(query.toLowerCase())
    ).toList());
  }
}