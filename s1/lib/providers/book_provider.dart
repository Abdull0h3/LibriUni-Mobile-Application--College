import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../services/book_service.dart';

class BookProvider with ChangeNotifier {
  final BookService _bookService = BookService();

  List<Book> _books = [];
  List<Book> _filteredBooks = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = '';

  // Getters
  List<Book> get books => _books;
  List<Book> get filteredBooks => _filteredBooks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  // Fetch all books
  Future<void> fetchBooks() async {
    try {
      _isLoading = true;
      notifyListeners();

      _books = await _bookService.getBooks();
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
    try {
      _isLoading = true;
      _searchQuery = query;
      notifyListeners();

      if (query.isEmpty) {
        _applyFilters();
      } else {
        final results = await _bookService.getBooks();
        final lowerQuery = query.toLowerCase();
        final filtered =
            results
                .where(
                  (book) =>
                      book.title.toLowerCase().startsWith(lowerQuery) ||
                      book.author.toLowerCase().startsWith(lowerQuery) ||
                      book.category.toLowerCase().startsWith(lowerQuery),
                )
                .toList();

        if (_selectedCategory.isNotEmpty) {
          _filteredBooks =
              filtered
                  .where((book) => book.category == _selectedCategory)
                  .toList();
        } else {
          _filteredBooks = filtered;
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Filter books by category
  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  // Clear category filter
  void clearCategoryFilter() {
    _selectedCategory = '';
    _applyFilters();
    notifyListeners();
  }

  // Filter by availability
  void filterByAvailability(bool showOnlyAvailable) {
    if (showOnlyAvailable) {
      _filteredBooks =
          _filteredBooks.where((book) => book.isAvailable).toList();
    } else {
      _applyFilters();
    }
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _selectedCategory = '';
    _searchQuery = '';
    _filteredBooks = List.from(_books);
    notifyListeners();
  }

  // Add a new book
  Future<bool> addBook(Book book) async {
    try {
      _isLoading = true;
      notifyListeners();

      final String id = await _bookService.addBook(book);

      final newBook = book.copyWith(id: id);
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
  Future<bool> updateBook(Book book) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _bookService.updateBook(book);

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

  // Update book availability
  Future<bool> updateBookAvailability(String id, bool isAvailable) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _bookService.updateBookAvailability(id, isAvailable);

      final index = _books.indexWhere((b) => b.id == id);
      if (index != -1) {
        _books[index] = _books[index].copyWith(isAvailable: isAvailable);
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

  // Apply all filters to books
  void _applyFilters() {
    if (_selectedCategory.isEmpty && _searchQuery.isEmpty) {
      _filteredBooks = List.from(_books);
      return;
    }

    _filteredBooks =
        _books.where((book) {
          // Filter by category if selected
          if (_selectedCategory.isNotEmpty &&
              book.category != _selectedCategory) {
            return false;
          }

          // Filter by search query if provided
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            return book.title.toLowerCase().startsWith(query) ||
                book.author.toLowerCase().startsWith(query) ||
                book.category.toLowerCase().startsWith(query);
          }

          return true;
        }).toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
