import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../providers/book_provider.dart';
import '../../models/book.dart';

class ManageBooksScreen extends StatefulWidget {
  const ManageBooksScreen({Key? key}) : super(key: key);

  @override
  State<ManageBooksScreen> createState() => _ManageBooksScreenState();
}

class _ManageBooksScreenState extends State<ManageBooksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
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

    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    await bookProvider.fetchBooks();

    setState(() {
      _isLoading = false;
    });
  }

  void _searchBooks(String query) {
    setState(() {
      _searchQuery = query;
    });
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    bookProvider.searchBooks(query);
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    if (category == 'All') {
      bookProvider.clearFilters();
    } else {
      bookProvider.filterByCategory(category);
    }
  }

  void _addNewBook() {
    // Navigate to add book screen
    context.push('/admin/books/add');
  }

  void _editBook(Book book) {
    // Navigate to add book screen with book parameter
    // This screen handles both adding and editing books
    context.push('/admin/books/add', extra: book);
  }

  void _deleteBook(Book book) {
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
    final categories = [
      'All',
      'Fiction',
      'Non-Fiction',
      'Science',
      'Engineering',
      'Arts',
      'History',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Books'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title, author, or ISBN',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchBooks('');
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _searchBooks,
            ),
          ),
          // Category filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) => _filterByCategory(category),
                    backgroundColor: AppColors.lightGray,
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color:
                          isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          // Book list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : books.isEmpty
                    ? const Center(child: Text('No books found'))
                    : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          child: ListTile(
                            leading: Container(
                              width: 50,
                              height: 70,
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
                                                color: AppColors.primary,
                                              ),
                                        ),
                                      )
                                      : const Icon(
                                        Icons.book,
                                        color: AppColors.primary,
                                      ),
                            ),
                            title: Text(book.title),
                            subtitle: Text(
                              '${book.author} • ${book.category} • ${book.isAvailable ? 'Available' : 'Borrowed'}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editBook(book),
                                  color: AppColors.primary,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteBook(book),
                                  color: AppColors.error,
                                ),
                              ],
                            ),
                            onTap: () => _editBook(book),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewBook,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
