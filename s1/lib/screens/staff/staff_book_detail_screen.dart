import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:s1/models/book_model.dart';
import 'package:s1/constants/app_colors.dart';
import 'package:go_router/go_router.dart'; // For navigation

class StaffBookDetailScreen extends StatelessWidget {
  final BookModel book;
  const StaffBookDetailScreen({super.key, required this.book});

  Color _getStatusColor(String? status) {
    if (status == 'Available') return AppColors.success;
    if (status == 'Borrowed' || status == 'Loaned') return AppColors.warning; // Assuming 'Loaned' is a status
    if (status == 'Lost' || status == 'Maintenance' || status == 'Reserved') return AppColors.info;
    return AppColors.textSecondary;
  }

  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(book.title, style: const TextStyle(color: AppColors.textColorLight)),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: AppColors.textColorLight),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_outlined),
            tooltip: 'Edit Book',
            onPressed: () {
              // Navigate to AddEditBookScreen with the book to edit
              context.push('/staff/books/edit/${book.id}', extra: book);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (book.coverUrl != null && book.coverUrl!.isNotEmpty)
              Center(
                child: Container(
                  height: 250,
                  width: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    image: DecorationImage(
                      image: NetworkImage(book.coverUrl!),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {
                        // Handled by the errorBuilder in Image.network if preferred
                      },
                    ),
                  ),
                  child: book.coverUrl == null || book.coverUrl!.isEmpty
                      ? const Icon(Icons.book_outlined, size: 100, color: AppColors.lightGray)
                      : null,
                  clipBehavior: Clip.antiAlias, // Ensures image respects border radius
                ),
              )
            else
              Center(
                child: Container(
                  height: 250,
                  width: 180,
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(8),
                     boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 60, color: AppColors.textSecondary)),
                ),
              ),
            const SizedBox(height: 24),
            _buildDetailItem(label: 'Title', value: book.title, isTitle: true),
            _buildDetailItem(label: 'Author', value: book.author),
            _buildDetailItem(label: 'LibriUni Code', value: book.code),
            _buildDetailItem(label: 'ISBN', value: book.id ?? 'N/A'), // Assuming BookModel has isbn
            _buildDetailItem(label: 'Published Year', value: book.publishedYear?.toString() ?? 'N/A'),
            _buildDetailItem(label: 'Category', value: book.category ?? 'N/A'),
            _buildDetailItem(label: 'Date Added', value: _formatTimestamp(book.dateAdded?.toDate())),
            _buildDetailItem(label: 'Status', value: book.status, statusColor: _getStatusColor(book.status)),
            _buildDetailItem(label: 'Tag (Fine Group)', value: book.tag),
            const SizedBox(height: 16),
            const Text(
              'Description:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textColorDark),
            ),
            const SizedBox(height: 8),
            Text(
              book.description ?? 'No description available.',
              style: const TextStyle(fontSize: 16, color: AppColors.textColorDark, height: 1.5),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 24),
            //todo: Add staff-specific actions like "Manage Loans", "View Loan History" etc.
            //     // Navigate to loan management for this book
            //   },
            // )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({required String label, required String value, Color? statusColor, bool isTitle = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // Fixed width for labels
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: isTitle ? 18 : 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTitle ? 22 : 16,
                fontWeight: isTitle ? FontWeight.bold : FontWeight.normal,
                color: statusColor ?? AppColors.textColorDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}