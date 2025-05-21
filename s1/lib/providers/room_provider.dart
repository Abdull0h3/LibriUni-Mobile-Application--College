import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room.dart';

class RoomProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'rooms';

  List<Room> _rooms = [];
  List<Room> _filteredRooms = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _statusFilter = '';

  // Getters
  List<Room> get rooms => _rooms;
  List<Room> get filteredRooms => _filteredRooms;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;

  // Fetch all rooms
  Future<void> fetchRooms() async {
    try {
      _isLoading = true;
      notifyListeners();

      final QuerySnapshot snapshot =
          await _firestore.collection(_collection).get();
      _rooms = snapshot.docs.map((doc) => Room.fromFirestore(doc)).toList();
      _applyFilters();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Search rooms by name
  void searchRooms(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Filter rooms by status
  void filterByStatus(String status) {
    _statusFilter = status;
    _applyFilters();
    notifyListeners();
  }

  // Add a new room
  Future<bool> addRoom(Room room) async {
    try {
      _isLoading = true;
      notifyListeners();

      final DocumentReference docRef = await _firestore
          .collection(_collection)
          .add(room.toFirestore());

      final newRoom = room.copyWith(id: docRef.id);
      _rooms.add(newRoom);
      _applyFilters();

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

  // Update a room
  Future<bool> updateRoom(Room room) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore
          .collection(_collection)
          .doc(room.id)
          .update(room.toFirestore());

      final index = _rooms.indexWhere((r) => r.id == room.id);
      if (index != -1) {
        _rooms[index] = room;
        _applyFilters();
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

  // Delete a room
  Future<bool> deleteRoom(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection(_collection).doc(id).delete();

      _rooms.removeWhere((room) => room.id == id);
      _applyFilters();

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

  // Reserve a room
  Future<bool> reserveRoom(
    String roomId,
    String userId,
    DateTime startTime,
    DateTime endTime,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if the room is available
      final roomDoc =
          await _firestore.collection(_collection).doc(roomId).get();
      final room = Room.fromFirestore(roomDoc);

      if (room.isReserved) {
        _error = 'Room is already reserved';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Update room reservation status
      final updatedRoom = room.copyWith(
        status: RoomStatus.occupied,
        reservedBy: userId,
        reservationStart: startTime,
        reservationEnd: endTime,
      );

      await _firestore
          .collection(_collection)
          .doc(roomId)
          .update(updatedRoom.toFirestore());

      // Update local state
      final index = _rooms.indexWhere((r) => r.id == roomId);
      if (index != -1) {
        _rooms[index] = updatedRoom;
        _applyFilters();
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

  // Cancel room reservation
  Future<bool> cancelReservation(String roomId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get the room
      final roomDoc =
          await _firestore.collection(_collection).doc(roomId).get();
      final room = Room.fromFirestore(roomDoc);

      // Update room reservation status
      final updatedRoom = room.copyWith(
        status: RoomStatus.available,
        reservedBy: null,
        reservationStart: null,
        reservationEnd: null,
      );

      await _firestore
          .collection(_collection)
          .doc(roomId)
          .update(updatedRoom.toFirestore());

      // Update local state
      final index = _rooms.indexWhere((r) => r.id == roomId);
      if (index != -1) {
        _rooms[index] = updatedRoom;
        _applyFilters();
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

  // Apply filters to rooms
  void _applyFilters() {
    if (_searchQuery.isEmpty && _statusFilter.isEmpty) {
      _filteredRooms = List.from(_rooms);
      return;
    }

    _filteredRooms =
        _rooms.where((room) {
          // Filter by status if selected
          if (_statusFilter.isNotEmpty) {
            if (_statusFilter == 'available' && room.isReserved) {
              return false;
            } else if (_statusFilter == 'reserved' && !room.isReserved) {
              return false;
            }
          }

          // Filter by search query if provided
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            return room.name.toLowerCase().startsWith(query);
          }

          return true;
        }).toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear all filters and search
  void clearFilters() {
    _statusFilter = '';
    _searchQuery = '';
    _filteredRooms = List.from(_rooms);
    notifyListeners();
  }
}
