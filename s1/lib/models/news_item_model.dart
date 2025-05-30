import 'package:cloud_firestore/cloud_firestore.dart';

enum NewsPriority { high, medium, low }

enum NewsItemType { alert, information, maintenance }

class NewsItemModel {
  final String id;
  final String title;
  final String description; // Main content for the list view
  final String? miniNote; // Optional small note under title
  final String fullDetails; // For the detail screen
  final NewsPriority priority;
  final NewsItemType type;
  final Timestamp? eventDate; // Optional date for events
  final Timestamp postedDate; // When the news item was published

  NewsItemModel({
    required this.id,
    required this.title,
    required this.description,
    this.miniNote,
    required this.fullDetails,
    required this.priority,
    required this.type,
    this.eventDate,
    required this.postedDate,
  });

  factory NewsItemModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError(
        'Missing data for NewsItemModel from snapshot ${snapshot.id}',
      );
    }

    return NewsItemModel(
      id: snapshot.id,
      title: data['title'] ?? 'No Title',
      description: data['description'] ?? 'No Description',
      miniNote: data['miniNote'] as String?,
      fullDetails:
          data['fullDetails'] ?? data['description'] ?? 'No Details Provided',
      priority: _priorityFromString(data['priority'] ?? 'medium'),
      type: _typeFromString(data['type'] ?? 'information'),
      eventDate: data['eventDate'] as Timestamp?,
      postedDate: data['postedDate'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'miniNote': miniNote,
      'fullDetails': fullDetails,
      'priority': priority.toString().split('.').last,
      'type': type.toString().split('.').last,
      'eventDate': eventDate,
      'postedDate': postedDate,
    };
  }

  static NewsPriority _priorityFromString(String priorityStr) {
    return NewsPriority.values.firstWhere(
      (e) =>
          e.toString().split('.').last.toLowerCase() ==
          priorityStr.toLowerCase(),
      orElse: () => NewsPriority.medium,
    );
  }

  static NewsItemType _typeFromString(String typeStr) {
    return NewsItemType.values.firstWhere(
      (e) =>
          e.toString().split('.').last.toLowerCase() == typeStr.toLowerCase(),
      orElse: () => NewsItemType.information,
    );
  }
}
