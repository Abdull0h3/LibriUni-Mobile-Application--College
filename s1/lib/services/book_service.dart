//lib/services/book_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';

class BookService {
  final CollectionReference<BookModel> _booksCollection = FirebaseFirestore
      .instance
      .collection('books')
      .withConverter<BookModel>(
        fromFirestore: BookModel.fromFirestore,
        toFirestore: (BookModel book, _) => book.toFirestore(),
      );

  // Add a new book
  Future<DocumentReference<BookModel>> addBook(BookModel book) async {
    return _booksCollection.add(book);
  }

  // Update an existing book
  Future<void> updateBook(String bookId, BookModel book) async {
    return _booksCollection.doc(bookId).set(book, SetOptions(merge: true));
  }

  // Delete a book
  Future<void> deleteBook(String bookId) async {
    return _booksCollection.doc(bookId).delete();
  }

  // Get a single book by its ID (document ID or potentially your custom 'code')
  Future<BookModel?> getBookById(String docId) async {
    final snapshot = await _booksCollection.doc(docId).get();
    return snapshot.data();
  }

  // Get a book by its unique 'code' (e.g., DS101)
  Future<BookModel?> getBookByCode(String code) async {
    final querySnapshot =
        await _booksCollection.where('code', isEqualTo: code).limit(1).get();
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data();
    }
    return null;
  }

  // Get a stream of all books (for real-time updates)
  Stream<List<BookModel>> getBooksStream() {
    return _booksCollection.orderBy('title').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // Search books (simple title search for now, can be expanded)
  Stream<List<BookModel>> searchBooksStream(String query) {
    if (query.isEmpty) {
      return getBooksStream();
    }
    // Firestore doesn't support case-insensitive 'contains' directly for complex queries.
    // A common workaround is to store a searchable version of the field (e.g., all lowercase).
    // For simplicity here, we'll fetch all and filter, or can structure data for search.
    // This query searches for titles starting with the query (case-sensitive).
    return _booksCollection
        .orderBy('title')
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

    // For a more robust client-side filter if needed, after fetching:
    // return getBooksStream().map((books) => books.where((book) =>
    //   book.title.toLowerCase().contains(query.toLowerCase()) ||
    //   book.author.toLowerCase().contains(query.toLowerCase()) ||
    //   book.code.toLowerCase().contains(query.toLowerCase())
    // ).toList());
  }

  // Update book status
  Future<void> updateBookStatus(String bookDocId, String newStatus) async {
    try {
      await _booksCollection.doc(bookDocId).update({'status': newStatus});
    } catch (e) {
      print("Error updating book status: $e");
      // Handle error appropriately
    }
  }

  Future<List<BookModel>> getBooksOnce() async {
    final snapshot = await _booksCollection.get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
