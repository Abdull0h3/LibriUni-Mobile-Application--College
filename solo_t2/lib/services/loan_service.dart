//lib/services/loan_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/loan_model.dart';
import '../models/book_model.dart'; // For updating book status
import 'book_service.dart'; // To update book status

class LoanService {
  final CollectionReference<LoanModel> _loansCollection =
      FirebaseFirestore.instance.collection('loans').withConverter<LoanModel>(
            fromFirestore: LoanModel.fromFirestore,
            toFirestore: (LoanModel loan, _) => loan.toFirestore(),
          );
  final BookService _bookService = BookService(); // To update book status

  // Create a new loan
  Future<DocumentReference<LoanModel>> createLoan(LoanModel loan) async {
    // Check if the book is already on an active loan
    final activeLoan = await getActiveLoanForBook(loan.bookId);
    if (activeLoan != null) {
      throw Exception('Book "${loan.bookTitle}" is already on loan to ${activeLoan.userName}.');
    }
    
    final loanRef = await _loansCollection.add(loan);
    // Update book status to "Borrowed"
    await _bookService.updateBookStatus(loan.bookId, 'Borrowed');
    return loanRef;
  }

  // Return a book (close an active loan)
  Future<void> returnBook(String loanId, String bookId) async {
    await _loansCollection.doc(loanId).update({'returnDate': Timestamp.now()});
    // Update book status to "Available"
    await _bookService.updateBookStatus(bookId, 'Available');
  }

  // Get an active loan for a specific book ID
  Future<LoanModel?> getActiveLoanForBook(String bookId) async {
    final querySnapshot = await _loansCollection
        .where('bookId', isEqualTo: bookId)
        .where('returnDate', isNull: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data();
    }
    return null;
  }

  // Get all active loans
  Stream<List<LoanModel>> getActiveLoansStream() {
    return _loansCollection
        .where('returnDate', isNull: true)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Get loan history for a specific book
  Stream<List<LoanModel>> getLoanHistoryForBookStream(String bookId) {
    return _loansCollection
        .where('bookId', isEqualTo: bookId)
        .orderBy('loanDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Get all loans for a specific user
  Stream<List<LoanModel>> getLoansForUserStream(String userId) {
    return _loansCollection
        .where('userId', isEqualTo: userId)
        .orderBy('loanDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

    Future<void> updateLoanReturnDate(String loanId, Timestamp returnDate) async {
    try {
      await _loansCollection.doc(loanId).update({'returnDate': returnDate});
    } catch (e) {
      print("Error updating loan return date: $e");
      throw FirebaseException(plugin: 'Firestore', message: 'Failed to update loan: $e');
    }
  }
  
  //for overdue loans
  Stream<List<LoanModel>> getOverdueLoansStream() {
    return _loansCollection
        .where('returnDate', isNull: true) // Loan is still active
        .where('dueDate', isLessThan: Timestamp.now()) // Due date has passed
        .orderBy('dueDate') // Show oldest overdue items first
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<LoanModel?> getLoanById(String loanId) async {
    final snapshot = await _loansCollection.doc(loanId).get();
    return snapshot.data();
  }
}