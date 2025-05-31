// lib/screens/search_catalog_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:s1/constants/app_colors.dart';
import 'package:s1/providers/book_provider.dart';
import 'package:s1/models/book_model.dart';

class SearchCatalogScreen extends StatefulWidget {
  const SearchCatalogScreen({super.key});

  @override
  State<SearchCatalogScreen> createState() => _SearchCatalogScreenState();
}

class _SearchCatalogScreenState extends State<SearchCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      bookProvider.fetchBooks();
    });
    _searchController.addListener(_filterBooks);
  }

  void _filterBooks() {
    final query = _searchController.text;
    Provider.of<BookProvider>(context, listen: false).searchBooks(query);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterBooks);
    _searchController.dispose();
    super.dispose();
  }

  void _addNewBook() {
    context.push('/staff/books/add');
  }

  void _navigateToBookDetail(BookModel book) {
    context.push('/staff/catalog/book-detail', extra: book);
  }

  Color _getStatusColor(String? status) {
    if (status == 'Available') {
      return AppColors.success;
    } else if (status == 'Borrowed' || status == 'Loaned') { // Assuming 'Loaned' is a status
      return AppColors.warning;
    } else if (status == 'Lost' || status == 'Maintenance' || status == 'Reserved') {
      return AppColors.info;
    }
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);
    final searchResults = bookProvider.filteredBooks;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Search Catalog', style: TextStyle(color: AppColors.textColorLight)),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: AppColors.textColorLight),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add New Book',
            onPressed: _addNewBook,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textColorDark),
              decoration: InputDecoration(
                hintText: 'Search by title, author, ISBN, code...',
                hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.7)),
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
            child: bookProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
                : searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'Enter a search term to find books.'
                              : 'No books found matching your search.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textColorDark.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final book = searchResults[index];
                          return Card(
                            color: AppColors.cardBackgroundColor,
                            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12.0),
                              leading: Container(
                                width: 50,
                                height: 75,
                                decoration: BoxDecoration(
                                  color: AppColors.lightGray,
                                  borderRadius: BorderRadius.circular(4.0),
                                  image: book.coverUrl != null && book.coverUrl!.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(book.coverUrl!),
                                          fit: BoxFit.cover,
                                          onError: (exception, stackTrace) {
                                            // Error handled by child icon
                                          },
                                        )
                                      : null,
                                ),
                                child: (book.coverUrl == null || book.coverUrl!.isEmpty)
                                    ? const Icon(Icons.book_outlined, color: AppColors.primaryColor, size: 30)
                                    : null,
                              ),
                              title: Text(
                                book.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textColorDark,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    book.author,
                                    style: TextStyle(
                                      color: AppColors.textColorDark.withOpacity(0.8),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Code: ${book.code} / Year: ${book.publishedYear?.toString() ?? 'N/A'}', // Corrected to use publishedYear
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                   Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(book.status).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      book.status ?? 'Unknown',
                                      style: TextStyle(
                                        color: _getStatusColor(book.status),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
                                ],
                              ),
                              onTap: () => _navigateToBookDetail(book),
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
