import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room.dart';
import '../models/room_booking.dart';

class RoomBookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'room_bookings';

  // Get bookings for a specific user
  Future<List<RoomBooking>> getUserBookings(String userId) async {
    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collection(_collection)
              .where('userId', isEqualTo: userId)
              .orderBy('startTime', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => RoomBooking.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user bookings: ${e.toString()}');
    }
  }

  // Get all bookings (for staff/admin)
  Future<List<RoomBooking>> getAllBookings({String? status}) async {
    try {
      Query query = _firestore.collection(_collection);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final QuerySnapshot snapshot =
          await query.orderBy('startTime', descending: true).get();

      return snapshot.docs
          .map((doc) => RoomBooking.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch all bookings: ${e.toString()}');
    }
  }

  // Book a room
  Future<bool> bookRoom(
    Room room,
    DateTime startTime,
    DateTime endTime,
    String purpose,
    String userId,
    String userName,
  ) async {
    try {
      // Check if room is available
      final bool isAvailable = await checkRoomAvailability(
        room.id,
        startTime,
        endTime,
      );

      if (!isAvailable) {
        return false;
      }

      // Create booking
      final booking = RoomBooking(
        id: '',
        userId: userId,
        roomId: room.id,
        roomName: room.name,
        roomCapacity: room.capacity,
        startTime: startTime,
        endTime: endTime,
        purpose: purpose,
      );

      await _firestore.collection(_collection).add(booking.toFirestore());

      return true;
    } catch (e) {
      throw Exception('Failed to book room: ${e.toString()}');
    }
  }

  // Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    try {
      await _firestore.collection(_collection).doc(bookingId).update({
        'isCancelled': true,
      });

      return true;
    } catch (e) {
      throw Exception('Failed to cancel booking: ${e.toString()}');
    }
  }

  // Check room availability
  Future<bool> checkRoomAvailability(
    String roomId,
    DateTime startTime,
    DateTime endTime,
  ) async {
    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collection(_collection)
              .where('roomId', isEqualTo: roomId)
              .where('isCancelled', isEqualTo: false)
              .get();

      final bookings =
          snapshot.docs.map((doc) => RoomBooking.fromFirestore(doc)).toList();

      // Check for time conflicts
      for (final booking in bookings) {
        if (booking.startTime.isBefore(endTime) &&
            booking.endTime.isAfter(startTime)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      throw Exception('Failed to check room availability: ${e.toString()}');
    }
  }
}
