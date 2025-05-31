import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/news_service.dart';
import '../../models/news_item_model.dart';
import '../../constants/app_colors.dart';

class ManageNewsScreen extends StatefulWidget {
  const ManageNewsScreen({super.key});

  @override
  State<ManageNewsScreen> createState() => _ManageNewsScreenState();
}

class _ManageNewsScreenState extends State<ManageNewsScreen> {
  final NewsService _newsService = NewsService();

  // Dialog for adding/editing news items
  Future<void> _showNewsItemDialog({NewsItemModel? newsItem}) async {
    final _formKey = GlobalKey<FormState>();
    String _title = newsItem?.title ?? '';
    String _description = newsItem?.description ?? '';
    String? _miniNote = newsItem?.miniNote;
    String _fullDetails = newsItem?.fullDetails ?? '';
    NewsPriority _priority = newsItem?.priority ?? NewsPriority.medium;
    NewsItemType _type = newsItem?.type ?? NewsItemType.information;
    Timestamp? _eventDate = newsItem?.eventDate;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(newsItem == null ? 'Add News Item' : 'Edit News Item'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: _title,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                    onSaved: (value) => _title = value!,
                  ),
                  TextFormField(
                    initialValue: _description,
                    decoration: const InputDecoration(
                      labelText: 'Short Description',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a short description';
                      }
                      return null;
                    },
                    onSaved: (value) => _description = value!,
                  ),
                  TextFormField(
                    initialValue: _miniNote,
                    decoration: const InputDecoration(
                      labelText: 'Mini Note (Optional)',
                    ),
                    onSaved: (value) => _miniNote = value,
                  ),
                  TextFormField(
                    initialValue: _fullDetails,
                    decoration: const InputDecoration(
                      labelText: 'Full Details',
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter full details';
                      }
                      return null;
                    },
                    onSaved: (value) => _fullDetails = value!,
                  ),
                  DropdownButtonFormField<NewsPriority>(
                    value: _priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items:
                        NewsPriority.values.map((priority) {
                          return DropdownMenuItem<NewsPriority>(
                            value: priority,
                            child: Text(
                              priority.toString().split('.').last.toUpperCase(),
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _priority =
                              value; // State update within dialog might need different approach
                        });
                      }
                    },
                    onSaved: (value) => _priority = value!,
                  ),
                  DropdownButtonFormField<NewsItemType>(
                    value: _type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items:
                        NewsItemType.values.map((type) {
                          return DropdownMenuItem<NewsItemType>(
                            value: type,
                            child: Text(
                              type.toString().split('.').last.toUpperCase(),
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _type = value; // State update within dialog
                        });
                      }
                    },
                    onSaved: (value) => _type = value!,
                  ),
                  // Add date picker for eventDate if needed
                  TextButton(
                    onPressed: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: _eventDate?.toDate() ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(Duration(days: 365)),
                        lastDate: DateTime.now().add(Duration(days: 365 * 5)),
                      );
                      if (selectedDate != null) {
                        setState(() {
                          _eventDate = Timestamp.fromDate(
                            selectedDate,
                          ); // State update within dialog
                        });
                      }
                    },
                    child: Text(
                      _eventDate == null
                          ? 'Select Event Date (Optional)'
                          : 'Event Date: ${_eventDate!.toDate()}',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  final newNewsItem = NewsItemModel(
                    id:
                        newsItem?.id ??
                        '', // Use existing ID for edit, empty for new
                    title: _title,
                    description: _description,
                    miniNote: _miniNote,
                    fullDetails: _fullDetails,
                    priority: _priority,
                    type: _type,
                    eventDate: _eventDate,
                    postedDate:
                        newsItem?.postedDate ??
                        Timestamp.now(), // Keep original posted date for edit
                  );

                  if (newsItem == null) {
                    await _newsService.addNewsItem(newNewsItem);
                  } else {
                    await _newsService.updateNewsItem(newNewsItem);
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(newsItem == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(String newsItemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete News Item'),
          content: const Text(
            'Are you sure you want to delete this news item?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _newsService.deleteNewsItem(newsItemId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage News'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textColorLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add News Item',
            onPressed: () => _showNewsItemDialog(),
          ),
        ],
      ),
      body: StreamBuilder<List<NewsItemModel>>(
        stream: _newsService.getNewsItemsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final newsItems = snapshot.data!;

          if (newsItems.isEmpty) {
            return const Center(child: Text('No news items found.'));
          }

          return ListView.builder(
            itemCount: newsItems.length,
            itemBuilder: (context, index) {
              final newsItem = newsItems[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.secondaryColor.withOpacity(0.2),
                    child: Icon(
                      _newsService.getTypeIcon(
                        newsItem.type,
                      ), // Assuming NewsService has this helper
                      color: _newsService.getTypeColor(
                        newsItem.type,
                      ), // Assuming NewsService has this helper
                    ),
                  ),
                  title: Text(newsItem.title),
                  subtitle: Text(
                    newsItem.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        tooltip: 'Edit',
                        onPressed:
                            () => _showNewsItemDialog(newsItem: newsItem),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          size: 20,
                          color: Colors.red[700],
                        ),
                        tooltip: 'Delete',
                        onPressed: () => _confirmDelete(newsItem.id),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Optional: Navigate to news detail screen for admin view if needed
                    // context.push('/admin/news/${newsItem.id}', extra: newsItem);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
