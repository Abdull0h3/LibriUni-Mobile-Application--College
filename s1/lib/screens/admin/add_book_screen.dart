import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../providers/book_provider.dart';
import '../../models/book.dart';

class AddBookScreen extends StatefulWidget {
  final Book? book; // Pass book for editing, null for adding
  const AddBookScreen({Key? key, this.book}) : super(key: key);

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _shelfController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _coverUrlController = TextEditingController();
  DateTime _publishedDate = DateTime.now();
  bool _isAvailable = true;
  bool _isLoading = false;

  // Book from route extra
  Book? _book;
  bool _didInitialize = false;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _populateFormIfEditing();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitialize) {
      final Object? extra = GoRouterState.of(context).extra;
      if (extra != null && extra is Book && _book == null) {
        _book = extra;
        _populateFormIfEditing();
      }
      _didInitialize = true;
    }
  }

  void _populateFormIfEditing() {
    if (_book != null) {
      _titleController.text = _book!.title;
      _authorController.text = _book!.author;
      _categoryController.text = _book!.category;
      _shelfController.text = _book!.shelf;
      _descriptionController.text = _book!.description ?? '';
      _coverUrlController.text = _book!.coverUrl ?? '';
      _publishedDate = _book!.publishedDate;
      _isAvailable = _book!.isAvailable;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _categoryController.dispose();
    _shelfController.dispose();
    _descriptionController.dispose();
    _coverUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _publishedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _publishedDate) {
      setState(() {
        _publishedDate = picked;
      });
    }
  }

  Future<void> _saveBook() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final bookProvider = Provider.of<BookProvider>(context, listen: false);

      final book = Book(
        id: _book?.id ?? '', // Empty for new books, will be set by Firestore
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        category: _categoryController.text.trim(),
        shelf: _shelfController.text.trim(),
        isAvailable: _isAvailable,
        publishedDate: _publishedDate,
        description: _descriptionController.text.trim(),
        coverUrl:
            _coverUrlController.text.trim().isEmpty
                ? null
                : _coverUrlController.text.trim(),
      );

      bool success;
      if (_book == null) {
        // Add new book
        success = await bookProvider.addBook(book);
      } else {
        // Update existing book
        success = await bookProvider.updateBook(book);
      }

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_book == null ? 'Book added' : 'Book updated'} successfully',
            ),
          ),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              bookProvider.error ??
                  'Failed to ${_book == null ? 'add' : 'update'} book',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_book == null ? 'Add New Book' : 'Edit Book'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Book cover preview (if URL provided)
              if (_coverUrlController.text.isNotEmpty)
                Container(
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _coverUrlController.text,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter book title',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Author
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: 'Author',
                  hintText: 'Enter author name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an author';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Category
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'Enter book category',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Shelf
              TextFormField(
                controller: _shelfController,
                decoration: const InputDecoration(
                  labelText: 'Shelf',
                  hintText: 'Enter shelf location',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a shelf location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Published Date
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Published Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_publishedDate.day}/${_publishedDate.month}/${_publishedDate.year}',
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Cover URL
              TextFormField(
                controller: _coverUrlController,
                decoration: const InputDecoration(
                  labelText: 'Cover URL (Optional)',
                  hintText: 'Enter URL for book cover image',
                ),
                onChanged: (value) {
                  // Trigger rebuild to show preview if URL is entered
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Enter book description',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // Available switch
              Row(
                children: [
                  const Text('Available for borrowing'),
                  const Spacer(),
                  Switch(
                    value: _isAvailable,
                    onChanged: (value) {
                      setState(() {
                        _isAvailable = value;
                      });
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Submit button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveBook,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                          _book == null ? 'Add Book' : 'Update Book',
                          style: const TextStyle(fontSize: 16),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
