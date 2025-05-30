//lib/screens/manage_books_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/models/book_model.dart'; // Ensure correct path
import '/services/book_service.dart'; // Ensure correct path
import '/constants/app_colors.dart';

class ManageBooksScreen extends StatefulWidget {
  const ManageBooksScreen({super.key});

  @override
  State<ManageBooksScreen> createState() => _ManageBooksScreenState();
}

class _ManageBooksScreenState extends State<ManageBooksScreen> {
  final BookService _bookService = BookService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToAddBook() {
    context.push('/staff/books/add').then((_) {
      // Refresh or handle state update if a book was added/modified
      setState(() {});
    });
  }

  void _navigateToEditBook(BookModel book) {
    context.push('/staff/books/edit/${book.id}', extra: book).then((_) {
      // Refresh or handle state update
      setState(() {});
    });
  }

  Future<void> _deleteBook(String bookId, String bookTitle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: Text(
              'Are you sure you want to delete "$bookTitle"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _bookService.deleteBook(bookId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"$bookTitle" deleted successfully.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting book: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Books'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textColorLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add New Book',
            onPressed: _navigateToAddBook,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title, author, code...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.primaryColor,
                ),
                filled: true,
                fillColor: AppColors.cardBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: const BorderSide(
                    color: AppColors.secondaryColor,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<BookModel>>(
              stream: _bookService.searchBooksStream(
                _searchQuery,
              ), // Use search stream
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondaryColor,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  print('Error fetching books: ${snapshot.error}');
                  return Center(
                    child: Text(
                      'Error fetching books: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No books found.'));
                }

                final books = snapshot.data!;

                return SingleChildScrollView(
                  // For horizontal scroll of DataTable
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20.0,
                    headingRowColor: MaterialStateColor.resolveWith(
                      (states) => AppColors.primaryColor.withOpacity(0.1),
                    ),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Title',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColorDark,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Author',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColorDark,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Code',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColorDark,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColorDark,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Actions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColorDark,
                          ),
                        ),
                      ),
                    ],
                    rows:
                        books.map((book) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  book.title,
                                  style: const TextStyle(
                                    color: AppColors.textColorDark,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  book.author,
                                  style: const TextStyle(
                                    color: AppColors.textColorDark,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  book.code,
                                  style: const TextStyle(
                                    color: AppColors.textColorDark,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  book.status,
                                  style: TextStyle(
                                    color:
                                        book.status == 'Available'
                                            ? Colors.green.shade700
                                            : book.status == 'Borrowed'
                                            ? Colors.orange.shade700
                                            : Colors.red.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: AppColors.primaryColor,
                                      ),
                                      tooltip: 'Edit Book',
                                      onPressed:
                                          () => _navigateToEditBook(book),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.redAccent,
                                      ),
                                      tooltip: 'Delete Book',
                                      onPressed:
                                          () =>
                                              _deleteBook(book.id, book.title),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
