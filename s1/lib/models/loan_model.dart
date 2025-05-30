//lib/models/loan_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class LoanModel {
  final String id; // Firestore document ID
  final String bookId;
  final String bookTitle; // Denormalized for easier display
  final String userId; // Firestore document ID of the LibriUniUser
  final String userName; // Denormalized for easier display
  final Timestamp loanDate;
  final Timestamp dueDate;
  Timestamp? returnDate;
  // Add other relevant fields like loan initiated by staff ID, etc.

  LoanModel({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.userId,
    required this.userName,
    required this.loanDate,
    required this.dueDate,
    this.returnDate,
  });

  factory LoanModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return LoanModel(
      id: snapshot.id,
      bookId: data?['bookId'] ?? '',
      bookTitle: data?['bookTitle'] ?? 'Unknown Book',
      userId: data?['userId'] ?? '',
      userName: data?['userName'] ?? 'Unknown User',
      loanDate: data?['loanDate'] ?? Timestamp.now(),
      dueDate: data?['dueDate'] ?? Timestamp.now(),
      returnDate: data?['returnDate'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookId': bookId,
      'bookTitle': bookTitle,
      'userId': userId,
      'userName': userName,
      'loanDate': loanDate,
      'dueDate': dueDate,
      'returnDate': returnDate, // Will be null for active loans
    };
  }

  // bool get isOverdue {
  // return status == 'unpaid'
  //     && returnDate == null
  //     && Timestamp.now().compareTo(dueDate) > 0;
  // }
  bool get isOverdue {
    return returnDate == null && Timestamp.now().compareTo(dueDate) > 0;
  }
}
