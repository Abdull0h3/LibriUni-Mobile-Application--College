import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room.dart';

/// Application theme using the defined color palette
class AppTheme {
  static ThemeData get light => ThemeData(
    primaryColor: AppColors.primary,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      secondary: AppColors.secondary,
      onSecondary: AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.textPrimary,
      background: AppColors.background,
      onBackground: AppColors.textPrimary,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      color: AppColors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    // Added for dark mode support
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textPrimary),
      titleLarge: TextStyle(color: AppColors.textPrimary),
      titleMedium: TextStyle(color: AppColors.textPrimary),
    ),
    iconTheme: const IconThemeData(
      color: AppColors.textPrimary,
    ),
  );

  static ThemeData get dark => ThemeData(
    primaryColor: AppColors.primary,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      secondary: AppColors.secondary,
      onSecondary: AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
      surface: Color(0xFF1E1E1E),
      onSurface: AppColors.white,
      background: Color(0xFF121212),
      onBackground: AppColors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.secondary,
      foregroundColor: AppColors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.lightGray),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.lightGray,
        side: const BorderSide(color: AppColors.lightGray),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    // Added for dark mode support
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.white),
      bodyMedium: TextStyle(color: AppColors.white),
      titleLarge: TextStyle(color: AppColors.white),
      titleMedium: TextStyle(color: AppColors.white),
    ),
    iconTheme: const IconThemeData(
      color: AppColors.white,
    ),
    // Added for dark mode support
    dividerTheme: const DividerThemeData(
      color: Color(0xFF333333),
    ),
    // Added for dark mode support
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: AppColors.secondary,
      unselectedItemColor: AppColors.lightGray,
    ),
  );
}

class RoomBookingProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Room> availableRooms = [];
  bool isLoading = false;
  String? error;

  // Fetch available rooms for a given date and time slot
  Future<void> fetchAvailableRooms(
    DateTime date,
    DateTime startTime,
    DateTime endTime,
  ) async {
    isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch all rooms
      final roomsSnapshot = await _firestore.collection('rooms').get();
      final allRooms =
          roomsSnapshot.docs.map((doc) => Room.fromFirestore(doc)).toList();

      // 2. Fetch all reservations for the date
      final reservationsSnapshot =
          await _firestore
              .collection('reservations')
              .where(
                'date',
                isEqualTo: '${date.day}-${date.month}-${date.year}',
              )
              .get();

      // 3. Filter out rooms that are reserved for the selected slot
      final reservedRoomIds = <String>{};
      for (var doc in reservationsSnapshot.docs) {
        final data = doc.data();
        final reservedStart = (data['startTime'] as Timestamp).toDate();
        final reservedEnd = (data['endTime'] as Timestamp).toDate();
        // Check for time overlap
        if (startTime.isBefore(reservedEnd) && endTime.isAfter(reservedStart)) {
          reservedRoomIds.add(data['roomID']);
        }
      }

      availableRooms =
          allRooms
              .where((room) => !reservedRoomIds.contains(room.id!))
              .toList();
      error = null;
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  // Reserve a room
  Future<bool> reserveRoom({
    required String roomId,
    required String userId,
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      await _firestore.collection('reservations').add({
        'roomID': roomId,
        'reservedBy': userId,
        'date': '${date.day}-${date.month}-${date.year}',
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'status': 'Confirmed',
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
