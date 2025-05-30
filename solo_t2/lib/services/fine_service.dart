// lib/services/fine_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fine_model.dart';
import '../models/loan_model.dart';
import '../models/book_model.dart';
import '../models/user_model.dart'; // LibriUniUser

// Fine calculation constants (could also be in a constants file)
const double _redTagFineRateFineService = 1.00;
const double _yellowTagFineRateFineService = 0.50;
const double _greenTagFineRateFineService = 0.25;


class FineService {
  final CollectionReference<FineModel> _finesCollection =
      FirebaseFirestore.instance.collection('fines').withConverter<FineModel>(
            fromFirestore: (snapshot, _) => FineModel.fromFirestore(snapshot),
            toFirestore: (fine, _) => fine.toFirestore(),
          );

  // Stream unpaid fines for display
  Stream<List<FineModel>> getUnpaidFinesStream() {
    return _finesCollection
        .where('status', isEqualTo: 'Unpaid')
        .orderBy('createdDate', descending: true) // Or however you want to sort
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Ensures a fine record exists and is up-to-date for an overdue loan
  Future<void> ensureFineRecord({
    required LoanModel loan,
    required BookModel book,
    required LibriUniUser user, // Pass the full LibriUniUser object
  }) async {
    final now = Timestamp.now();
    // Double check if loan is actually overdue
    if (loan.returnDate != null || loan.dueDate.compareTo(now) >= 0) {
      // If loan is returned or not yet due, ensure no 'Unpaid' fine exists or mark it as 'Error/Resolved'
      // For now, we'll just prevent creation/update if not truly overdue.
      // More advanced logic could handle removing/voiding unnecessary fine records.
      print("Loan ${loan.id} is not currently overdue. Skipping fine record creation/update.");
      
      // Optional: If an "Unpaid" fine record exists for a now non-overdue loan, might want to void it.
      // final existingFineQuery = await _finesCollection.where('loanID', isEqualTo: loan.id).where('status', isEqualTo: 'Unpaid').limit(1).get();
      // if (existingFineQuery.docs.isNotEmpty) {
      //   await existingFineQuery.docs.first.reference.update({'status': 'Voided - Loan Not Overdue'});
      // }
      return;
    }

    final daysOverdue = now.toDate().difference(loan.dueDate.toDate()).inDays;
    if (daysOverdue <= 0) return; // Not overdue by a full day yet

    double ratePerDay;
    switch (book.tag.toLowerCase()) {
      case 'red': ratePerDay = _redTagFineRateFineService; break;
      case 'yellow': ratePerDay = _yellowTagFineRateFineService; break;
      case 'green': default: ratePerDay = _greenTagFineRateFineService; break;
    }
    final fineAmount = daysOverdue * ratePerDay;

    final querySnapshot = await _finesCollection.where('loanID', isEqualTo: loan.id).limit(1).get();

    if (querySnapshot.docs.isNotEmpty) {
      final fineDocSnapshot = querySnapshot.docs.first;
      final existingFine = fineDocSnapshot.data();

      if (existingFine.status == 'Unpaid') {
        // Update if daysOverdue or fineAmount changed
        await fineDocSnapshot.reference.update({
          'daysOverdue': daysOverdue,
          'fineAmount': fineAmount,
          'bookID': book.id, // Ensure these are up-to-date
          'userID': user.id, // Ensure these are up-to-date
          // 'lastChecked': now, // Optional: for debugging or auditing
        });
      }
      // If status is 'Paid', do nothing more here.
    } else {
      // No fine record exists, create one.
      final newFine = FineModel(
        id: '', // Firestore will generate ID on .add()
        loanID: loan.id,
        bookID: book.id, // Use the actual book document ID
        userID: user.id, // Use the actual user document ID
        createdDate: loan.dueDate, // Date it became overdue, or Timestamp.now()
        daysOverdue: daysOverdue,
        fineAmount: fineAmount,
        status: 'Unpaid',
        paidDate: null,
      );
      await _finesCollection.add(newFine);
    }
  }

  // Mark a specific fine document as paid
  Future<void> markFineDocumentAsPaid(String fineDocId, Timestamp paidDate) async {
    try {
      await _finesCollection.doc(fineDocId).update({
        'status': 'Paid',
        'paidDate': paidDate,
      });
    } catch (e) {
      print("Error marking fine document as paid: $e");
      rethrow;
    }
  }
}