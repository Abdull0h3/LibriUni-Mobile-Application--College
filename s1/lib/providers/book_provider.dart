import 'package:flutter/foundation.dart';
import '../models/book_model.dart';
import '../services/book_service.dart';

class BookProvider with ChangeNotifier {
  final BookService _bookService = BookService();

  List<BookModel> _books = [];
  List<BookModel> _filteredBooks = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = '';

  // Getters
  List<BookModel> get books => _books;
  List<BookModel> get filteredBooks => _filteredBooks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  // Fetch all books (once)
  Future<void> fetchBooks() async {
    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _bookService.getBooksStream().first;
      _books = snapshot;
      _applyFilters();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Search books
  Future<void> searchBooks(String query) async {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Filter books by tag
  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  // Clear all filters
  void clearFilters() {
    _selectedCategory = '';
    _searchQuery = '';
    _filteredBooks = List.from(_books);
    notifyListeners();
  }

  // Add a new book
  Future<bool> addBook(BookModel book) async {
    try {
      _isLoading = true;
      notifyListeners();

      final docRef = await _bookService.addBook(book);
      final newBook = book.copyWith(id: docRef.id);
      _books.add(newBook);
      _applyFilters();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update a book
  Future<bool> updateBook(BookModel book) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _bookService.updateBook(book.id, book);

      final index = _books.indexWhere((b) => b.id == book.id);
      if (index != -1) {
        _books[index] = book;
        _applyFilters();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete a book
  Future<bool> deleteBook(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _bookService.deleteBook(id);

      _books.removeWhere((book) => book.id == id);
      _applyFilters();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update book status
  Future<bool> updateBookStatus(String id, String newStatus) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _bookService.updateBookStatus(id, newStatus);

      final index = _books.indexWhere((b) => b.id == id);
      if (index != -1) {
        _books[index] = _books[index].copyWith(status: newStatus);
        _applyFilters();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Apply filters
  void _applyFilters() {
    _filteredBooks =
        _books.where((book) {
          if (_selectedCategory.isNotEmpty && book.tag != _selectedCategory)
            return false;

          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            return book.title.toLowerCase().contains(query) ||
                book.author.toLowerCase().contains(query) ||
                book.code.toLowerCase().contains(query);
          }

          return true;
        }).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
