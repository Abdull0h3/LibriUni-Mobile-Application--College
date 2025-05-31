import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart';
import '../../models/chat_message_model.dart';
import '../../constants/app_colors.dart';

class StaffStudentChatDetailScreen extends StatefulWidget {
  final String studentId;
  final String staffId;
  final String studentName;

  const StaffStudentChatDetailScreen({
    Key? key,
    required this.studentId,
    required this.staffId,
    required this.studentName,
  }) : super(key: key);

  @override
  State<StaffStudentChatDetailScreen> createState() =>
      _StaffStudentChatDetailScreenState();
}

class _StaffStudentChatDetailScreenState
    extends State<StaffStudentChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      await _chatService.sendStudentMessage(
        studentId: widget.studentId,
        senderId: widget.staffId,
        message: _messageController.text.trim(),
        receiverId: widget.studentId,
      );
      _messageController.clear();
      // No need to scroll to bottom here, StreamBuilder will handle it with new message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.studentName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            Text(
              widget.studentId,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getStaffChatMessages(widget.studentId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Start typing to begin.'),
                  );
                }

                final messages = snapshot.data!;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollToBottom();
                  }
                });

                // Mark messages as read when they are loaded
                // Ensure to mark messages received by the staff user (the current user of this screen)
                _chatService.markMessagesAsRead(
                  widget.studentId,
                  widget.staffId,
                );

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == widget.staffId;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.65,
                        ),
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: isMe ? 0 : 0,
                            vertical: 4,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isMe
                                    ? AppColors.primary.withOpacity(0.8)
                                    : Colors.grey[300],
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                              bottomLeft:
                                  isMe
                                      ? Radius.circular(16)
                                      : Radius.circular(4),
                              bottomRight:
                                  isMe
                                      ? Radius.circular(4)
                                      : Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                            children: [
                              // Display sender name if not staff
                              FutureBuilder<DocumentSnapshot>(
                                future:
                                    FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(message.senderId)
                                        .get(),
                                builder: (context, userSnapshot) {
                                  if (userSnapshot.hasData &&
                                      userSnapshot.data!.exists) {
                                    final userData =
                                        userSnapshot.data!.data()
                                            as Map<String, dynamic>;
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 4.0,
                                      ),
                                      child: Text(
                                        userData['name'] ?? 'Student',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    );
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                },
                              ),
                              Text(
                                message.message,
                                style: TextStyle(
                                  color:
                                      isMe
                                          ? AppColors.white
                                          : AppColors.textPrimary,
                                ),
                              ),
                            ],
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
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
