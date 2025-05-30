
// lib/models/fine_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FineModel {
  final String id; // Firestore document ID for the fine itself
  final String loanID; // Firestore document ID of the associated LoanModel
  final String bookID; // Firestore document ID of the associated BookModel
  final String userID; // Firestore document ID of the associated LibriUniUser
  
  Timestamp createdDate; // When the fine record was created or loan became overdue
  int daysOverdue;
  double fineAmount;
  String status; // "Unpaid", "Paid"
  Timestamp? paidDate;

  FineModel({
    required this.id,
    required this.loanID,
    required this.bookID,
    required this.userID,
    required this.createdDate,
    required this.daysOverdue,
    required this.fineAmount,
    required this.status,
    this.paidDate,
  });

  factory FineModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Missing data for FineModel from snapshot ${snapshot.id}');
    }
    return FineModel(
      id: snapshot.id,
      loanID: data['loanID'] ?? '',
      bookID: data['bookID'] ?? '',
      userID: data['userID'] ?? '',
      createdDate: data['createdDate'] as Timestamp? ?? Timestamp.now(),
      daysOverdue: data['daysOverdue'] as int? ?? 0,
      fineAmount: (data['fineAmount'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'Unpaid',
      paidDate: data['paidDate'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'loanID': loanID,
      'bookID': bookID,
      'userID': userID,
      'createdDate': createdDate,
      'daysOverdue': daysOverdue,
      'fineAmount': fineAmount,
      'status': status,
      'paidDate': paidDate,
    };
  }
}