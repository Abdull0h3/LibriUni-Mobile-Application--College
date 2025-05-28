import 'package:cloud_firestore/cloud_firestore.dart';

enum AIChatMessageType { text, options, error }

class AIChatMessage {
  final String id;
  final bool isAi;
  final String message;
  final AIChatMessageType type;
  final List<String>? options;
  final DateTime timestamp;

  AIChatMessage({
    required this.id,
    required this.isAi,
    required this.message,
    required this.type,
    this.options,
    required this.timestamp,
  });

  factory AIChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AIChatMessage(
      id: doc.id,
      isAi: data['isAi'] as bool,
      message: data['message'] as String,
      type: AIChatMessageType.values[data['type'] as int],
      options: (data['options'] as List<dynamic>?)?.cast<String>(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'isAi': isAi,
      'message': message,
      'type': type.index,
      'options': options,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
