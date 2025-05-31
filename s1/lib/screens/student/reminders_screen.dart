// Made by Faisal: Updated for dark mode support and improved reminders UI with colored tags and book covers.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../models/book_model.dart';
import '../../widgets/student_nav_bar.dart';
import '../../screens/student/book_detail_screen.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: userId == null
          ? const Center(child: Text('Please login to view reminders'))
          : StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('loans')
                  .where('userId', isEqualTo: userId)
                  .where('returnDate', isNull: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: \\${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                List<Widget> reminderTiles = [];
                for (final doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final bookId = data['bookId'] as String?;
                  if (bookId == null) continue;
                  final dueDateRaw = data['dueDate'];
                  DateTime? dueDate;
                  if (dueDateRaw is Timestamp) {
                    dueDate = dueDateRaw.toDate();
                  } else if (dueDateRaw is DateTime) {
                    dueDate = dueDateRaw;
                  } else if (dueDateRaw is String) {
                    try {
                      dueDate = DateTime.parse(dueDateRaw);
                    } catch (_) {}
                  }
                  if (dueDate == null) continue;
                  final DateTime dueDateValue = dueDate;
                  final isOverdue = dueDateValue.isBefore(DateTime.now());
                  final daysLeft = !isOverdue ? dueDateValue.difference(DateTime.now()).inDays : 0;
                  // Only show reminders for books due in 3 days or less, or overdue
                  if (!isOverdue && (daysLeft > 3 || daysLeft < 0)) continue;
                  reminderTiles.add(
                    FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection('books')
                          .doc(bookId)
                          .get(),
                      builder: (context, bookSnap) {
                        if (!bookSnap.hasData || !bookSnap.data!.exists) {
                          return const SizedBox.shrink();
                        }
                        final book = BookModel.fromFirestore(bookSnap.data!, null);
                        String statusMsg;
                        Color statusColor;
                        Color tagColor;
                        String tagLabel = '';
                        // Tag color logic
                        switch (book.tag.toLowerCase()) {
                          case 'red':
                            tagColor = AppColors.error;
                            tagLabel = 'Overdue';
                            break;
                          case 'yellow':
                            tagColor = AppColors.warning;
                            tagLabel = 'Due Soon';
                            break;
                          default:
                            tagColor = AppColors.success;
                            tagLabel = 'On Time';
                        }
                        final isOverdue = dueDateValue.isBefore(DateTime.now());
                        final daysLeft = !isOverdue ? dueDateValue.difference(DateTime.now()).inDays : 0;
                        if (isOverdue) {
                          final overdueDays = DateTime.now().difference(dueDateValue).inDays;
                          statusMsg = 'Overdue by \\${overdueDays} day\\${overdueDays == 1 ? '' : 's'}';
                          statusColor = AppColors.error;
                        } else if (daysLeft == 0) {
                          statusMsg = 'Due today';
                          statusColor = AppColors.warning;
                        } else if (daysLeft == 1) {
                          statusMsg = 'Due in 1 day';
                          statusColor = AppColors.warning;
                        } else {
                          statusMsg = 'Due in \\${daysLeft} days';
                          statusColor = AppColors.warning;
                        }
                        // Fine calculation (example: 10 per day)
                        double fine = 0;
                        if (isOverdue) {
                          final overdueDays = DateTime.now().difference(dueDateValue).inDays;
                          fine = overdueDays * 10.0; // Adjust per your policy
                        }
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                          child: ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookDetailScreen(bookId: book.id),
                                ),
                              );
                            },
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            leading: book.coverUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      book.coverUrl!,
                                      width: 44,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Icon(Icons.book, color: AppColors.primary, size: 32),
                                    ),
                                  )
                                : Icon(Icons.book, color: AppColors.primary, size: 32),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    book.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Chip(
                                  label: Text(tagLabel, style: const TextStyle(color: Colors.white)),
                                  backgroundColor: tagColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('By \\${book.author}'),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      isOverdue ? Icons.warning : Icons.event,
                                      size: 16,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      statusMsg,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (isOverdue) ...[
                                      const SizedBox(width: 12),
                                      Icon(Icons.attach_money, color: AppColors.error, size: 16),
                                      Text(
                                        'Fine: \\${fine.toStringAsFixed(2)}',
                                        style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
                          ),
                        );
                      },
                    ),
                  );
                }
                if (reminderTiles.isEmpty) {
                  return const Center(child: Text('No reminders for overdue or soon due books.'));
                }
                return ListView(
                  padding: const EdgeInsets.only(top: 16.0),
                  children: reminderTiles,
                );
              },
            ),
      bottomNavigationBar: StudentNavBar(currentIndex: 0, context: context),
    );
  }
} 