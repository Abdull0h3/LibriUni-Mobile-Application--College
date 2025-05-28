import 'package:cloud_firestore/cloud_firestore.dart';

class RoomBooking {
  final String id;
  final String userId;
  final String roomId;
  final String roomName;
  final int roomCapacity;
  final DateTime startTime;
  final DateTime endTime;
  final String? purpose;
  final bool isApproved;
  final bool isCancelled;

  RoomBooking({
    required this.id,
    required this.userId,
    required this.roomId,
    required this.roomName,
    required this.roomCapacity,
    required this.startTime,
    required this.endTime,
    this.purpose,
    this.isApproved = false,
    this.isCancelled = false,
  });

  // Create from Firestore document
  factory RoomBooking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomBooking(
      id: doc.id,
      userId: data['userId'] as String,
      roomId: data['roomId'] as String,
      roomName: data['roomName'] as String,
      roomCapacity: data['roomCapacity'] as int,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      purpose: data['purpose'] as String?,
      isApproved: data['isApproved'] as bool? ?? false,
      isCancelled: data['isCancelled'] as bool? ?? false,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'roomId': roomId,
      'roomName': roomName,
      'roomCapacity': roomCapacity,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'purpose': purpose,
      'isApproved': isApproved,
      'isCancelled': isCancelled,
    };
  }

  // Create a copy with modified fields
  RoomBooking copyWith({
    String? id,
    String? userId,
    String? roomId,
    String? roomName,
    int? roomCapacity,
    DateTime? startTime,
    DateTime? endTime,
    String? purpose,
    bool? isApproved,
    bool? isCancelled,
  }) {
    return RoomBooking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      roomCapacity: roomCapacity ?? this.roomCapacity,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      purpose: purpose ?? this.purpose,
      isApproved: isApproved ?? this.isApproved,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }
}
