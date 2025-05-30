import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/book_model.dart';
import '../../constants/app_colors.dart';
import '../../providers/book_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/student_nav_bar.dart';

class BookDetailScreen extends StatefulWidget {
  final String bookId;
  const BookDetailScreen({Key? key, required this.bookId}) : super(key: key);

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  BookModel? _book;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookDetails();
  }

  Future<void> _loadBookDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      await bookProvider.fetchBooks();

      // Find the book in the list
      final books = bookProvider.books;
      final book = books.firstWhere(
        (b) => b.id == widget.bookId,
        orElse: () => throw Exception('Book not found'),
      );

      setState(() {
        _book = book;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: $_error',
                      style: const TextStyle(color: AppColors.error),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadBookDetails,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : _book == null
              ? const Center(child: Text('Book not found'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book cover and basic info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Book cover
                        Container(
                          width: 120,
                          height: 180,
                          decoration: BoxDecoration(
                            color: AppColors.lightGray,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child:
                              _book!.coverUrl != null
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _book!.coverUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return const Center(
                                          child: Icon(
                                            Icons.book,
                                            size: 48,
                                            color: AppColors.primary,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                  : const Center(
                                    child: Icon(
                                      Icons.book,
                                      size: 48,
                                      color: AppColors.primary,
                                    ),
                                  ),
                        ),
                        const SizedBox(width: 16),
                        // Book basic info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _book!.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'By ${_book!.author}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _book!.status == 'Available'
                                          ? AppColors.success.withOpacity(0.2)
                                          : _book!.status == 'Borrowed'
                                          ? AppColors.error.withOpacity(0.2)
                                          : AppColors.warning.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _book!.status,
                                  style: TextStyle(
                                    color:
                                        _book!.status == 'Available'
                                            ? AppColors.success
                                            : _book!.status == 'Borrowed'
                                            ? AppColors.error
                                            : AppColors.warning,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Category: ${_book!.category ?? 'Not specified'}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Code: ${_book!.code}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Published: ${_book!.publishedYear ?? 'Not specified'}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Book description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _book!.description ??
                          'No description available for this book.',
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
      bottomNavigationBar: StudentNavBar(currentIndex: 0, context: context),
    );
  }
}
