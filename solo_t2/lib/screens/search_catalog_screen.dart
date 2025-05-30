// lib/screens/search_catalog_screen.dart
import 'package:flutter/material.dart';
import '/constants/app_colors.dart';

// Mock Data Model
class BookSearchResult {
  final String title;
  final String author;
  final String availability; // e.g., "Available", "Loaned"
  final String publishedDate;

  BookSearchResult({
    required this.title,
    required this.author,
    required this.availability,
    required this.publishedDate,
  });
}

class SearchCatalogScreen extends StatefulWidget {
  const SearchCatalogScreen({super.key});

  @override
  State<SearchCatalogScreen> createState() => _SearchCatalogScreenState();
}

class _SearchCatalogScreenState extends State<SearchCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<BookSearchResult> _searchResults = [];
  List<BookSearchResult> _allBooks = [ // Replace with actual data source
    BookSearchResult(title: 'Data Science 101', author: 'Dr. Foo Bar', availability: 'Available', publishedDate: 'Jan 15, 2024'),
    BookSearchResult(title: 'AI Fundamentals', author: 'Jane Doe', availability: 'Loaned', publishedDate: 'Dec 22, 2023'),
    BookSearchResult(title: 'Programming 101', author: 'John Smith', availability: 'Available', publishedDate: 'Sep 8, 2023'),
    BookSearchResult(title: 'Advanced Algorithms', author: 'Alice Brown', availability: 'Available', publishedDate: 'Mar 10, 2024'),
    BookSearchResult(title: 'Network Security', author: 'Bob Green', availability: 'Maintenance', publishedDate: 'Feb 01, 2024'),
  ];

  @override
  void initState() {
    super.initState();
    _searchResults = _allBooks; // Initially show all books
    _searchController.addListener(_filterBooks);
  }

  void _filterBooks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _searchResults = _allBooks.where((book) {
        return book.title.toLowerCase().contains(query) ||
               book.author.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterBooks);
    _searchController.dispose();
    super.dispose();
  }

  void _addNewBook() {
    // TODO: Navigate to Add/Edit Book Screen or show a dialog
    print('Add New Book tapped from Search Catalog');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to Add New Book page (not implemented yet).')),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Catalog'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textColorLight,
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
              decoration: InputDecoration(
                hintText: 'Search by book, ID, author...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryColor),
                filled: true,
                fillColor: AppColors.cardBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: const BorderSide(color: AppColors.secondaryColor, width: 2),
                ),
              ),
            ),
          ),
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Text(
                      'No books found matching your search.',
                      style: TextStyle(color: AppColors.textColorDark.withOpacity(0.7)),
                    ),
                  )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final book = _searchResults[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textColorDark)),
                    subtitle: Text('${book.author}\nPublished: ${book.publishedDate}', style: TextStyle(color: AppColors.textColorDark.withOpacity(0.8))),
                    trailing: Text(
                      book.availability,
                      style: TextStyle(
                        color: book.availability == 'Available' ? Colors.green.shade700 : (book.availability == 'Loaned' ? Colors.orange.shade700 : AppColors.textColorDark),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      // TODO: Implement view more information logic
                      print('Tapped on ${book.title}');
                       ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Details for ${book.title} (not implemented yet).')),
                      );
                    },
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