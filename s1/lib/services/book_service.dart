import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';

class BookService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'books';

  /// Get a stream of all books
  Stream<List<Book>> getBooksStream() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList(),
        );
  }

  /// Get all books
  Future<List<Book>> getBooks() async {
    final QuerySnapshot snapshot =
        await _firestore.collection(_collection).get();
    return snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
  }

  /// Get a specific book by ID
  Future<Book?> getBookById(String id) async {
    final DocumentSnapshot doc =
        await _firestore.collection(_collection).doc(id).get();
    if (doc.exists) {
      return Book.fromFirestore(doc);
    }
    return null;
  }

  /// Search books by title, author, or category
  Future<List<Book>> searchBooks(String query) async {
    // Convert query to lowercase for case-insensitive search
    final String searchQuery = query.toLowerCase();

    // Get all books (in a real app, you might want to use a more efficient approach)
    final List<Book> allBooks = await getBooks();

    // Filter books based on the query
    return allBooks
        .where(
          (book) =>
              book.title.toLowerCase().contains(searchQuery) ||
              book.author.toLowerCase().contains(searchQuery) ||
              book.category.toLowerCase().contains(searchQuery),
        )
        .toList();
  }

  /// Add a new book
  Future<String> addBook(Book book) async {
    final DocumentReference doc = await _firestore
        .collection(_collection)
        .add(book.toFirestore());
    return doc.id;
  }

  /// Update an existing book
  Future<void> updateBook(Book book) async {
    await _firestore
        .collection(_collection)
        .doc(book.id)
        .update(book.toFirestore());
  }

  /// Delete a book
  Future<void> deleteBook(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  /// Get available books
  Future<List<Book>> getAvailableBooks() async {
    final QuerySnapshot snapshot =
        await _firestore
            .collection(_collection)
            .where('isAvailable', isEqualTo: true)
            .get();
    return snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
  }

  /// Get books by category
  Future<List<Book>> getBooksByCategory(String category) async {
    final QuerySnapshot snapshot =
        await _firestore
            .collection(_collection)
            .where('category', isEqualTo: category)
            .get();
    return snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
  }

  /// Update book availability
  Future<void> updateBookAvailability(String id, bool isAvailable) async {
    await _firestore.collection(_collection).doc(id).update({
      'isAvailable': isAvailable,
    });
  }
}
