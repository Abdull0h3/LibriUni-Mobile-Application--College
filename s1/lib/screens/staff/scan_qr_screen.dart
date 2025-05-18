import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../constants/app_colors.dart';

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({Key? key}) : super(key: key);

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  String? _scannedCode;
  String? _error;
  ScanMode _currentMode = ScanMode.borrow;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _processScannedCode(String code) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _scannedCode = code;
      _error = null;
    });

    try {
      // Here you would process the QR code based on the current mode
      // For now we'll just simulate success after a delay
      await Future.delayed(const Duration(seconds: 1));

      if (_currentMode == ScanMode.borrow) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book borrowed successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (_currentMode == ScanMode.returnBook) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book returned successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book information retrieved'),
            backgroundColor: AppColors.primary,
          ),
        );
      }

      // In a real app, you might navigate to a book detail page
      // or show a success dialog
      setState(() {
        _isProcessing = false;
        _scannedCode = null;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _error = e.toString();
      });
    }
  }

  void _setMode(ScanMode mode) {
    setState(() {
      _currentMode = mode;
      _scannedCode = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Mode selector
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Mode',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildModeButton(
                        'Borrow',
                        Icons.book,
                        ScanMode.borrow,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModeButton(
                        'Return',
                        Icons.assignment_return,
                        ScanMode.returnBook,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModeButton(
                        'Info',
                        Icons.info_outline,
                        ScanMode.info,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Instructions
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            color: AppColors.primary.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.info, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getModeInstructions(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // QR Scanner
          Expanded(
            child:
                _isProcessing
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Processing: $_scannedCode',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                    : _error != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: $_error',
                            style: const TextStyle(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _error = null;
                              });
                            },
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    )
                    : Stack(
                      children: [
                        MobileScanner(
                          controller: _scannerController,
                          onDetect: (capture) {
                            final List<Barcode> barcodes = capture.barcodes;
                            if (barcodes.isNotEmpty && mounted) {
                              final code = barcodes.first.rawValue;
                              if (code != null) {
                                _processScannedCode(code);
                              }
                            }
                          },
                        ),
                        Center(
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String title, IconData icon, ScanMode mode) {
    final isSelected = _currentMode == mode;
    return ElevatedButton(
      onPressed: () => _setMode(mode),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primary : Colors.white,
        foregroundColor: isSelected ? Colors.white : AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppColors.primary, width: isSelected ? 0 : 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  String _getModeInstructions() {
    switch (_currentMode) {
      case ScanMode.borrow:
        return 'Scan the QR code on the book to borrow it.';
      case ScanMode.returnBook:
        return 'Scan the QR code on the book to return it.';
      case ScanMode.info:
        return 'Scan the QR code to view book details.';
    }
  }
}

enum ScanMode { borrow, returnBook, info }
