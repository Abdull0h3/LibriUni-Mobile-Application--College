import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Required for Timestamp
import 'package:intl/intl.dart'; // For date formatting

import '/constants/app_colors.dart';
import '/models/news_item_model.dart'; // Use the new model
import '/services/news_service.dart';   // Use the new service
import '/routes/app_router.dart';       // For navigation

class NewsAndEventsScreen extends StatefulWidget {
  const NewsAndEventsScreen({super.key});

  @override
  State<NewsAndEventsScreen> createState() => _NewsAndEventsScreenState();
}

class _NewsAndEventsScreenState extends State<NewsAndEventsScreen> {
  final NewsService _newsService = NewsService();
  String _sortBy = 'Posted Date'; // Default sort
  bool _sortDescending = true; // Default: newest first for dates, high first for priority

  // This list will hold the data from the stream and be sorted
  List<NewsItemModel> _displayedItems = [];

  String _formatTimestampForDisplay(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    // More concise date format for list items
    return DateFormat('MMM dd, yyyy').format(timestamp.toDate());
  }

  void _applySort(List<NewsItemModel> items) {
    items.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'Priority':
          // NewsPriority enum order is high, medium, low (0, 1, 2)
          comparison = a.priority.index.compareTo(b.priority.index);
          return _sortDescending ? comparison : -comparison; // Ascending for priority (High first)
        case 'Event Date':
          if (a.eventDate == null && b.eventDate == null) comparison = 0;
          else if (a.eventDate == null) comparison = 1; // Nulls last
          else if (b.eventDate == null) comparison = -1; // Nulls last
          else comparison = a.eventDate!.compareTo(b.eventDate!);
          return _sortDescending ? -comparison : comparison; // Descending for date (Newest first)
        case 'Title':
          comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          return _sortDescending ? -comparison : comparison; // Standard A-Z or Z-A
        case 'Posted Date':
        default: // Default to Posted Date
          comparison = a.postedDate.compareTo(b.postedDate);
          return _sortDescending ? -comparison : comparison; // Descending for date (Newest first)
      }
    });
    // No need to call setState here if StreamBuilder handles rebuilds,
    // but if sorting is done outside StreamBuilder's build, then setState is needed.
    // For this setup, StreamBuilder rebuilds, and we sort the fresh list.
    //TODO: DELETE THIS LATER
  }

  Map<String, dynamic> _getItemAppearance(NewsItemModel item) {
    switch (item.type) {
      case NewsItemType.alert:
        return {'color': Colors.red.shade600, 'icon': Icons.warning_amber_rounded};
      case NewsItemType.information:
        return {'color': Colors.orange.shade600, 'icon': Icons.info_outline};
      case NewsItemType.maintenance:
        return {'color': Colors.blue.shade600, 'icon': Icons.build_circle_outlined};
      default: // Should not happen if model parsing is correct
        return {'color': AppColors.textColorDark, 'icon': Icons.help_outline};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News & Events'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textColorLight,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sort by:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textColorDark)),
                DropdownButton<String>(
                  value: _sortBy,
                  icon: Icon(
                    _sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
                    color: AppColors.primaryColor,
                  ),
                  elevation: 16,
                  style: const TextStyle(color: AppColors.primaryColor, fontSize: 16),
                  underline: Container(
                    height: 2,
                    color: AppColors.secondaryColor,
                  ),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        if (_sortBy == newValue) {
                          _sortDescending = !_sortDescending; // Toggle direction
                        } else {
                          _sortBy = newValue;
                          // Default sort directions for new selections
                          if (_sortBy == 'Priority') {
                            _sortDescending = false; // High (0) to Low (2)
                          } else {
                            _sortDescending = true; // Newest/Largest first for dates/titles(Z-A)
                          }
                        }
                        // The StreamBuilder will refetch or we re-sort the current list.
                        // For simplicity, we let StreamBuilder provide the base list, then sort.
                      });
                    }
                  },
                  items: <String>['Posted Date', 'Priority', 'Event Date', 'Title']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<NewsItemModel>>(
              stream: _newsService.getNewsItemsStream(), // Service fetches data
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No news or events at the moment.'));
                }

                _displayedItems = List.from(snapshot.data!); // Take a mutable copy
                _applySort(_displayedItems); // Apply current sort criteria

                return ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: _displayedItems.length,
                  itemBuilder: (context, index) {
                    final item = _displayedItems[index];
                    final appearance = _getItemAppearance(item);
                    final Color itemColor = appearance['color'];
                    final IconData itemIcon = appearance['icon'];

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: itemColor, width: 1.8)
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        title: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textColorDark),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.miniNote != null && item.miniNote!.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                item.miniNote!,
                                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textColorDark.withOpacity(0.7)),
                              ),
                            ],
                            const SizedBox(height: 5),
                            Text(
                              item.description,
                              style: TextStyle(fontSize: 14.5, color: AppColors.textColorDark.withOpacity(0.85)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (item.eventDate != null)
                                  Text(
                                    'Event: ${_formatTimestampForDisplay(item.eventDate)}',
                                    style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: AppColors.secondaryColor),
                                  ),
                                Text(
                                  'Posted: ${_formatTimestampForDisplay(item.postedDate)}',
                                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Icon(
                            itemIcon,
                            color: itemColor,
                            size: 30,
                        ),
                        onTap: () {
                           Navigator.pushNamed(
                             context,
                             AppRoutes.newsItemDetail,
                             arguments: item,
                           );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}