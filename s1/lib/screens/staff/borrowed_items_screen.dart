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
            child:
                _filteredBorrowedItems.isEmpty
                    ? const Center(child: Text('No borrowed items found.'))
                    : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: DataTable(
                          columnSpacing: 12.0,
                          dataRowMinHeight: 48.0,
                          dataRowMaxHeight: 60.0,
                          headingRowColor: MaterialStateColor.resolveWith(
                            (_) => AppColors.primaryColor.withOpacity(0.1),
                          ),
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Book Title',
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
                                'ISBN',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textColorDark,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Borrower ID',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textColorDark,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Loan Date',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textColorDark,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Overdue',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textColorDark,
                                ),
                              ),
                            ),
                          ],
                          rows:
                              _filteredBorrowedItems.map((item) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 150,
                                        ),
                                        child: Text(
                                          item.bookTitle,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.textColorDark,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        item.code,
                                        style: const TextStyle(
                                          color: AppColors.textColorDark,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        item.isbn,
                                        style: const TextStyle(
                                          color: AppColors.textColorDark,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        item.borrowerId,
                                        style: const TextStyle(
                                          color: AppColors.textColorDark,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '${item.loanDate.day}/${item.loanDate.month}/${item.loanDate.year}',
                                        style: const TextStyle(
                                          color: AppColors.textColorDark,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Icon(
                                        item.isOverdue
                                            ? Icons.cancel
                                            : Icons.check_circle,
                                        color:
                                            item.isOverdue
                                                ? AppColors.dangerColor
                                                : AppColors.successColor,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
