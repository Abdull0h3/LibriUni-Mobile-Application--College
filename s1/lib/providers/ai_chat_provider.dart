import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ai_chat_message.dart';

class AIChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'ai_chats';

  List<AIChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<AIChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get chat history for a user
  Stream<List<AIChatMessage>> getAIChatMessages(String userId) {
    return _firestore
        .collection(_collection)
        .doc(userId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AIChatMessage.fromFirestore(doc))
              .toList();
        });
  }

  // Send message to AI
  Future<void> sendMessage(String userId, String message) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Store user message
      await _storeMessage(userId, message, false);

      // Generate AI response
      final aiResponse = await _generateAIResponse(message);
      await _storeMessage(
        userId,
        aiResponse.message,
        true,
        type: aiResponse.type,
        options: aiResponse.options,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _storeMessage(
    String userId,
    String message,
    bool isAi, {
    AIChatMessageType type = AIChatMessageType.text,
    List<String>? options,
  }) async {
    final aiMessage = AIChatMessage(
      id: '',
      isAi: isAi,
      message: message,
      type: type,
      options: options,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection(_collection)
        .doc(userId)
        .collection('messages')
        .add(aiMessage.toFirestore());
  }

  Future<AIChatMessage> _generateAIResponse(String userMessage) async {
    // Simulate AI processing time
    await Future.delayed(const Duration(seconds: 1));

    // Default welcome message
    if (_messages.isEmpty) {
      return AIChatMessage(
        id: '',
        isAi: true,
        message:
            'Hello! I\'m your LibriUni AI assistant. How can I help you today?',
        type: AIChatMessageType.options,
        options: [
          '1. Connect with library staff',
          '2. Book search help',
          '3. Room reservation help',
          '4. Library policies',
          '5. Other questions',
        ],
        timestamp: DateTime.now(),
      );
    }

    // Process user selection
    if (userMessage == '1') {
      return AIChatMessage(
        id: '',
        isAi: true,
        message:
            'I\'ll connect you with our library staff. Please wait while I transfer you to a staff member.',
        type: AIChatMessageType.text,
        timestamp: DateTime.now(),
      );
    }

    // Handle other options with predefined responses
    final lowerMessage = userMessage.toLowerCase();
    if (lowerMessage.contains('book') || userMessage == '2') {
      return AIChatMessage(
        id: '',
        isAi: true,
        message:
            'I can help you with book-related queries. What would you like to know?',
        type: AIChatMessageType.options,
        options: [
          '1. How to search for books',
          '2. How to borrow books',
          '3. Check book availability',
          '4. Return procedures',
          '5. Connect with staff',
        ],
        timestamp: DateTime.now(),
      );
    }

    if (lowerMessage.contains('room') || userMessage == '3') {
      return AIChatMessage(
        id: '',
        isAi: true,
        message:
            'I can help you with room reservations. What information do you need?',
        type: AIChatMessageType.options,
        options: [
          '1. Room booking process',
          '2. Available room types',
          '3. Booking duration limits',
          '4. Cancellation policy',
          '5. Connect with staff',
        ],
        timestamp: DateTime.now(),
      );
    }

    // Default response for unrecognized queries
    return AIChatMessage(
      id: '',
      isAi: true,
      message: 'I understand you need help. Would you like to:',
      type: AIChatMessageType.options,
      options: [
        '1. Connect with library staff',
        '2. Try another question',
        '3. View help topics',
      ],
      timestamp: DateTime.now(),
    );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
