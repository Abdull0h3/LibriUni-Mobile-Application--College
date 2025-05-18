import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum representing room status
enum RoomStatus { available, occupied, underMaintenance }

/// Extension to convert RoomStatus to and from string values
extension RoomStatusExtension on RoomStatus {
  String get name {
    switch (this) {
      case RoomStatus.available:
        return 'available';
      case RoomStatus.occupied:
        return 'occupied';
      case RoomStatus.underMaintenance:
        return 'underMaintenance';
    }
  }

  static RoomStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return RoomStatus.available;
      case 'occupied':
        return RoomStatus.occupied;
      case 'undermaintenance':
      case 'under_maintenance':
      case 'under maintenance':
        return RoomStatus.underMaintenance;
      default:
        return RoomStatus.available;
    }
  }
}

class Room {
  final String id;
  final String name;
  final int capacity;
  final RoomStatus status;
  final String? reservedBy;
  final DateTime? reservationStart;
  final DateTime? reservationEnd;
  final String? description;
  final String? location;

  Room({
    required this.id,
    required this.name,
    required this.capacity,
    required this.status,
    this.reservedBy,
    this.reservationStart,
    this.reservationEnd,
    this.description,
    this.location,
  });

  /// Create a Room from a Firestore document
  factory Room.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Room(
      id: doc.id,
      name: data['name'] ?? '',
      capacity: data['capacity'] ?? 0,
      status: RoomStatusExtension.fromString(data['status'] ?? 'available'),
      reservedBy: data['reservedBy'],
      reservationStart: (data['reservationStart'] as Timestamp?)?.toDate(),
      reservationEnd: (data['reservationEnd'] as Timestamp?)?.toDate(),
      description: data['description'],
      location: data['location'],
    );
  }

  /// Convert Room to a Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'capacity': capacity,
      'status': status.name,
      'reservedBy': reservedBy,
      'reservationStart':
          reservationStart != null
              ? Timestamp.fromDate(reservationStart!)
              : null,
      'reservationEnd':
          reservationEnd != null ? Timestamp.fromDate(reservationEnd!) : null,
      'description': description,
      'location': location,
    };
  }

  /// Check if the room is currently reserved
  bool get isReserved => status == RoomStatus.occupied;

  /// Create a copy of the room with updated fields
  Room copyWith({
    String? id,
    String? name,
    int? capacity,
    RoomStatus? status,
    String? reservedBy,
    DateTime? reservationStart,
    DateTime? reservationEnd,
    String? description,
    String? location,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      reservedBy: reservedBy ?? this.reservedBy,
      reservationStart: reservationStart ?? this.reservationStart,
      reservationEnd: reservationEnd ?? this.reservationEnd,
      description: description ?? this.description,
      location: location ?? this.location,
    );
  }
}
