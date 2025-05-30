import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp
import '/models/book_model.dart';
import '/services/book_service.dart';
import '/constants/app_colors.dart';

class AddEditBookScreen extends StatefulWidget {
  final BookModel? bookToEdit;

  const AddEditBookScreen({super.key, this.bookToEdit});

  @override
  State<AddEditBookScreen> createState() => _AddEditBookScreenState();
}

class _AddEditBookScreenState extends State<AddEditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final BookService _bookService = BookService();

  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _codeController;
  late TextEditingController _publishedYearController;
  String? _selectedStatus;

  final List<String> _statuses = ['Available', 'Borrowed', 'Lost', 'Maintenance'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.bookToEdit?.title ?? '');
    _authorController = TextEditingController(text: widget.bookToEdit?.author ?? '');
    _codeController = TextEditingController(text: widget.bookToEdit?.code ?? '');
    _publishedYearController = TextEditingController(text: widget.bookToEdit?.publishedYear?.toString() ?? '');
    _selectedStatus = widget.bookToEdit?.status ?? 'Available';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _codeController.dispose();
    _publishedYearController.dispose();
    super.dispose();
  }

  Future<void> _saveBook() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final String bookCode = _codeController.text.trim();

      // Check if book code already exists when adding a new book
      if (widget.bookToEdit == null) {
        final existingBook = await _bookService.getBookByCode(bookCode);
        if (existingBook != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: Book code "$bookCode" already exists.'), backgroundColor: Colors.red),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }
      // If editing, and the code changed, check if the new code exists for another book
      else if (widget.bookToEdit != null && widget.bookToEdit!.code != bookCode) {
         final existingBook = await _bookService.getBookByCode(bookCode);
        if (existingBook != null && existingBook.id != widget.bookToEdit!.id) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: Book code "$bookCode" already exists for another book.'), backgroundColor: Colors.red),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }


      final bookData = BookModel(
        id: widget.bookToEdit?.id ?? '', // ID will be set by Firestore if new, or use existing
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        code: bookCode,
        status: _selectedStatus!,
        publishedYear: _publishedYearController.text.isNotEmpty
            ? int.tryParse(_publishedYearController.text.trim())
            : null,
        dateAdded: widget.bookToEdit?.dateAdded ?? Timestamp.now(),
      );

      try {
        if (widget.bookToEdit == null) {
          await _bookService.addBook(bookData);
        } else {
          await _bookService.updateBook(widget.bookToEdit!.id, bookData);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Book ${widget.bookToEdit == null ? "added" : "updated"} successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Pop and indicate success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving book: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bookToEdit == null ? 'Add New Book' : 'Edit Book'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textColorLight,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Book Title', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title)),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter the book title' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _authorController,
                    decoration: const InputDecoration(labelText: 'Author', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter the author' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(labelText: 'Book Code (e.g., DS101, ISBN)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.qr_code)),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter the book code' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _publishedYearController,
                    decoration: const InputDecoration(labelText: 'Published Year (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today_outlined)),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                        return 'Please enter a valid year';
                      }
                      if (value != null && value.isNotEmpty && value.length != 4 && int.tryParse(value) != null) {
                        return 'Year should be 4 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder(), prefixIcon: Icon(Icons.check_circle_outline)),
                    items: _statuses.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (String? newValue) => setState(() => _selectedStatus = newValue),
                    validator: (value) => value == null ? 'Please select a status' : null,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18, color: AppColors.textColorDark, fontWeight: FontWeight.bold),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(AppColors.textColorDark)))
                        : Text(widget.bookToEdit == null ? 'Add Book' : 'Save Changes', style: const TextStyle(color: AppColors.textColorDark)),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator(color: AppColors.secondaryColor)),
            ),
        ],
      ),
    );
  }
}