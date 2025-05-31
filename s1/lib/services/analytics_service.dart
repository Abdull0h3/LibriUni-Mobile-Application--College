import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get borrowing trends by time period
  Future<Map<String, List<int>>> getBorrowingTrends() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('borrows').get();
      final List<DocumentSnapshot> docs = snapshot.docs;

      // Calculate date ranges
      final DateTime now = DateTime.now();
      final DateTime todayStart = DateTime(now.year, now.month, now.day);
      final DateTime weekStart = todayStart.subtract(
        Duration(days: todayStart.weekday - 1),
      );
      final DateTime monthStart = DateTime(now.year, now.month, 1);

      // Initialize result maps
      final Map<String, List<int>> result = {
        'Today': List.filled(7, 0),
        'This Week': List.filled(7, 0),
        'This Month': List.filled(7, 0),
        'All Time': List.filled(7, 0),
      };

      // Process each borrow document
      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        final DateTime borrowDate = (data['borrowDate'] as Timestamp).toDate();

        // Determine day index for each time period
        final int todayIndex = _getDayIndex(borrowDate, todayStart, 'day');
        final int weekIndex = _getDayIndex(borrowDate, weekStart, 'week');
        final int monthIndex = _getDayIndex(borrowDate, monthStart, 'month');
        final int allTimeIndex = borrowDate.weekday - 1;

        // Update counts
        if (todayIndex >= 0 && todayIndex < 7) {
          result['Today']![todayIndex]++;
        }
        if (weekIndex >= 0 && weekIndex < 7) {
          result['This Week']![weekIndex]++;
        }
        if (monthIndex >= 0 && monthIndex < 7) {
          result['This Month']![monthIndex]++;
        }
        result['All Time']![allTimeIndex]++;
      }

      return result;
    } catch (e) {
      print('Error fetching borrowing trends: $e');
      return {
        'Today': [0, 0, 0, 0, 0, 0, 0],
        'This Week': [0, 0, 0, 0, 0, 0, 0],
        'This Month': [0, 0, 0, 0, 0, 0, 0],
        'All Time': [0, 0, 0, 0, 0, 0, 0],
      };
    }
  }

  // Get popular categories by time period
  Future<Map<String, Map<String, int>>> getPopularCategories() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('borrows').get();
      final List<DocumentSnapshot> docs = snapshot.docs;

      // Calculate date ranges
      final DateTime now = DateTime.now();
      final DateTime todayStart = DateTime(now.year, now.month, now.day);
      final DateTime weekStart = todayStart.subtract(
        Duration(days: todayStart.weekday - 1),
      );
      final DateTime monthStart = DateTime(now.year, now.month, 1);

      // Initialize result maps
      final Map<String, Map<String, int>> result = {
        'Today': {},
        'This Week': {},
        'This Month': {},
        'All Time': {},
      };

      // Process each borrow document
      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        final DateTime borrowDate = (data['borrowDate'] as Timestamp).toDate();
        final String category = data['bookCategory'] ?? 'Uncategorized';

        // Update for all time
        result['All Time']![category] =
            (result['All Time']![category] ?? 0) + 1;

        // Update for this month
        if (borrowDate.isAfter(monthStart)) {
          result['This Month']![category] =
              (result['This Month']![category] ?? 0) + 1;
        }

        // Update for this week
        if (borrowDate.isAfter(weekStart)) {
          result['This Week']![category] =
              (result['This Week']![category] ?? 0) + 1;
        }

        // Update for today
        if (borrowDate.isAfter(todayStart)) {
          result['Today']![category] = (result['Today']![category] ?? 0) + 1;
        }
      }

      return result;
    } catch (e) {
      print('Error fetching popular categories: $e');
      return {
        'Today': {
          'Fiction': 0,
          'Non-Fiction': 0,
          'Science': 0,
          'Engineering': 0,
          'Arts': 0,
          'History': 0,
        },
        'This Week': {
          'Fiction': 0,
          'Non-Fiction': 0,
          'Science': 0,
          'Engineering': 0,
          'Arts': 0,
          'History': 0,
        },
        'This Month': {
          'Fiction': 0,
          'Non-Fiction': 0,
          'Science': 0,
          'Engineering': 0,
          'Arts': 0,
          'History': 0,
        },
        'All Time': {
          'Fiction': 0,
          'Non-Fiction': 0,
          'Science': 0,
          'Engineering': 0,
          'Arts': 0,
          'History': 0,
        },
      };
    }
  }

  // Get room usage by time period
  Future<Map<String, Map<String, int>>> getRoomUsage() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('roomBookings').get();
      final List<DocumentSnapshot> docs = snapshot.docs;

      // Calculate date ranges
      final DateTime now = DateTime.now();
      final DateTime todayStart = DateTime(now.year, now.month, now.day);
      final DateTime weekStart = todayStart.subtract(
        Duration(days: todayStart.weekday - 1),
      );
      final DateTime monthStart = DateTime(now.year, now.month, 1);

      // Initialize result maps with days of the week
      final Map<String, Map<String, int>> result = {
        'Today': {'Today': 0},
        'This Week': {
          'Monday': 0,
          'Tuesday': 0,
          'Wednesday': 0,
          'Thursday': 0,
          'Friday': 0,
          'Saturday': 0,
          'Sunday': 0,
        },
        'This Month': {'Week 1': 0, 'Week 2': 0, 'Week 3': 0, 'Week 4': 0},
        'All Time': {
          'Monday': 0,
          'Tuesday': 0,
          'Wednesday': 0,
          'Thursday': 0,
          'Friday': 0,
          'Saturday': 0,
          'Sunday': 0,
        },
      };

      // Process each room booking document
      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        final DateTime bookingDate = (data['startTime'] as Timestamp).toDate();

        // Update for all time
        final String dayOfWeek = _getDayName(bookingDate.weekday);
        result['All Time']![dayOfWeek] =
            (result['All Time']![dayOfWeek] ?? 0) + 1;

        // Update for this month
        if (bookingDate.isAfter(monthStart)) {
          final int weekOfMonth = (bookingDate.day - 1) ~/ 7;
          final String weekKey = 'Week ${weekOfMonth + 1}';
          if (result['This Month']!.containsKey(weekKey)) {
            result['This Month']![weekKey] =
                (result['This Month']![weekKey] ?? 0) + 1;
          }
        }

        // Update for this week
        if (bookingDate.isAfter(weekStart)) {
          final String dayName = _getDayName(bookingDate.weekday);
          result['This Week']![dayName] =
              (result['This Week']![dayName] ?? 0) + 1;
        }

        // Update for today
        if (bookingDate.isAfter(todayStart)) {
          result['Today']!['Today'] = (result['Today']!['Today'] ?? 0) + 1;
        }
      }

      return result;
    } catch (e) {
      print('Error fetching room usage: $e');
      return {
        'Today': {'Today': 0},
        'This Week': {
          'Monday': 0,
          'Tuesday': 0,
          'Wednesday': 0,
          'Thursday': 0,
          'Friday': 0,
          'Saturday': 0,
          'Sunday': 0,
        },
        'This Month': {'Week 1': 0, 'Week 2': 0, 'Week 3': 0, 'Week 4': 0},
        'All Time': {
          'Monday': 0,
          'Tuesday': 0,
          'Wednesday': 0,
          'Thursday': 0,
          'Friday': 0,
          'Saturday': 0,
          'Sunday': 0,
        },
      };
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  // Helper method to get day index for various time periods
  int _getDayIndex(DateTime date, DateTime startDate, String period) {
    if (period == 'day') {
      // For today, return 0 if it's the same day
      return date.day == startDate.day &&
              date.month == startDate.month &&
              date.year == startDate.year
          ? 0
          : -1;
    } else if (period == 'week') {
      // For week, calculate days since week start
      final difference = date.difference(startDate).inDays;
      return difference >= 0 && difference < 7 ? difference : -1;
    } else if (period == 'month') {
      // For month, group into weeks
      final weekOfMonth = (date.day - 1) ~/ 7;
      return date.month == startDate.month && date.year == startDate.year
          ? (weekOfMonth < 7 ? weekOfMonth : 6)
          : -1;
    }
    return -1;
  }

  // Get general statistics
  Future<Map<String, dynamic>> getGeneralStatistics() async {
    try {
      // Get total books
      final QuerySnapshot booksSnapshot =
          await _firestore.collection('books').get();
      final int totalBooks = booksSnapshot.size;

      // Get available books
      final QuerySnapshot availableBooksSnapshot =
          await _firestore
              .collection('books')
              .where('isAvailable', isEqualTo: true)
              .get();
      final int availableBooks = availableBooksSnapshot.size;

      // Get total users
      final QuerySnapshot usersSnapshot =
          await _firestore.collection('users').get();
      final int totalUsers = usersSnapshot.size;

      // Count by role
      int studentCount = 0;
      int staffCount = 0;
      int adminCount = 0;

      for (var doc in usersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String role = data['role'] ?? 'student';

        if (role == 'student')
          studentCount++;
        else if (role == 'staff')
          staffCount++;
        else if (role == 'admin')
          adminCount++;
      }

      // Get active borrows
      final QuerySnapshot activeBorrowsSnapshot =
          await _firestore
              .collection('borrows')
              .where('isReturned', isEqualTo: false)
              .get();
      final int activeBorrows = activeBorrowsSnapshot.size;

      return {
        'totalBooks': totalBooks,
        'availableBooks': availableBooks,
        'borrowedBooks': totalBooks - availableBooks,
        'totalUsers': totalUsers,
        'studentCount': studentCount,
        'staffCount': staffCount,
        'adminCount': adminCount,
        'activeBorrows': activeBorrows,
      };
    } catch (e) {
      print('Error fetching general statistics: $e');
      return {
        'totalBooks': 0,
        'availableBooks': 0,
        'borrowedBooks': 0,
        'totalUsers': 0,
        'studentCount': 0,
        'staffCount': 0,
        'adminCount': 0,
        'activeBorrows': 0,
      };
    }
  }

  // Get total reserved slots
  Future<int> getReservedSlotsCount() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collectionGroup(
                'slots',
              ) // Use collectionGroup to query nested slots
              .where('isReserved', isEqualTo: true)
              .get();
      return snapshot.size;
    } catch (e) {
      print('Error fetching reserved slots count: $e');
      return 0;
    }
  }

  // Get fines statistics (paid and unpaid)
  Future<Map<String, dynamic>> getFinesStats({
    String timePeriod = 'All Time',
  }) async {
    try {
      DateTime now = DateTime.now();
      DateTime startDate;

      switch (timePeriod) {
        case 'Today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'This Week':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          break;
        case 'This Month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'All Time':
        default:
          startDate = DateTime.fromMillisecondsSinceEpoch(0); // Start of epoch
          break;
      }

      Query query = _firestore.collection('fines');

      if (timePeriod != 'All Time') {
        // Assuming 'createdDate' or 'paidDate' exists and is a Timestamp
        // You might need to adjust the field name based on your Firestore structure
        query = query.where('paidDate', isGreaterThanOrEqualTo: startDate);
      }

      final QuerySnapshot snapshot = await query.get();

      int paidCount = 0;
      int unpaidCount = 0;
      double paidAmount = 0.0;
      double unpaidAmount = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String status = data['status'] ?? 'Unpaid';
        final double fineAmount =
            (data['fineAmount'] as num?)?.toDouble() ?? 0.0;

        if (status == 'Paid') {
          paidCount++;
          paidAmount += fineAmount;
        } else {
          unpaidCount++;
          unpaidAmount += fineAmount;
        }
      }

      return {
        'paid': paidCount,
        'unpaid': unpaidCount,
        'paidAmount': paidAmount,
        'unpaidAmount': unpaidAmount,
      };
    } catch (e) {
      print('Error fetching fines stats: $e');
      return {'paid': 0, 'unpaid': 0, 'paidAmount': 0.0, 'unpaidAmount': 0.0};
    }
  }
}
