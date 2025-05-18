import 'package:flutter/foundation.dart';
import '../services/room_booking_service.dart';
import '../models/room.dart';

class RoomBookingProvider with ChangeNotifier {
  final RoomBookingService _roomBookingService = RoomBookingService();

  List<Map<String, dynamic>> _userBookings = [];
  List<Map<String, dynamic>> _allBookings = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Map<String, dynamic>> get userBookings => _userBookings;
  List<Map<String, dynamic>> get allBookings => _allBookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch bookings for the current user
  Future<void> fetchUserBookings() async {
    try {
      _isLoading = true;
      notifyListeners();

      _userBookings = await _roomBookingService.getUserBookings();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Fetch all bookings (for staff/admin)
  Future<void> fetchAllBookings({String? status}) async {
    try {
      _isLoading = true;
      notifyListeners();

      _allBookings = await _roomBookingService.getAllBookings(status: status);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Book a room
  Future<bool> bookRoom(
    Room room,
    DateTime startTime,
    DateTime endTime,
    String purpose,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _roomBookingService.bookRoom(
        room,
        startTime,
        endTime,
        purpose,
      );

      if (result) {
        await fetchUserBookings(); // Refresh the user's bookings
      } else {
        _error =
            'Failed to book room. It might be unavailable for the selected time.';
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Cancel a booking
  Future<bool> cancelBooking(String bookingId, String roomId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _roomBookingService.cancelBooking(bookingId, roomId);

      if (result) {
        // Update the booking status in our lists
        final userIndex = _userBookings.indexWhere(
          (booking) => booking['id'] == bookingId,
        );
        if (userIndex != -1) {
          _userBookings[userIndex]['status'] = 'cancelled';
        }

        final allIndex = _allBookings.indexWhere(
          (booking) => booking['id'] == bookingId,
        );
        if (allIndex != -1) {
          _allBookings[allIndex]['status'] = 'cancelled';
        }
      } else {
        _error = 'Failed to cancel booking.';
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Check room availability
  Future<bool> checkRoomAvailability(
    String roomId,
    DateTime startTime,
    DateTime endTime,
  ) async {
    try {
      return await _roomBookingService.checkRoomAvailability(
        roomId,
        startTime,
        endTime,
      );
    } catch (e) {
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
