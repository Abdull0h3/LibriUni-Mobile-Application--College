import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '/models/book_model.dart';
import '/models/loan_model.dart';
import '/models/user_model.dart';
import '/services/loan_service.dart';
import '/services/user_service.dart';
import '/constants/app_colors.dart';

class LoanFormScreen extends StatefulWidget {
  final BookModel book;
  const LoanFormScreen({required this.book, super.key});

  @override
  State<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends State<LoanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final LoanService _loanService = LoanService();
  final UserService _userService = UserService(); // To search for users

  final TextEditingController _userIdStringController = TextEditingController();
  LibriUniUser? _selectedUser;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14)); // Default 2 weeks
  bool _isLoading = false;
  String _userSearchQuery = "";
  List<LibriUniUser> _userSearchResults = [];

  Future<void> _searchUser() async {
    if (_userIdStringController.text.trim().isEmpty) {
      setState(() => _userSearchResults = []);
      return;
    }
    setState(() => _isLoading = true);
    // A simple search by User ID String, Name, or Email
    //todo: can???
    _userService.searchUsersStream(_userIdStringController.text.trim()).listen((users) {
      if (mounted) {
        setState(() {
          _userSearchResults = users;
          _isLoading = false;
        });
      }
    }).onError((error) {
       if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching users: $error'), backgroundColor: Colors.red),
        );
      }
    });
  }


  Future<void> _submitLoan() async {
    if (_formKey.currentState!.validate() && _selectedUser != null) {
      if (widget.book.status != 'Available') {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Book "${widget.book.title}" is not available for loan.'), backgroundColor: Colors.orange),
        );
        return;
      }

      setState(() => _isLoading = true);

      final newLoan = LoanModel(
        id: '', // Firestore will generate
        bookId: widget.book.id,
        bookTitle: widget.book.title,
        userId: _selectedUser!.id,
        userName: _selectedUser!.name,
        loanDate: Timestamp.now(),
        dueDate: Timestamp.fromDate(_dueDate),
      );

      try {
        await _loanService.createLoan(newLoan);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Book "${widget.book.title}" loaned to ${_selectedUser!.name} successfully!'), backgroundColor: Colors.green),
          );
          // Pop twice: once for loan form, once for scan screen to go back to dashboard/previous
          int popCount = 0;
          Navigator.of(context).popUntil((_) => popCount++ >=2);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating loan: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else if (_selectedUser == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a user.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loan Book: ${widget.book.title}'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView( // Changed to ListView for better scrolling with search results
                children: [
                  Text('Book: ${widget.book.title}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Author: ${widget.book.author}'),
                  Text('Status: ${widget.book.status}', style: TextStyle(color: widget.book.status == 'Available' ? Colors.green : Colors.orange)),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _userIdStringController,
                    decoration: InputDecoration(
                      labelText: 'Search User (ID, Name, Email)',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.person_search),
                        onPressed: _searchUser,
                      )
                    ),
                    onChanged: (value) {
                      // Optional: auto-search as user types
                      // if (value.length > 2) _searchUser();
                    },
                     validator: (value) {
                      if (_selectedUser == null && (value == null || value.isEmpty)) {
                        return 'Please search and select a user';
                      }
                      return null;
                    }
                  ),
                  if (_userSearchResults.isNotEmpty && _selectedUser == null)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150), // Limit height of results
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _userSearchResults.length,
                        itemBuilder: (context, index) {
                          final user = _userSearchResults[index];
                          return ListTile(
                            title: Text(user.name),
                            subtitle: Text('${user.userIdString} - ${user.email}'),
                            onTap: () {
                              setState(() {
                                _selectedUser = user;
                                _userIdStringController.text = "${user.name} (${user.userIdString})"; // Display selected user
                                _userSearchResults = []; // Clear search results
                              });
                            },
                          );
                        },
                      ),
                    ),
                  
                  if (_selectedUser != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Chip(
                        avatar: const Icon(Icons.check_circle, color: Colors.green),
                        label: Text('Selected User: ${_selectedUser!.name} (${_selectedUser!.userIdString})'),
                        onDeleted: () {
                          setState(() {
                            _selectedUser = null;
                            _userIdStringController.clear();
                          });
                        },
                      ),
                    ),
                  const SizedBox(height: 20),

                  ListTile(
                    title: Text('Due Date: ${DateFormat.yMMMd().format(_dueDate)}'),
                    trailing: const Icon(Icons.calendar_today, color: AppColors.primaryColor),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _dueDate,
                        firstDate: DateTime.now().add(const Duration(days: 1)), // Due date must be in the future
                        lastDate: DateTime.now().add(const Duration(days: 365)), // Max 1 year loan
                      );
                      if (pickedDate != null && pickedDate != _dueDate) {
                        setState(() {
                          _dueDate = pickedDate;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.assignment_turned_in_outlined),
                    label: const Text('Confirm Loan'),
                    onPressed: _isLoading || widget.book.status != 'Available' ? null : _submitLoan,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
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