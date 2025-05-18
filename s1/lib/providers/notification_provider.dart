import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'notifications';

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch notifications for a specific user
  Future<void> fetchNotifications(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final QuerySnapshot snapshot =
          await _firestore
              .collection(_collection)
              .where('userId', isEqualTo: userId)
              .orderBy('date', descending: true)
              .get();

      _notifications =
          snapshot.docs
              .map((doc) => AppNotification.fromFirestore(doc))
              .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Add a new notification
  Future<bool> addNotification(AppNotification notification) async {
    try {
      _isLoading = true;
      notifyListeners();

      final DocumentReference docRef = await _firestore
          .collection(_collection)
          .add(notification.toFirestore());

      final newNotification = notification.copyWith(id: docRef.id);
      _notifications.add(newNotification);
      _notifications.sort((a, b) => b.date.compareTo(a.date));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection(_collection).doc(notificationId).update({
        'isRead': true,
      });

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete a notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection(_collection).doc(notificationId).delete();

      _notifications.removeWhere((n) => n.id == notificationId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get unread notifications count
  int getUnreadCount() {
    return _notifications.where((n) => !n.isRead).length;
  }

  // Clear all notifications for a user
  Future<bool> clearAllNotifications(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get all notifications for the user
      final QuerySnapshot snapshot =
          await _firestore
              .collection(_collection)
              .where('userId', isEqualTo: userId)
              .get();

      // Delete each notification
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      _notifications.clear();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
