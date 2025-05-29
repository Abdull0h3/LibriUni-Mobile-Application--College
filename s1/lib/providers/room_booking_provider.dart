import 'package:flutter/foundation.dart';
import '../services/room_booking_service.dart';
import '../models/room.dart';
import '../models/room_booking.dart';

class RoomBookingProvider with ChangeNotifier {
  final RoomBookingService _roomBookingService = RoomBookingService();

  List<RoomBooking> _userBookings = [];
  List<RoomBooking> _allBookings = [];
  bool _isLoading = false;
  String? _error;

  Future<bool> reserveRoom({
    required Room room,
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final date = "${startTime.day}-${startTime.month}-${startTime.year}";

      final success = await _roomBookingService.bookRoom(
        room,
        startTime,
        endTime,
        "General", // Replace with actual purpose if needed
        userId,
        date,
      );

      if (success) {
        await fetchUserBookings(userId); // Update local state
      } else {
        _error =
            'Room is already reserved or user already booked a room for that day.';
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = 'Error reserving room: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  List<RoomBooking> get userBookings => _userBookings;
  List<RoomBooking> get allBookings => _allBookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUserBookings(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _userBookings = await _roomBookingService.getUserBookings(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

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

  Future<bool> bookRoom(
    Room room,
    DateTime startTime,
    DateTime endTime,
    String purpose,
    String userId,
    String userName,
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
        userId,
        userName,
      );

      if (result) {
        await fetchUserBookings(userId); // Refresh the user's bookings
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

  Future<bool> cancelBooking(String bookingId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _roomBookingService.cancelBooking(bookingId);

      if (result) {
        _userBookings =
            _userBookings
                .map(
                  (booking) =>
                      booking.id == bookingId
                          ? booking.copyWith(isCancelled: true)
                          : booking,
                )
                .toList();

        _allBookings =
            _allBookings
                .map(
                  (booking) =>
                      booking.id == bookingId
                          ? booking.copyWith(isCancelled: true)
                          : booking,
                )
                .toList();
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
