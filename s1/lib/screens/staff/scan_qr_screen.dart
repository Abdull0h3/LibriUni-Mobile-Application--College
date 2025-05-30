import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Import mobile_scanner
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp
import 'package:intl/intl.dart';
import '/models/book_model.dart';
import '/models/loan_model.dart';
import '/services/book_service.dart';
import '/services/loan_service.dart';
import '/routes/app_router.dart'; // For navigation
import '/constants/app_colors.dart';
import 'package:go_router/go_router.dart';

enum ScanScreenState { scanning, bookFound, bookNotFound, error, processing }

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final BookService _bookService = BookService();
  final LoanService _loanService = LoanService();
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal, // or .noDuplicates
    // facing: CameraFacing.back,
    // torchEnabled: false,
  );

  ScanScreenState _screenState = ScanScreenState.scanning;
  BookModel? _scannedBook;
  LoanModel? _activeLoan;
  String _errorMessage = "";
  String? _lastScannedCode; // To prevent immediate re-scan of the same code

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _processScannedCode(String code) async {
    if (_screenState == ScanScreenState.processing || code == _lastScannedCode)
      return;

    setState(() {
      _screenState = ScanScreenState.processing;
      _lastScannedCode = code; // Store last scanned code
    });

    try {
      // Assuming QR code contains the Book's unique 'code' (e.g., DS101)
      final book = await _bookService.getBookByCode(code);

      if (book != null) {
        final loan = await _loanService.getActiveLoanForBook(book.id);
        setState(() {
          _scannedBook = book;
          _activeLoan = loan;
          _screenState = ScanScreenState.bookFound;
        });
      } else {
        setState(() {
          _screenState = ScanScreenState.bookNotFound;
          _errorMessage = 'Book with code "$code" not found in the system.';
        });
      }
    } catch (e) {
      print("Error processing scanned code: $e");
      setState(() {
        _screenState = ScanScreenState.error;
        _errorMessage = 'An error occurred: ${e.toString()}';
      });
    }
    // Allow re-scanning after a short delay or when user explicitly tries again
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted &&
          (_screenState == ScanScreenState.bookNotFound ||
              _screenState == ScanScreenState.error)) {
        _lastScannedCode = null; // Clear last scanned code to allow re-scan
      }
    });
  }

  Future<void> _handleReceiveBook() async {
    if (_scannedBook == null || _activeLoan == null) return;

    setState(() => _screenState = ScanScreenState.processing);
    try {
      await _loanService.returnBook(_activeLoan!.id, _scannedBook!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Book "${_scannedBook!.title}" received successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _resetToScanning();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error receiving book: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(
          () => _screenState = ScanScreenState.bookFound,
        ); // Revert to previous state
      }
    }
  }

  void _handleLoanBook() {
    if (_scannedBook != null) {
      context.push('/staff/loan-form', extra: _scannedBook).then((_) {
        _resetToScanning(); // Reset after returning from loan form
      });
    }
  }

  void _resetToScanning() {
    setState(() {
      _screenState = ScanScreenState.scanning;
      _scannedBook = null;
      _activeLoan = null;
      _errorMessage = "";
      _lastScannedCode = null; // Allow new scans
      // Restart camera if it was stopped
      // cameraController.start();
      /// Checks whether the scanner is currently starting.
      // TODO: Optionally check if the scanner is starting before restarting it.
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: AppColors.primaryColor,
        actions: [
          if (_screenState != ScanScreenState.scanning &&
              _screenState != ScanScreenState.processing)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: 'Scan Another Book',
              onPressed: _resetToScanning,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  String _getAppBarTitle() {
    switch (_screenState) {
      case ScanScreenState.scanning:
      case ScanScreenState.processing:
        return 'Scan Book QR Code';
      case ScanScreenState.bookFound:
        return 'Book Details';
      case ScanScreenState.bookNotFound:
      case ScanScreenState.error:
        return 'Scan Result';
      default:
        return 'Scan Book';
    }
  }

  Widget _buildBody() {
    switch (_screenState) {
      case ScanScreenState.processing:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.secondaryColor),
        );
      case ScanScreenState.scanning:
        return Column(
          children: [
            Expanded(
              flex: 5,
              child: MobileScanner(
                controller: cameraController,
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                    if (mounted && (_screenState == ScanScreenState.scanning)) {
                      // Process only if in scanning state
                      _processScannedCode(barcodes.first.rawValue!);
                    }
                  }
                },
                // Fit the camera preview to the container
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Align QR code within the frame to scan.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textColorDark.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      case ScanScreenState.bookFound:
        return _buildBookDetailsView();
      case ScanScreenState.bookNotFound:
      case ScanScreenState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _screenState == ScanScreenState.bookNotFound
                      ? Icons.search_off
                      : Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 20),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.textColorDark,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Try Scan Again'),
                  onPressed: _resetToScanning,
                ),
              ],
            ),
          ),
        );
      default:
        return const Center(child: Text('Unknown state'));
    }
  }

  Widget _buildBookDetailsView() {
    if (_scannedBook == null) return const Center(child: Text('No book data.'));

    final bool isBookAvailableForLoan =
        _scannedBook!.status == 'Available' && _activeLoan == null;
    final bool isBookOnLoan = _activeLoan != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _scannedBook!.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Author:', _scannedBook!.author),
              _buildInfoRow('Code:', _scannedBook!.code),
              _buildInfoRow(
                'Status:',
                _scannedBook!.status,
                valueColor:
                    _scannedBook!.status == 'Available'
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
              ),
              if (_scannedBook!.publishedYear != null)
                _buildInfoRow('Year:', _scannedBook!.publishedYear.toString()),
              const Divider(height: 30, thickness: 1),

              if (isBookOnLoan) ...[
                Text(
                  'Currently On Loan:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
                _buildInfoRow('Borrower:', _activeLoan!.userName),
                _buildInfoRow(
                  'Loan Date:',
                  DateFormat.yMMMd().format(_activeLoan!.loanDate.toDate()),
                ),
                _buildInfoRow(
                  'Due Date:',
                  DateFormat.yMMMd().format(_activeLoan!.dueDate.toDate()),
                  valueColor:
                      _activeLoan!.isOverdue ? Colors.red.shade700 : null,
                ),
                if (_activeLoan!.isOverdue)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'OVERDUE!',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                const SizedBox(height: 25),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.assignment_returned_outlined),
                    label: const Text('Receive Book (Check-In)'),
                    onPressed: _handleReceiveBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryColor,
                    ),
                  ),
                ),
              ] else if (isBookAvailableForLoan) ...[
                Text(
                  'Book is Available for Loan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 25),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.assignment_ind_outlined),
                    label: const Text('Loan This Book (Check-Out)'),
                    onPressed: _handleLoanBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryColor,
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'Book Status: ${_scannedBook!.status}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _scannedBook!.status == 'Lost'
                      ? 'This book is marked as Lost.'
                      : _scannedBook!.status == 'Maintenance'
                      ? 'This book is currently under maintenance.'
                      : 'This book is not currently available for loan processing via QR scan.',
                  style: const TextStyle(color: AppColors.textColorDark),
                ),
              ],
              const SizedBox(height: 20),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan Another Book'),
                  onPressed: _resetToScanning,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textColorDark.withOpacity(0.85),
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: valueColor ?? AppColors.textColorDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
