// lib/screens/manage_fines_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/constants/app_colors.dart';
import '/models/fine_model.dart'; // Your new FineModel
import '/models/loan_model.dart';
import '/models/book_model.dart';
import '/models/user_model.dart';
// The FineDetailModel is now for UI display, enriched from FineModel
import '/models/fine_detail_model.dart';

import '/services/fine_service.dart';
import '/services/loan_service.dart';
import '/services/book_service.dart';
import '/services/user_service.dart';

class ManageFinesScreen extends StatefulWidget {
  const ManageFinesScreen({super.key});

  @override
  State<ManageFinesScreen> createState() => _ManageFinesScreenState();
}

class _ManageFinesScreenState extends State<ManageFinesScreen> {
  final FineService _fineService = FineService();
  final LoanService _loanService = LoanService();
  final BookService _bookService = BookService();
  final UserService _userService = UserService();

  List<FineDetailModel> _allFineDetails = [];
  List<FineDetailModel> _filteredFineDetails = [];

  bool _isLoading = true;
  bool _isSyncing = false; // For the initial sync process
  String _errorMessage = '';

  StreamSubscription? _finesSubscription;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
  );
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_performSearch);
    _initializeFinesData();
  }

  Future<void> _initializeFinesData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true; // General loading for stream setup
      _isSyncing = true; // Specific flag for the sync part
      _errorMessage = '';
    });

    try {
      // 1. Synchronize overdue loans to the 'fines' collection
      await _synchronizeOverdueLoansToFinesCollection();
      if (!mounted) return;
      setState(() {
        _isSyncing = false;
      });

      // 2. Listen to the 'fines' collection for unpaid fines
      _finesSubscription?.cancel(); // Cancel any previous subscription
      _finesSubscription = _fineService.getUnpaidFinesStream().listen(
        (List<FineModel> unpaidFines) async {
          if (!mounted) return;
          List<FineDetailModel> details = [];
          // Fetch user and book details for each FineModel to create FineDetailModel
          for (var fineModel in unpaidFines) {
            // It's more efficient to batch these fetches if possible,
            // but for simplicity, fetching one by one.
            final user = await _userService.getUserById(fineModel.userID);
            final book = await _bookService.getBookById(fineModel.bookID);

            if (user != null && book != null) {
              details.add(
                FineDetailModel(
                  // Pass the FineModel's ID to be used when paying
                  fineDocId: fineModel.id,
                  loanId: fineModel.loanID, // Store loanId from FineModel
                  book: book, // Full BookModel
                  user: user, // Full LibriUniUser
                  daysOverdue: fineModel.daysOverdue, // From FineModel
                  fineAmount: fineModel.fineAmount, // From FineModel
                  // Add other fields to FineDetailModel if needed from FineModel (like createdDate)
                ),
              );
            } else {
              print(
                "Could not find user (${fineModel.userID}) or book (${fineModel.bookID}) for fine ${fineModel.id}",
              );
            }
          }
          if (mounted) {
            setState(() {
              _allFineDetails = details;
              _performSearch(); // Apply current search
              _isLoading = false; // Overall loading done
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _errorMessage = "Error fetching fines: ${error.toString()}";
              _isLoading = false;
              _isSyncing = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Initialization error: ${e.toString()}";
          _isLoading = false;
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _synchronizeOverdueLoansToFinesCollection() async {
    // This stream gives ALL overdue loans. We process them once.
    // Consider if this should be a one-time fetch: .get() instead of .listen()
    // TODO: note
    final overdueLoansCompleter = Completer<List<LoanModel>>();
    StreamSubscription? tempLoanSub;

    tempLoanSub = _loanService.getOverdueLoansStream().listen(
      (loans) {
        if (!overdueLoansCompleter.isCompleted) {
          overdueLoansCompleter.complete(loans);
        }
        tempLoanSub?.cancel(); // We only need the first emission for this sync
      },
      onError: (e) {
        if (!overdueLoansCompleter.isCompleted) {
          overdueLoansCompleter.completeError(e);
        }
        tempLoanSub?.cancel();
      },
    );

    List<LoanModel> activeOverdueLoans;
    try {
      activeOverdueLoans = await overdueLoansCompleter.future.timeout(
        const Duration(seconds: 20),
      );
    } catch (e) {
      print("Error or timeout fetching overdue loans for sync: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Could not sync fines: Error fetching loans.";
        });
      }
      return; // Stop sync if loans can't be fetched
    }

    for (var loan in activeOverdueLoans) {
      if (!mounted) break; // Check mounted state in long loops
      final book = await _bookService.getBookById(loan.bookId);
      final user = await _userService.getUserById(
        loan.userId,
      ); // loan.userId should be doc ID

      if (book != null && user != null) {
        try {
          await _fineService.ensureFineRecord(
            loan: loan,
            book: book,
            user: user,
          );
        } catch (e) {
          print("Error ensuring fine record for loan ${loan.id}: $e");
          // Continue to next loan, but log error
        }
      } else {
        print(
          "Skipping fine sync for loan ${loan.id}: Missing book or user details.",
        );
      }
    }
    print("Fine synchronization process complete.");
  }

  void _performSearch() {
    final query = _searchController.text.toLowerCase();
    if (!mounted) return;
    setState(() {
      if (query.isEmpty) {
        _filteredFineDetails = List.from(_allFineDetails);
      } else {
        _filteredFineDetails =
            _allFineDetails.where((fineDetail) {
              final userName = fineDetail.user.name.toLowerCase();
              final userIdString =
                  fineDetail.user.userIdString
                      .toLowerCase(); // Assuming FineDetailModel.user has userIdString
              return userName.contains(query) || userIdString.contains(query);
            }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_performSearch);
    _searchController.dispose();
    _finesSubscription?.cancel();
    super.dispose();
  }

  // This method now orchestrates all updates
  Future<void> _processFinePayment(FineDetailModel fineDetail) async {
    // fineDetail now includes fineDocId
    try {
      final now = Timestamp.now();

      // 1. Update the 'fines' Collection Record (using fineDetail.fineDocId)
      await _fineService.markFineDocumentAsPaid(fineDetail.fineDocId, now);

      // 2. Update the Loan: Mark as returned/settled (using fineDetail.loanId)
      await _loanService.updateLoanReturnDate(fineDetail.loanId, now);

      // 3. Update Book Status: Mark as "Available" (using fineDetail.book.id)
      await _bookService.updateBookStatus(fineDetail.book.id, 'Available');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fine for ${fineDetail.book.title} by ${fineDetail.user.name} paid successfully.',
            ),
            backgroundColor: AppColors.successColor,
          ),
        );
        // The list will update automatically because of the stream on 'fines' collection.
        // Dialogs that led here should be popped by their respective callers.
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing fine payment: ${e.toString()}'),
            backgroundColor: AppColors.dangerColor,
          ),
        );
      }
      print("Error in _processFinePayment: $e");
    }
  }

  void _showFineDetailsAndPaymentDialog(FineDetailModel fineDetail) {
    // This dialog displays info from FineDetailModel
    // The 'Process Payment' button will call _confirmPaymentDialog
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Fine Details: ${fineDetail.user.name}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'User ID: ${fineDetail.user.userIdString}',
                ), // Assuming FineDetailModel.user has userIdString
                Text(
                  'Book: ${fineDetail.book.title} (${fineDetail.book.tag} Tag)',
                ),
                Text('Loan ID: ${fineDetail.loanId}'), // From FineDetailModel
                // Text('Fine Record ID: ${fineDetail.fineDocId}'), // For debugging
                Text(
                  'Days Overdue: ${fineDetail.daysOverdue}',
                ), // From FineDetailModel
                Text(
                  'Fine Amount: ${_currencyFormat.format(fineDetail.fineAmount)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successColor,
                foregroundColor: AppColors.textColorLight,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _confirmPaymentDialog(fineDetail);
              },
              child: const Text('Process Payment'),
            ),
          ],
        );
      },
    );
  }

  void _confirmPaymentDialog(FineDetailModel fineDetail) {
    showDialog(
      context: context,
      builder: (BuildContext confirmDialogContext) {
        return AlertDialog(
          title: const Text('Confirm Payment'),
          content: Text(
            'Are you sure you want to mark the fine for "${fineDetail.book.title}" (User: ${fineDetail.user.name}) as paid?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(confirmDialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
              child: const Text(
                'Confirm Payment',
                style: TextStyle(color: AppColors.textColorLight),
              ),
              onPressed: () async {
                Navigator.of(confirmDialogContext).pop();
                await _processFinePayment(fineDetail);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    if (_isLoading && _isSyncing) {
      bodyContent = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Syncing fine records..."),
          ],
        ),
      );
    } else if (_isLoading) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage.isNotEmpty) {
      bodyContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage,
            style: const TextStyle(color: AppColors.dangerColor, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      bodyContent = Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(/* ... Search Bar ... */),
          ),
          if (_filteredFineDetails.isEmpty && _searchController.text.isNotEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No fines found for your search criteria.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          else if (_allFineDetails.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No unpaid fines to display.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                /* ... DataTable ... */
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
                  child: DataTable(
                    // ... columns (User Name, User ID, Book Title, Days Overdue, Fine Amount, Actions)
                    columns: const [
                      DataColumn(
                        label: Text(
                          'User Name',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColorDark,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'User ID',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColorDark,
                          ),
                        ),
                      ),
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
                          'Days Overdue',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColorDark,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Fine Amount',
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
                        _filteredFineDetails.map((fineDetail) {
                          // Use fineDetail of type FineDetailModel
                          final fineAmountColor =
                              fineDetail.daysOverdue > 10
                                  ? AppColors.dangerColor
                                  : Colors.red.shade400;
                          return DataRow(
                            cells: [
                              DataCell(Text(fineDetail.user.name)),
                              DataCell(
                                Text(fineDetail.user.userIdString),
                              ), // Assuming FineDetailModel.user has userIdString
                              DataCell(
                                Tooltip(
                                  message:
                                      "${fineDetail.book.title} (Tag: ${fineDetail.book.tag})",
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 150,
                                    ),
                                    child: Text(
                                      fineDetail.book.title,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Center(
                                  child: Text(
                                    fineDetail.daysOverdue.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  _currencyFormat.format(fineDetail.fineAmount),
                                  style: TextStyle(
                                    color: fineAmountColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const Icon(
                                    Icons.payment_outlined,
                                    color: AppColors.primaryColor,
                                    size: 26,
                                  ),
                                  tooltip: 'View Details & Process Payment',
                                  onPressed:
                                      () => _showFineDetailsAndPaymentDialog(
                                        fineDetail,
                                      ),
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
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Fines')),
      body: bodyContent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            _isSyncing ? null : _initializeFinesData, // Allow manual re-sync
        label: const Text('Refresh Fines'),
        icon:
            _isSyncing
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : const Icon(Icons.sync),
        backgroundColor: _isSyncing ? Colors.grey : AppColors.secondaryColor,
      ),
    );
  }
}
