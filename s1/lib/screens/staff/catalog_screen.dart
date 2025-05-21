import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../providers/book_provider.dart';
import '../../models/book.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({Key? key}) : super(key: key);

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _showOnlyAvailable = false;

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
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    await bookProvider.fetchBooks();
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
      bookProvider.clearCategoryFilter();
    } else {
      bookProvider.filterByCategory(category);
    }
  }

  void _toggleAvailabilityFilter(bool value) {
    setState(() {
      _showOnlyAvailable = value;
    });
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    bookProvider.filterByAvailability(value);
  }

  void _addNewBook() {
    // Navigate to add book screen
  }

  void _editBook(Book book) {
    // Navigate to edit book screen
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
        title: const Text('Book Catalog'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addNewBook),
        ],
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
          // Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Categories',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Show only available books'),
                    const Spacer(),
                    Switch(
                      value: _showOnlyAvailable,
                      onChanged: _toggleAvailabilityFilter,
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          // Book List
          Expanded(
            child:
                bookProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : books.isEmpty
                    ? const Center(child: Text('No books found'))
                    : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        return _buildBookItem(context, books[index]);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookItem(BuildContext context, Book book) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () => _editBook(book),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book cover
              Container(
                width: 70,
                height: 100,
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
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.book,
                                size: 32,
                                color: AppColors.primary,
                              );
                            },
                          ),
                        )
                        : const Icon(
                          Icons.book,
                          size: 32,
                          color: AppColors.primary,
                        ),
              ),
              const SizedBox(width: 16),
              // Book details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ' + book.id,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(book.author, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                book.isAvailable
                                    ? AppColors.success.withOpacity(0.2)
                                    : AppColors.error.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            book.isAvailable ? 'Available' : 'Borrowed',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color:
                                  book.isAvailable
                                      ? AppColors.success
                                      : AppColors.error,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            book.category,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Shelf: ${book.shelf}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Edit icon
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editBook(book),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
