import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../models/book.dart';
import '../../widgets/student_nav_bar.dart';

class BorrowedBooksScreen extends StatefulWidget {
  const BorrowedBooksScreen({Key? key}) : super(key: key);

  @override
  State<BorrowedBooksScreen> createState() => _BorrowedBooksScreenState();
}

class _BorrowedBooksScreenState extends State<BorrowedBooksScreen> {
  bool _isLoading = false;
  String? _error;

  // This would come from a BorrowedBooksProvider in a real app
  // Here we'll just use a mock list for demonstration
  final List<BorrowedBook> _borrowedBooks = [
    BorrowedBook(
      book: Book(
        id: '1',
        title: 'Data Science 101',
        author: 'John Smith',
        category: 'Engineering',
        shelf: 'A1',
        isAvailable: false,
        publishedDate: DateTime(2021),
        coverUrl: null,
        description: 'An introduction to data science principles and methods.',
      ),
      borrowDate: DateTime.now().subtract(const Duration(days: 5)),
      dueDate: DateTime.now().add(const Duration(days: 9)),
      isOverdue: false,
    ),
    BorrowedBook(
      book: Book(
        id: '2',
        title: 'AI Fundamentals',
        author: 'Sarah Johnson',
        category: 'Engineering',
        shelf: 'B3',
        isAvailable: false,
        publishedDate: DateTime(2020),
        coverUrl: null,
        description: 'Comprehensive guide to artificial intelligence.',
      ),
      borrowDate: DateTime.now().subtract(const Duration(days: 15)),
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
      isOverdue: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadBorrowedBooks();
  }

  Future<void> _loadBorrowedBooks() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      setState(() {
        _error = 'Please login to view your borrowed books';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // In a real app, we would load books from a service
      // For now, we'll just simulate a network delay
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _returnBook(BorrowedBook borrowedBook) async {
    // In a real app, we would call a service
    setState(() {
      _borrowedBooks.remove(borrowedBook);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${borrowedBook.book.title} has been returned'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              setState(() {
                _borrowedBooks.add(borrowedBook);
              });
            },
          ),
        ),
      );
    }
  }

  Future<void> _renewBook(BorrowedBook borrowedBook) async {
    // In a real app, we would call a service
    final index = _borrowedBooks.indexOf(borrowedBook);
    if (index != -1) {
      setState(() {
        _borrowedBooks[index] = BorrowedBook(
          book: borrowedBook.book,
          borrowDate: borrowedBook.borrowDate,
          dueDate: DateTime.now().add(const Duration(days: 14)),
          isOverdue: false,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${borrowedBook.book.title} has been renewed'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Borrowed Books'),
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
                      _error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadBorrowedBooks,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : _borrowedBooks.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.book_outlined,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'You have no borrowed books',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Visit the library to borrow books',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _borrowedBooks.length,
                itemBuilder: (context, index) {
                  return _buildBorrowedBookItem(context, _borrowedBooks[index]);
                },
              ),
      bottomNavigationBar: StudentNavBar(currentIndex: 0, context: context),
    );
  }

  Widget _buildBorrowedBookItem(
    BuildContext context,
    BorrowedBook borrowedBook,
  ) {
    final book = borrowedBook.book;
    final daysLeft =
        borrowedBook.isOverdue
            ? 0
            : borrowedBook.dueDate.difference(DateTime.now()).inDays;
    final statusColor =
        borrowedBook.isOverdue
            ? AppColors.error
            : daysLeft <= 3
            ? AppColors.warning
            : AppColors.success;
    final statusText =
        borrowedBook.isOverdue
            ? 'Overdue'
            : daysLeft == 0
            ? 'Due today'
            : daysLeft == 1
            ? '1 day left'
            : '$daysLeft days left';

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book cover or placeholder
                Container(
                  width: 80,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child:
                      book.coverUrl != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              book.coverUrl!,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => const Icon(
                                    Icons.book,
                                    size: 32,
                                    color: AppColors.primary,
                                  ),
                            ),
                          )
                          : const Icon(
                            Icons.book,
                            size: 32,
                            color: AppColors.primary,
                          ),
                ),
                const SizedBox(width: 16),
                // Book info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By ${book.author}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Borrowed: ${DateFormat.yMMMd().format(borrowedBook.borrowDate)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.event, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            'Due: ${DateFormat.yMMMd().format(borrowedBook.dueDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 10,
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _returnBook(borrowedBook),
                  icon: const Icon(Icons.assignment_return, size: 16),
                  label: const Text('Return'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed:
                      borrowedBook.isOverdue
                          ? null
                          : () => _renewBook(borrowedBook),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Renew'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.disabledBackground,
                    disabledForegroundColor: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Model class for borrowed books
class BorrowedBook {
  final Book book;
  final DateTime borrowDate;
  final DateTime dueDate;
  final bool isOverdue;

  BorrowedBook({
    required this.book,
    required this.borrowDate,
    required this.dueDate,
    required this.isOverdue,
  });
}
