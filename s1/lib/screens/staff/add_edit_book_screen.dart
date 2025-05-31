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
  late TextEditingController _coverUrlController;
  late TextEditingController _categoryController;
  late TextEditingController _descriptionController;
  String? _selectedStatus;
  String? _selectedTag;

  // No longer a fixed list for statuses here, it will be dynamic
  final List<String> _tags = ['Green', 'Yellow', 'Red'];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.bookToEdit?.title ?? '',
    );
    _authorController = TextEditingController(
      text: widget.bookToEdit?.author ?? '',
    );
    _codeController = TextEditingController(
      text: widget.bookToEdit?.code ?? '',
    );
    _publishedYearController = TextEditingController(
      text: widget.bookToEdit?.publishedYear?.toString() ?? '',
    );

    // Initialize status based on the new rules
    if (widget.bookToEdit == null) { // Adding new book
      _selectedStatus = 'Available';
    } else { // Editing existing book
      _selectedStatus = widget.bookToEdit!.status;
      // If the existing status is not 'Borrowed', 'Available', or 'Maintenance'
      // (e.g., it was 'Lost' from a previous version), default it.
      if (widget.bookToEdit!.status != 'Borrowed' &&
          !['Available', 'Maintenance'].contains(widget.bookToEdit!.status)) {
        _selectedStatus = 'Available'; // Default to 'Available'
      }
    }

    _coverUrlController = TextEditingController(
      text: widget.bookToEdit?.coverUrl ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.bookToEdit?.category ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.bookToEdit?.description ?? '',
    );
    _selectedTag = widget.bookToEdit?.tag ?? 'Green';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _codeController.dispose();
    _publishedYearController.dispose();
    _coverUrlController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveBook() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final String bookCode = _codeController.text.trim();

      if (widget.bookToEdit == null) {
        final existingBook = await _bookService.getBookByCode(bookCode);
        if (existingBook != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: Book code "$bookCode" already exists.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      } else if (widget.bookToEdit != null &&
          widget.bookToEdit!.code != bookCode) {
        final existingBook = await _bookService.getBookByCode(bookCode);
        if (existingBook != null && existingBook.id != widget.bookToEdit!.id) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error: Book code "$bookCode" already exists for another book.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      final bookData = BookModel(
        id: widget.bookToEdit?.id ?? '',
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        code: bookCode,
        status: _selectedStatus!,
        publishedYear: _publishedYearController.text.isNotEmpty
            ? int.tryParse(_publishedYearController.text.trim())
            : null,
        dateAdded: widget.bookToEdit?.dateAdded ?? Timestamp.now(),
        coverUrl: _coverUrlController.text.trim().isNotEmpty ? _coverUrlController.text.trim() : null,
        category: _categoryController.text.trim().isNotEmpty ? _categoryController.text.trim() : null,
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        tag: _selectedTag!,
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
              content: Text(
                'Book ${widget.bookToEdit == null ? "added" : "updated"} successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving book: $e'),
              backgroundColor: Colors.red,
            ),
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
    List<String> currentStatusOptions;
    if (widget.bookToEdit != null && widget.bookToEdit!.status == 'Borrowed') {
      currentStatusOptions = ['Borrowed', 'Maintenance'];
      // Ensure _selectedStatus is valid for this case
      if (_selectedStatus != 'Borrowed' && _selectedStatus != 'Maintenance') {
        _selectedStatus = 'Borrowed'; // Default to borrowed if somehow it's not
      }
    } else {
      currentStatusOptions = ['Available', 'Maintenance'];
      // Ensure _selectedStatus is valid for this case
      if (_selectedStatus != 'Available' && _selectedStatus != 'Maintenance') {
         // This might happen if the book was 'Borrowed' and user changed it,
         // or if it was an old status like 'Lost'.
         // If it's not 'Borrowed' anymore, it should be 'Available' or 'Maintenance'.
        _selectedStatus = 'Available';
      }
    }

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
                    decoration: const InputDecoration(
                      labelText: 'Book Title',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Please enter the book title' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _authorController,
                    decoration: const InputDecoration(
                      labelText: 'Author',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Please enter the author' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Book Code (e.g., DS101)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.qr_code_scanner_outlined),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Please enter the book code' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _publishedYearController,
                    decoration: const InputDecoration(
                      labelText: 'Published Year (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
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
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _coverUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Cover Image URL (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.image_outlined),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description_outlined),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    textInputAction: TextInputAction.newline,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedTag,
                    decoration: const InputDecoration(
                      labelText: 'Tag (Fine Group)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    items: _tags.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) => setState(() => _selectedTag = newValue),
                    validator: (value) => value == null ? 'Please select a tag' : null,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus, // This should now be correctly one of the currentStatusOptions
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.check_circle_outline),
                    ),
                    items: currentStatusOptions.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
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
                      textStyle: const TextStyle(
                        fontSize: 18,
                        color: AppColors.textColorDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textColorDark,
                              ),
                            ),
                          )
                        : Text(
                            widget.bookToEdit == null ? 'Add Book' : 'Save Changes',
                            style: const TextStyle(
                              color: AppColors.textColorDark,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.secondaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
