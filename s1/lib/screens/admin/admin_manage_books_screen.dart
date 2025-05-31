import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../providers/book_provider.dart';
import '../../models/book_model.dart';

class AdminManageBooksScreen extends StatefulWidget {
  const AdminManageBooksScreen({super.key});

  @override
  State<AdminManageBooksScreen> createState() => _AdminManageBooksScreenState();
}

class _AdminManageBooksScreenState extends State<AdminManageBooksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      await bookProvider.fetchBooks();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load books: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _searchBooks(String query) {
    setState(() {
      _searchQuery = query;
    });
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    bookProvider.searchBooks(query);
  }

  void _addNewBook() {
    context.push('/admin/books/add');
  }

  void _editBook(BookModel book) {
    context.push('/admin/books/add', extra: book);
  }

  void _deleteBook(BookModel book) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Book'),
            content: Text('Are you sure you want to delete "${book.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final bookProvider = Provider.of<BookProvider>(
                    context,
                    listen: false,
                  );
                  await bookProvider.deleteBook(book.id);
                  _loadBooks();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Book deleted successfully')),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);
    final books = bookProvider.filteredBooks;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: const Text(
          'Manage Books',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _isLoading ? null : () => context.pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey[50]!],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search books...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.primary,
                  ),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.primary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _searchBooks('');
                            },
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15.0,
                    horizontal: 20.0,
                  ),
                ),
                onChanged: _searchBooks,
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : books.isEmpty
                      ? const Center(child: Text('No books found'))
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          final book = books[index];
                          return _buildBookListItem(book);
                        },
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _addNewBook,
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.add, color: Colors.white),
        elevation: 4.0,
      ),
    );
  }

  Widget _buildBookListItem(BookModel book) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
              image:
                  book.coverUrl != null
                      ? DecorationImage(
                        image: NetworkImage(book.coverUrl!),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                book.coverUrl == null
                    ? const Icon(Icons.book, size: 30, color: Colors.grey)
                    : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${book.author} • ${book.category}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        book.status == 'Available'
                            ? AppColors.success.withOpacity(0.2)
                            : AppColors.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    book.status,
                    style: TextStyle(
                      color:
                          book.status == 'Available'
                              ? AppColors.success
                              : AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primary),
                onPressed: _isLoading ? null : () => _editBook(book),
                tooltip: 'Edit Book',
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error),
                onPressed: _isLoading ? null : () => _deleteBook(book),
                tooltip: 'Delete Book',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
