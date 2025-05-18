import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum representing notification types
enum NotificationType { dueDate, reservation, announcement, system }

/// Extension to convert NotificationType to and from string values
extension NotificationTypeExtension on NotificationType {
  String get name {
    switch (this) {
      case NotificationType.dueDate:
        return 'dueDate';
      case NotificationType.reservation:
        return 'reservation';
      case NotificationType.announcement:
        return 'announcement';
      case NotificationType.system:
        return 'system';
    }
  }

  static NotificationType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'duedate':
      case 'due_date':
      case 'due date':
        return NotificationType.dueDate;
      case 'reservation':
        return NotificationType.reservation;
      case 'announcement':
        return NotificationType.announcement;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.system;
    }
  }
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final NotificationType type;
  final String? userId;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.type,
    this.userId,
    this.isRead = false,
  });

  /// Create a Notification from a Firestore document
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: NotificationTypeExtension.fromString(data['type'] ?? 'system'),
      userId: data['userId'],
      isRead: data['isRead'] ?? false,
    );
  }

  /// Convert Notification to a Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'date': Timestamp.fromDate(date),
      'type': type.name,
      'userId': userId,
      'isRead': isRead,
    };
  }

  /// Create a copy of the notification with updated fields
  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? date,
    NotificationType? type,
    String? userId,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      date: date ?? this.date,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      isRead: isRead ?? this.isRead,
    );
  }

  /// Mark the notification as read
  AppNotification markAsRead() {
    return copyWith(isRead: true);
  }
}
