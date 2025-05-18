import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/book.dart';

class BorrowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final String _collection = 'borrows';

  // Borrow a book
  Future<bool> borrowBook(Book book, DateTime dueDate) async {
    try {
      if (!book.isAvailable) {
        return false; // Book is already borrowed
      }

      final user = _auth.currentUser;
      if (user == null) {
        return false; // User not logged in
      }

      // Create a borrow record
      final borrowData = {
        'userId': user.uid,
        'userName': user.displayName ?? 'Unknown User',
        'userEmail': user.email ?? 'No Email',
        'bookId': book.id,
        'bookTitle': book.title,
        'bookAuthor': book.author,
        'bookCategory': book.category,
        'borrowDate': Timestamp.now(),
        'dueDate': Timestamp.fromDate(dueDate),
        'isReturned': false,
        'returnDate': null,
      };

      // Add borrow record
      await _firestore.collection(_collection).add(borrowData);

      // Update book availability
      await _firestore.collection('books').doc(book.id).update({
        'isAvailable': false,
        'borrowedBy': user.uid,
        'borrowDate': Timestamp.now(),
        'dueDate': Timestamp.fromDate(dueDate),
      });

      return true;
    } catch (e) {
      print('Error borrowing book: $e');
      return false;
    }
  }

  // Return a book
  Future<bool> returnBook(String borrowId, String bookId) async {
    try {
      // Update borrow record
      await _firestore.collection(_collection).doc(borrowId).update({
        'isReturned': true,
        'returnDate': Timestamp.now(),
      });

      // Update book availability
      await _firestore.collection('books').doc(bookId).update({
        'isAvailable': true,
        'borrowedBy': null,
        'borrowDate': null,
        'dueDate': null,
      });

      return true;
    } catch (e) {
      print('Error returning book: $e');
      return false;
    }
  }

  // Get all current borrows for the logged-in user
  Future<List<Map<String, dynamic>>> getUserBorrows() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      final QuerySnapshot snapshot =
          await _firestore
              .collection(_collection)
              .where('userId', isEqualTo: user.uid)
              .where('isReturned', isEqualTo: false)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'bookId': data['bookId'],
          'bookTitle': data['bookTitle'],
          'bookAuthor': data['bookAuthor'],
          'borrowDate': (data['borrowDate'] as Timestamp).toDate(),
          'dueDate': (data['dueDate'] as Timestamp).toDate(),
        };
      }).toList();
    } catch (e) {
      print('Error getting user borrows: $e');
      return [];
    }
  }

  // Get all current borrows (for staff/admin)
  Future<List<Map<String, dynamic>>> getAllBorrows({
    bool activeOnly = true,
  }) async {
    try {
      QuerySnapshot snapshot;

      if (activeOnly) {
        snapshot =
            await _firestore
                .collection(_collection)
                .where('isReturned', isEqualTo: false)
                .get();
      } else {
        snapshot = await _firestore.collection(_collection).get();
      }

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'userId': data['userId'],
          'userName': data['userName'],
          'userEmail': data['userEmail'],
          'bookId': data['bookId'],
          'bookTitle': data['bookTitle'],
          'bookAuthor': data['bookAuthor'],
          'borrowDate': (data['borrowDate'] as Timestamp).toDate(),
          'dueDate': (data['dueDate'] as Timestamp).toDate(),
          'isReturned': data['isReturned'],
          'returnDate':
              data['returnDate'] != null
                  ? (data['returnDate'] as Timestamp).toDate()
                  : null,
        };
      }).toList();
    } catch (e) {
      print('Error getting all borrows: $e');
      return [];
    }
  }

  // Get borrow history for a specific book
  Future<List<Map<String, dynamic>>> getBookBorrowHistory(String bookId) async {
    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collection(_collection)
              .where('bookId', isEqualTo: bookId)
              .orderBy('borrowDate', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'userId': data['userId'],
          'userName': data['userName'],
          'userEmail': data['userEmail'],
          'borrowDate': (data['borrowDate'] as Timestamp).toDate(),
          'dueDate': (data['dueDate'] as Timestamp).toDate(),
          'isReturned': data['isReturned'],
          'returnDate':
              data['returnDate'] != null
                  ? (data['returnDate'] as Timestamp).toDate()
                  : null,
        };
      }).toList();
    } catch (e) {
      print('Error getting book borrow history: $e');
      return [];
    }
  }

  // Get the number of overdue books
  Future<int> getOverdueCount() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collection(_collection)
              .where('isReturned', isEqualTo: false)
              .where('dueDate', isLessThan: Timestamp.now())
              .get();

      return snapshot.size;
    } catch (e) {
      print('Error getting overdue count: $e');
      return 0;
    }
  }
}
