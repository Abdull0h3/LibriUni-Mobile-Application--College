// lib/models/fine_detail_model.dart
import '/models/book_model.dart';
import '/models/user_model.dart'; // LibriUniUser

class FineDetailModel {
  final String fineDocId; // Firestore document ID of the FineModel
  final String loanId;    // Firestore document ID of the original LoanModel
  final LibriUniUser user;
  final BookModel book;
  final int daysOverdue;  
  final double fineAmount; 
  // Add any other fields you want to display from FineModel, like createdDate

  FineDetailModel({
    required this.fineDocId,
    required this.loanId,
    required this.user,
    required this.book,
    required this.daysOverdue,
    required this.fineAmount,
  });
}