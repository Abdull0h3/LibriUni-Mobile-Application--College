import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get chat messages for a specific student's chat thread
  Stream<List<ChatMessage>> getStudentChatMessages(String studentId) {
    return _firestore
        .collection('chats')
        .doc(studentId)
        .collection('messages')
        .orderBy(
          'timestamp',
          descending: false,
        ) // Order by timestamp ascending for chat view
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();
        });
  }

  // Send a new message to a student's chat thread
  Future<void> sendStudentMessage({
    required String studentId,
    required String senderId,
    required String message,
    required String receiverId, // Explicitly require receiverId
  }) async {
    final chatMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      receiverId: receiverId,
      message: message,
      timestamp: DateTime.now(),
      isRead: false, // Message is unread when sent
    );

    // Ensure the chat document for the student exists and potentially store student name here too for easier access
    // Use SetOptions(merge: true) to avoid overwriting existing chat document data like lastMessage/Timestamp
    await _firestore.collection('chats').doc(studentId).set({
      'studentId': studentId,
      'participants': FieldValue.arrayUnion([
        senderId,
        receiverId,
      ]), // Keep track of participants
    }, SetOptions(merge: true));

    await _firestore
        .collection('chats')
        .doc(studentId)
        .collection('messages')
        .doc(chatMessage.id) // Use message id as document id
        .set(chatMessage.toMap());

    // Update last message and timestamp in the chat document
    await _firestore.collection('chats').doc(studentId).update({
      'lastMessage': chatMessage.message,
      'lastMessageTimestamp': chatMessage.timestamp,
    });
  }

  // Get list of students with active chat threads including student names and last message (for staff)
  Stream<List<Map<String, dynamic>>> getStudentsWithActiveChats() {
    return _firestore
        .collection('chats')
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final chatsData =
              snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList();
          List<Map<String, dynamic>> studentsWithNames = [];
          for (var chat in chatsData) {
            final studentId = chat['id'];
            // Fetch student name from the users collection
            final userDoc =
                await _firestore.collection('users').doc(studentId).get();
            if (userDoc.exists) {
              studentsWithNames.add({
                'id': studentId,
                'studentName': userDoc.data()?['name'] ?? 'Unknown Student',
                'lastMessage': chat['lastMessage'] ?? '',
                'lastMessageTimestamp': chat['lastMessageTimestamp'],
              });
            } else {
              studentsWithNames.add({
                'id': studentId,
                'studentName':
                    'Unknown Student', // Fallback if user doc not found
                'lastMessage': chat['lastMessage'] ?? '',
                'lastMessageTimestamp': chat['lastMessageTimestamp'],
              });
            }
          }
          return studentsWithNames;
        });
  }

  // Get chat messages for a specific student's chat thread (for staff)
  Stream<List<ChatMessage>> getStaffChatMessages(String studentId) {
    return _firestore
        .collection('chats')
        .doc(studentId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();
        });
  }

  // Mark messages as read in a student's chat thread
  Future<void> markMessagesAsRead(String studentId, String userId) async {
    print(
      'markMessagesAsRead entered - studentId: $studentId, userId: $userId',
    );

    try {
      final messagesToMark =
          await _firestore
              .collection('chats')
              .doc(studentId)
              .collection('messages')
              .where('receiverId', isEqualTo: userId)
              .where('isRead', isEqualTo: false)
              .get();

      print(
        'markMessagesAsRead query result: Found ${messagesToMark.docs.length} messages to mark as read for userId $userId in chat $studentId.',
      );
      if (messagesToMark.docs.isEmpty) {
        print('No unread messages found matching the criteria.');
      }

      for (var doc in messagesToMark.docs) {
        print('Attempting to mark message ${doc.id} as read...');
        await doc.reference.update({'isRead': true});
        print('Successfully marked message ${doc.id} as read.');
      }
      print('markMessagesAsRead finished.');
    } catch (e) {
      print('Error in markMessagesAsRead: $e');
    }
  }

  // Get unread message count for a specific student's chat thread (for staff list view)
  Stream<int> getUnreadMessageCountForStudent(
    String studentId,
    String staffId,
  ) {
    return _firestore
        .collection('chats')
        .doc(studentId)
        .collection('messages')
        .where(
          'receiverId',
          isEqualTo: staffId,
        ) // Messages sent by student to staff
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get total unread message count for a user (staff or student)
  Stream<int> getTotalUnreadMessageCount(String userId) {
    return _firestore
        .collectionGroup(
          'messages',
        ) // Search across all subcollections named 'messages'
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Keep old methods for now, might be used elsewhere or need adaptation
  // These might be removed later if not used.
  // Get chat messages between two users
  Stream<List<ChatMessage>> getChatMessages(String userId1, String userId2) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContainsAny: [userId1, userId2])
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .where(
                (message) =>
                    (message.senderId == userId1 &&
                        message.receiverId == userId2) ||
                    (message.senderId == userId2 &&
                        message.receiverId == userId1),
              )
              .toList();
        });
  }

  // Send a new message
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    final chatMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      receiverId: receiverId,
      message: message,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection('chats')
        .doc(chatMessage.id)
        .set(chatMessage.toMap());
  }

  // Get unread message count
  Stream<int> getUnreadMessageCount(String userId) {
    return _firestore
        .collection('chats')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get staff members
  Stream<QuerySnapshot> getStaffMembers() {
    return _firestore
        .collection('users')
        .where('userId', isGreaterThanOrEqualTo: 'STA')
        .where('userId', isLessThan: 'STB')
        .snapshots();
  }

  // Get students
  Stream<QuerySnapshot> getStudents() {
    return _firestore
        .collection('users')
        .where('userId', isGreaterThanOrEqualTo: 'STU')
        .where('userId', isLessThan: 'STV')
        .snapshots();
  }

  // Get user type from ID
  String getUserType(String userId) {
    if (userId.startsWith('AD')) return 'admin';
    if (userId.startsWith('STA')) return 'staff';
    if (userId.startsWith('STU')) return 'student';
    return 'unknown';
  }

  // Check if user is staff
  bool isStaff(String userId) {
    return userId.startsWith('STA');
  }

  // Check if user is student
  bool isStudent(String userId) {
    return userId.startsWith('STU');
  }

  // Check if user is admin
  bool isAdmin(String userId) {
    return userId.startsWith('AD');
  }
}
