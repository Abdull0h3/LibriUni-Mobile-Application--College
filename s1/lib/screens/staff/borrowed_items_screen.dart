// lib/screens/borrowed_items_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '/constants/app_colors.dart';
import '/models/loan_model.dart';
import '/models/book_model.dart';
import '/services/loan_service.dart';
import '/services/book_service.dart';

// UI model for a single borrowed item, now including borrowerName for search
class BorrowedItemModel {
  final String bookTitle;
  final String code;
  final String isbn;
  final String borrowerId;
  final String borrowerName;
  final DateTime loanDate;
  final bool isOverdue;

  BorrowedItemModel({
    required this.bookTitle,
    required this.code,
    required this.isbn,
    required this.borrowerId,
    required this.borrowerName,
    required this.loanDate,
    required this.isOverdue,
  });
}

class BorrowedItemsScreen extends StatefulWidget {
  const BorrowedItemsScreen({super.key});

  @override
  State<BorrowedItemsScreen> createState() => _BorrowedItemsScreenState();
}

class _BorrowedItemsScreenState extends State<BorrowedItemsScreen> {
  final TextEditingController _searchController = TextEditingController();

  final LoanService _loanService = LoanService();
  final BookService _bookService = BookService();

  late StreamSubscription<List<LoanModel>> _loansSub;
  late StreamSubscription<List<BookModel>> _booksSub;

  List<LoanModel> _loans = [];
  Map<String, BookModel> _booksMap = {};
  List<BorrowedItemModel> _allBorrowedItems = [];
  List<BorrowedItemModel> _filteredBorrowedItems = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_performSearch);

    // Subscribe to books collection
    _booksSub = _bookService.getBooksStream().listen((books) {
      _booksMap = {for (var b in books) b.id: b};
      _rebuildItems();
    });

    // Subscribe to active loans
    _loansSub = _loanService.getActiveLoansStream().listen((loans) {
      _loans = loans;
      _rebuildItems();
    });
  }

  void _rebuildItems() {
    final now = DateTime.now();
    final items = <BorrowedItemModel>[];

    for (var loan in _loans) {
      final book = _booksMap[loan.bookId];
      items.add(
        BorrowedItemModel(
          bookTitle: loan.bookTitle,
          code: book?.code ?? '',
          isbn: loan.bookId,
          borrowerId: loan.userId,
          borrowerName: loan.userName,
          loanDate: loan.loanDate.toDate(),
          isOverdue: loan.isOverdue,
        ),
      );
    }

    setState(() {
      _allBorrowedItems = items;
      _filteredBorrowedItems = _applySearch(items, _searchController.text);
    });
  }

  List<BorrowedItemModel> _applySearch(
    List<BorrowedItemModel> items,
    String query,
  ) {
    final q = query.toLowerCase();
    if (q.isEmpty) return items;
    return items.where((item) {
      return item.bookTitle.toLowerCase().contains(q) ||
          item.code.toLowerCase().contains(q) ||
          item.isbn.toLowerCase().contains(q) ||
          item.borrowerId.toLowerCase().contains(q) ||
          item.borrowerName.toLowerCase().contains(q);
    }).toList();
  }

  void _performSearch() {
    setState(() {
      _filteredBorrowedItems = _applySearch(
        _allBorrowedItems,
        _searchController.text,
      );
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_performSearch);
    _searchController.dispose();
    _booksSub.cancel();
    _loansSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrowed Items'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textColorLight,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                    'Search by book, user ID, ISBN, code, or user name...',
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
            child: _filteredBorrowedItems.isEmpty
                ? const Center(child: Text('No borrowed items found.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    itemCount: _filteredBorrowedItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredBorrowedItems[index];
                      
                      Color borderColor;
                      String overdueStatusText;
                      IconData statusIcon;

                      if (item.isOverdue) {
                        borderColor = AppColors.dangerColor; // Red outline
                        overdueStatusText = 'OVERDUE';
                        statusIcon = Icons.warning_amber_rounded;
                      } else {
                        borderColor = AppColors.successColor; // Green outline
                        overdueStatusText = 'On Loan';
                        statusIcon = Icons.check_circle_outline_rounded;
                      }

                      return Card(
                        elevation: 3.0,
                        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          side: BorderSide(color: borderColor, width: 1.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.bookTitle,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: AppColors.textColorDark,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                    decoration: BoxDecoration(
                                      color: borderColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(statusIcon, color: borderColor, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          overdueStatusText,
                                          style: TextStyle(
                                            color: borderColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              _buildDetailRow('Borrower:', item.borrowerName),
                              _buildDetailRow('Borrower ID:', item.borrowerId),
                              const Divider(height: 12, thickness: 0.5),
                              _buildDetailRow('Book Code:', item.code),
                              _buildDetailRow('ISBN:', item.isbn),
                              _buildDetailRow('Loan Date:', '${item.loanDate.day}/${item.loanDate.month}/${item.loanDate.year}'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Helper widget to build detail rows consistently
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textColorDark.withOpacity(0.8),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
