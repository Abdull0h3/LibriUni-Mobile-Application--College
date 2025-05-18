import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/room.dart';

class RoomBookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final String _collection = 'roomBookings';

  // Book a room
  Future<bool> bookRoom(
    Room room,
    DateTime startTime,
    DateTime endTime,
    String purpose,
  ) async {
    try {
      if (room.status != RoomStatus.available) {
        return false; // Room is not available
      }

      final user = _auth.currentUser;
      if (user == null) {
        return false; // User not logged in
      }

      // Check for existing bookings in the time slot
      final QuerySnapshot existingBookings =
          await _firestore
              .collection(_collection)
              .where('roomId', isEqualTo: room.id)
              .where('startTime', isLessThan: Timestamp.fromDate(endTime))
              .where('endTime', isGreaterThan: Timestamp.fromDate(startTime))
              .get();

      if (existingBookings.docs.isNotEmpty) {
        return false; // Room is already booked during this time
      }

      // Create a booking record
      final bookingData = {
        'userId': user.uid,
        'userName': user.displayName ?? 'Unknown User',
        'userEmail': user.email ?? 'No Email',
        'roomId': room.id,
        'roomName': room.name,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'purpose': purpose,
        'bookingDate': Timestamp.now(),
        'status': 'confirmed', // could be 'confirmed', 'cancelled', 'completed'
      };

      // Add booking record
      await _firestore.collection(_collection).add(bookingData);

      // Update room status to occupied
      await _firestore.collection('rooms').doc(room.id).update({
        'status': RoomStatus.occupied.name,
        'reservedBy': user.uid,
        'reservationStart': Timestamp.fromDate(startTime),
        'reservationEnd': Timestamp.fromDate(endTime),
      });

      return true;
    } catch (e) {
      print('Error booking room: $e');
      return false;
    }
  }

  // Cancel a room booking
  Future<bool> cancelBooking(String bookingId, String roomId) async {
    try {
      // Update booking status
      await _firestore.collection(_collection).doc(bookingId).update({
        'status': 'cancelled',
      });

      // Update room status back to available
      await _firestore.collection('rooms').doc(roomId).update({
        'status': RoomStatus.available.name,
        'reservedBy': null,
        'reservationStart': null,
        'reservationEnd': null,
      });

      return true;
    } catch (e) {
      print('Error cancelling booking: $e');
      return false;
    }
  }

  // Get all bookings for the current user
  Future<List<Map<String, dynamic>>> getUserBookings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      final QuerySnapshot snapshot =
          await _firestore
              .collection(_collection)
              .where('userId', isEqualTo: user.uid)
              .orderBy('startTime', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'roomId': data['roomId'],
          'roomName': data['roomName'],
          'startTime': (data['startTime'] as Timestamp).toDate(),
          'endTime': (data['endTime'] as Timestamp).toDate(),
          'purpose': data['purpose'],
          'status': data['status'],
        };
      }).toList();
    } catch (e) {
      print('Error getting user bookings: $e');
      return [];
    }
  }

  // Get all bookings (for staff/admin)
  Future<List<Map<String, dynamic>>> getAllBookings({String? status}) async {
    try {
      Query query = _firestore.collection(_collection);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final QuerySnapshot snapshot = await query.orderBy('startTime').get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'userId': data['userId'],
          'userName': data['userName'],
          'userEmail': data['userEmail'],
          'roomId': data['roomId'],
          'roomName': data['roomName'],
          'startTime': (data['startTime'] as Timestamp).toDate(),
          'endTime': (data['endTime'] as Timestamp).toDate(),
          'purpose': data['purpose'],
          'status': data['status'],
          'bookingDate': (data['bookingDate'] as Timestamp).toDate(),
        };
      }).toList();
    } catch (e) {
      print('Error getting all bookings: $e');
      return [];
    }
  }

  // Check if a room is available during a specific time slot
  Future<bool> checkRoomAvailability(
    String roomId,
    DateTime startTime,
    DateTime endTime,
  ) async {
    try {
      // Check room status
      final DocumentSnapshot roomDoc =
          await _firestore.collection('rooms').doc(roomId).get();

      if (!roomDoc.exists) {
        return false; // Room doesn't exist
      }

      final data = roomDoc.data() as Map<String, dynamic>;
      final status = RoomStatusExtension.fromString(
        data['status'] ?? 'available',
      );

      if (status != RoomStatus.available) {
        return false; // Room is not available (maintenance or other reason)
      }

      // Check for existing bookings in the time slot
      final QuerySnapshot existingBookings =
          await _firestore
              .collection(_collection)
              .where('roomId', isEqualTo: roomId)
              .where('status', isEqualTo: 'confirmed')
              .where('startTime', isLessThan: Timestamp.fromDate(endTime))
              .where('endTime', isGreaterThan: Timestamp.fromDate(startTime))
              .get();

      return existingBookings.docs.isEmpty; // Available if no bookings found
    } catch (e) {
      print('Error checking room availability: $e');
      return false;
    }
  }
}
