import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart';
import '../../models/chat_message_model.dart';

class StudentChatScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentChatScreen({
    Key? key,
    required this.studentId,
    required this.studentName,
  }) : super(key: key);

  @override
  State<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends State<StudentChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Mark messages as read when the chat screen is opened
    _chatService.markMessagesAsRead(
      widget.studentId,
      widget.studentId,
    ); // Student is the reader
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      // >>> IMPORTANT: REPLACE THIS WITH THE ACTUAL FIREBASE USER UID OF A STAFF MEMBER <<<
      // This is the staff member who will receive general student inquiries from this screen.
      final staffReceiverId = 'y2GY7v4Xp5fEnnQmHFw11sk3U4a2';
      // You can get this UID from your Firebase Authentication console.

      // Consider adding a check here to ensure staffReceiverId is not the placeholder before sending
      if (staffReceiverId == 'REPLACE_WITH_REAL_STAFF_USER_ID') {
        print(
          "WARNING: Staff receiver ID placeholder not replaced in StudentMessageScreen._sendMessage. Messages may not be routed correctly.",
        );
        // Optionally, prevent message sending until a real ID is provided
        // return;
      }

      await _chatService.sendStudentMessage(
        studentId: widget.studentId, // The chat thread ID (student's own ID)
        senderId: widget.studentId,
        message: _messageController.text.trim(),
        receiverId: staffReceiverId, // Pass the determined staff ID as receiver
      );
      _messageController.clear();
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Help')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getStudentChatMessages(
                widget.studentId,
              ), // Get messages for this student's thread
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Start a conversation...'));
                }

                final messages = snapshot.data!;
                // Mark messages as read when new messages arrive
                // This might be triggered by staff sending a message, so the student reads it.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _chatService.markMessagesAsRead(
                    widget.studentId,
                    widget.studentId,
                  );
                });

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    // Check if the sender is the current student
                    final isMe = message.senderId == widget.studentId;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          message.message,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
