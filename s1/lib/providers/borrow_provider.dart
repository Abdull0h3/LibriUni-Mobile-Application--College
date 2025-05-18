import 'package:flutter/foundation.dart';
import '../services/borrow_service.dart';
import '../models/book.dart';

class BorrowProvider with ChangeNotifier {
  final BorrowService _borrowService = BorrowService();

  List<Map<String, dynamic>> _userBorrows = [];
  List<Map<String, dynamic>> _allBorrows = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Map<String, dynamic>> get userBorrows => _userBorrows;
  List<Map<String, dynamic>> get allBorrows => _allBorrows;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch borrows for the current user
  Future<void> fetchUserBorrows() async {
    try {
      _isLoading = true;
      notifyListeners();

      _userBorrows = await _borrowService.getUserBorrows();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Fetch all borrows (for staff/admin)
  Future<void> fetchAllBorrows({bool activeOnly = true}) async {
    try {
      _isLoading = true;
      notifyListeners();

      _allBorrows = await _borrowService.getAllBorrows(activeOnly: activeOnly);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Borrow a book
  Future<bool> borrowBook(Book book, DateTime dueDate) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _borrowService.borrowBook(book, dueDate);

      if (result) {
        await fetchUserBorrows(); // Refresh the user's borrows
      } else {
        _error = 'Failed to borrow book. It might be unavailable.';
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Return a book
  Future<bool> returnBook(String borrowId, String bookId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _borrowService.returnBook(borrowId, bookId);

      if (result) {
        // Remove this borrow from the list or update its status
        _userBorrows.removeWhere((borrow) => borrow['id'] == borrowId);

        // Also update the all borrows list if we're an admin/staff
        final index = _allBorrows.indexWhere(
          (borrow) => borrow['id'] == borrowId,
        );
        if (index != -1) {
          _allBorrows[index]['isReturned'] = true;
          _allBorrows[index]['returnDate'] = DateTime.now();
        }
      } else {
        _error = 'Failed to return book.';
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get book history
  Future<List<Map<String, dynamic>>> getBookHistory(String bookId) async {
    try {
      return await _borrowService.getBookBorrowHistory(bookId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Get overdue count
  Future<int> getOverdueCount() async {
    try {
      return await _borrowService.getOverdueCount();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
