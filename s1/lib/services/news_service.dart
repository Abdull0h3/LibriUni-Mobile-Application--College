import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_item_model.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class NewsService {
  final CollectionReference<NewsItemModel> _newsCollection = FirebaseFirestore
      .instance
      .collection('news_items')
      .withConverter<NewsItemModel>(
        fromFirestore: (snapshots, _) => NewsItemModel.fromFirestore(snapshots),
        toFirestore: (newsItem, _) => newsItem.toFirestore(),
      );

  Stream<List<NewsItemModel>> getNewsItemsStream() {
    // Default sort by postedDate, newest first.
    // You can extend this to accept sort parameters.
    return _newsCollection
        .orderBy('postedDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }

  // Example: Add a news item (you might need this for an admin panel)
  Future<DocumentReference<NewsItemModel>> addNewsItem(NewsItemModel newsItem) {
    // Firestore automatically generates a unique ID when you use .add()
    return _newsCollection.add(newsItem);
  }

  // Update an existing news item
  Future<void> updateNewsItem(NewsItemModel newsItem) {
    if (newsItem.id.isEmpty) {
      throw ArgumentError('News item ID cannot be empty for updating');
    }
    return _newsCollection
        .doc(newsItem.id)
        .set(newsItem, SetOptions(merge: true));
  }

  // Delete a news item
  Future<void> deleteNewsItem(String newsItemId) {
    if (newsItemId.isEmpty) {
      throw ArgumentError('News item ID cannot be empty for deleting');
    }
    return _newsCollection.doc(newsItemId).delete();
  }

  // Helper to get color based on news type
  Color getTypeColor(NewsItemType type) {
    switch (type) {
      case NewsItemType.alert:
        return Colors.red.shade700;
      case NewsItemType.information:
        return Colors.orange.shade700;
      case NewsItemType.maintenance:
        return Colors.blue.shade700;
      default:
        return AppColors
            .textColorDark; // Assuming AppColors is accessible or imported
    }
  }

  // Helper to get icon based on news type
  IconData getTypeIcon(NewsItemType type) {
    switch (type) {
      case NewsItemType.alert:
        return Icons.warning_amber_rounded;
      case NewsItemType.information:
        return Icons.info_outline;
      case NewsItemType.maintenance:
        return Icons.build_circle_outlined;
      default:
        return Icons.help_outline;
    }
  }
}
