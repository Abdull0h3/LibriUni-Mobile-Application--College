// lib/screens/view_users_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '/constants/app_colors.dart';
import '/models/user_model.dart';
import '/services/user_service.dart';
import '/services/loan_service.dart';
import '/models/loan_model.dart';

class ViewUsersScreen extends StatefulWidget {
  const ViewUsersScreen({super.key});

  @override
  State<ViewUsersScreen> createState() => _ViewUsersScreenState();
}

class _ViewUsersScreenState extends State<ViewUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();
  final LoanService _loanService = LoanService();

  List<LibriUniUser> _allUsers = [];
  List<LibriUniUser> _filteredUsers = [];
  List<LoanModel> _activeLoans = [];
  Map<String, int> _overdueCounts = {};

  late StreamSubscription<List<LibriUniUser>> _usersSub;
  late StreamSubscription<List<LoanModel>> _loansSub;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_performSearch);

    // Subscribe to user stream
    _usersSub = _userService.getUsersStream().listen((users) {
      setState(() {
        _allUsers = users;
        _filteredUsers = _applySearch(users, _searchController.text);
      });
    });

    // Subscribe to active loans stream to compute overdue counts
    _loansSub = _loanService.getActiveLoansStream().listen((loans) {
      final now = DateTime.now();
      final counts = <String, int>{};
      for (final loan in loans) {
        if (loan.dueDate.toDate().isBefore(now)) {
          counts[loan.userId] = (counts[loan.userId] ?? 0) + 1;
        }
      }
      setState(() {
        _activeLoans = loans;
        _overdueCounts = counts;
      });
    });
  }

  List<LibriUniUser> _applySearch(List<LibriUniUser> users, String query) {
    final q = query.toLowerCase();
    if (q.isEmpty) return users;
    return users.where((user) {
      return user.name.toLowerCase().contains(q) ||
          user.userIdString.toLowerCase().contains(q) ||
          user.email.toLowerCase().contains(q);
    }).toList();
  }

  void _performSearch() {
    setState(() {
      _filteredUsers = _applySearch(_allUsers, _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_performSearch);
    _searchController.dispose();
    _usersSub.cancel();
    _loansSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Users'),
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
                hintText: 'Search by name, user ID, or email...',
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
            child: _filteredUsers.isEmpty
                ? const Center(child: Text('No users found.'))
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final overdueCount = _overdueCounts[user.id] ?? 0;
                      final overdueStatusText = overdueCount == 0
                          ? 'None Overdue'
                          : '$overdueCount item${overdueCount > 1 ? 's' : ''} overdue';
                      final overdueStatusColor = overdueCount == 0
                          ? Colors.green.shade700
                          : Colors.red.shade700;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                        elevation: 2.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12.0),
                          leading: Icon(
                            user.isActive ? Icons.check_circle : Icons.cancel,
                            color: user.isActive ? Colors.green.shade600 : Colors.red.shade600,
                            size: 36.0,
                          ),
                          title: Text(
                            user.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textColorDark,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 4.0),
                              Text(
                                'ID: ${user.userIdString}',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                user.email,
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: overdueStatusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Text(
                              overdueStatusText,
                              style: TextStyle(
                                color: overdueStatusColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          onTap: () {
                            // Optional: Implement navigation to a user detail screen
                            // or show a dialog with more actions.
                            print('Tapped on user: ${user.name}');
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
