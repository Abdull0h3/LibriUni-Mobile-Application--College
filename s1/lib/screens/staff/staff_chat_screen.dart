import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart';
import '../../models/chat_message_model.dart';
import '../../constants/app_colors.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class StaffChatScreen extends StatefulWidget {
  final String staffId;
  final String staffName;

  const StaffChatScreen({
    Key? key,
    required this.staffId,
    required this.staffName,
  }) : super(key: key);

  @override
  State<StaffChatScreen> createState() => _StaffChatScreenState();
}

class _StaffChatScreenState extends State<StaffChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _selectedStudentId;
  String? _selectedStudentName;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0, // Scroll to the top (latest message)
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty &&
        _selectedStudentId != null) {
      // Send message to the selected student's chat thread
      await _chatService.sendStudentMessage(
        studentId: _selectedStudentId!,
        senderId: widget.staffId,
        message: _messageController.text.trim(),
      );
      _messageController.clear();
      // No need to scroll to bottom here, StreamBuilder will handle it with new message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Chats')),
      body: Row(
        children: [
          // Student list sidebar
          Container(
            width: 350, // Increased width for better readability
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // Stream active chat threads
              stream: _chatService.getStudentsWithActiveChats(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final activeChats = snapshot.data!;

                if (activeChats.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No active student chats at the moment.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: activeChats.length,
                  itemBuilder: (context, index) {
                    final chat = activeChats[index];
                    final studentId = chat['id'] as String;
                    final studentName =
                        chat['studentName'] ?? 'Unknown Student';
                    final lastMessage = chat['lastMessage'] ?? '';
                    final lastMessageTimestamp =
                        chat['lastMessageTimestamp'] as Timestamp?;

                    String formattedTime = '';
                    if (lastMessageTimestamp != null) {
                      DateTime messageTime = lastMessageTimestamp.toDate();
                      if (DateTime.now().difference(messageTime).inDays == 0) {
                        formattedTime = DateFormat(
                          'jm',
                        ).format(messageTime); // e.g., 5:08 PM
                      } else {
                        formattedTime = DateFormat(
                          'MM/dd/yy',
                        ).format(messageTime); // e.g., 10/27/23
                      }
                    }

                    return StreamBuilder<int>(
                      // Get unread count for this specific student's chat thread for the current staff
                      stream: _chatService.getUnreadMessageCountForStudent(
                        studentId,
                        widget.staffId,
                      ),
                      builder: (context, unreadSnapshot) {
                        final unreadCount = unreadSnapshot.data ?? 0;

                        // Build the ListTile for each student chat thread
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 10.0,
                          ), // Adjusted vertical padding for better spacing
                          selected: studentId == _selectedStudentId,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.2),
                            radius: 24, // Slightly larger avatar
                            child: Text(
                              studentName.isNotEmpty
                                  ? studentName[0].toUpperCase()
                                  : '',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ), // Larger and bolder font for avatar
                            ),
                          ),
                          title: Text(
                            studentName, // Display student name as title
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight:
                                  studentId == _selectedStudentId ||
                                          unreadCount > 0
                                      ? FontWeight.bold
                                      : FontWeight
                                          .w600, // Slightly bolder for normal
                              fontSize: 16.0, // Standard font size
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(
                              top: 2.0,
                            ), // Reduced space between name and message
                            child: Text(
                              lastMessage.isEmpty
                                  ? 'Start a conversation...' // Show placeholder if no messages
                                  : lastMessage, // Display last message as subtitle
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14, // Standard font size
                                color:
                                    unreadCount > 0
                                        ? AppColors
                                            .secondary // Highlight unread messages
                                        : Colors.grey[600],
                              ),
                            ),
                          ),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (formattedTime.isNotEmpty)
                                Text(
                                  formattedTime, // Display formatted timestamp
                                  style: const TextStyle(
                                    fontSize:
                                        11, // Slightly larger timestamp font
                                    color: Colors.grey,
                                  ),
                                ),
                              if (unreadCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(
                                    top: 4.0,
                                  ), // Space above badge
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ), // Adjusted padding
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors
                                            .secondary, // Use a different color for unread count
                                    borderRadius: BorderRadius.circular(
                                      10,
                                    ), // Slightly smaller border radius
                                  ),
                                  child: Text(
                                    unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          10, // Standard font size for badge
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              _selectedStudentId = studentId;
                              _selectedStudentName = studentName;
                            });
                            // Mark messages as read when staff selects the chat
                            _chatService.markMessagesAsRead(
                              studentId,
                              widget.staffId,
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          // Chat area
          Expanded(
            child:
                _selectedStudentId == null
                    ? const Center(
                      child: Text(
                        'Select a student from the list to view the chat.',
                      ),
                    )
                    : Column(
                      children: [
                        AppBar(
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedStudentName ?? '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                              ),
                              Text(
                                _selectedStudentId ?? '',
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
                        Expanded(
                          child: StreamBuilder<List<ChatMessage>>(
                            stream: _chatService.getStaffChatMessages(
                              _selectedStudentId!,
                            ), // Get messages for the selected student's thread
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text('Error: ${snapshot.error}'),
                                );
                              }

                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No messages yet. Start typing to begin.',
                                  ),
                                );
                              }

                              final messages = snapshot.data!;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                // Only scroll to bottom if it's the first load or a new message arrives from the other user
                                if (_scrollController.hasClients) {
                                  // Check if the last message is sent by the student (not the current staff user)
                                  if (messages.isNotEmpty &&
                                      messages.last.senderId !=
                                          widget.staffId) {
                                    _scrollToBottom();
                                  } else if (messages.length == 1 &&
                                      messages.last.senderId ==
                                          widget.staffId) {
                                    // If it's the very first message and sent by staff, still scroll to bottom
                                    _scrollToBottom();
                                  }
                                }
                              });

                              return ListView.builder(
                                controller: _scrollController,
                                reverse:
                                    true, // Show latest messages at the bottom
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final message = messages[index];
                                  final isMe =
                                      message.senderId == widget.staffId;

                                  // Format timestamp for message bubble (optional, could add later)
                                  // String messageTime = DateFormat('h:mm a').format(message.timestamp);

                                  return Align(
                                    alignment:
                                        isMe
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            0.65, // Limit bubble width
                                      ),
                                      child: Container(
                                        margin: EdgeInsets.symmetric(
                                          horizontal: isMe ? 8 : 8,
                                          vertical: 4,
                                        ), // Adjusted margin based on sender
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isMe
                                                  ? AppColors.primary.withOpacity(
                                                    0.8,
                                                  ) // Different color for sent messages
                                                  : Colors
                                                      .grey[300], // Color for received messages
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            topRight: Radius.circular(16),
                                            bottomLeft:
                                                isMe
                                                    ? Radius.circular(16)
                                                    : Radius.circular(
                                                      4,
                                                    ), // Pointed corner for received
                                            bottomRight:
                                                isMe
                                                    ? Radius.circular(4)
                                                    : Radius.circular(
                                                      16,
                                                    ), // Pointed corner for sent
                                          ), // Adjusted border radius
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              isMe
                                                  ? CrossAxisAlignment.end
                                                  : CrossAxisAlignment.start,
                                          children: [
                                            if (!isMe) // Display sender name if not staff
                                              FutureBuilder<DocumentSnapshot>(
                                                // Fetch sender name for student messages
                                                future:
                                                    FirebaseFirestore.instance
                                                        .collection('users')
                                                        .doc(message.senderId)
                                                        .get(),
                                                builder: (
                                                  context,
                                                  userSnapshot,
                                                ) {
                                                  if (userSnapshot.hasData &&
                                                      userSnapshot
                                                          .data!
                                                          .exists) {
                                                    final userData =
                                                        userSnapshot.data!
                                                                .data()
                                                            as Map<
                                                              String,
                                                              dynamic
                                                            >;
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 4.0,
                                                          ),
                                                      child: Text(
                                                        userData['name'] ??
                                                            'Student', // Use fetched student name
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12,
                                                          color:
                                                              AppColors
                                                                  .textSecondary,
                                                        ),
                                                      ),
                                                    );
                                                  } else {
                                                    return const SizedBox.shrink(); // Or a placeholder like 'Student'
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
                                            // Optional: Add message timestamp below the message
                                            // Padding(
                                            //   padding: const EdgeInsets.only(top: 4.0),
                                            //   child: Text(
                                            //     messageTime,
                                            //     style: const TextStyle(
                                            //       fontSize: 10,
                                            //       color: Colors.black54,
                                            //     ),
                                            //   ),
                                            // ),
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
                                    ), // Added padding
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        24.0,
                                      ), // Rounded corners
                                      borderSide: BorderSide.none,
                                    ),
                                    isDense: true, // Reduced height
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
          ),
        ],
      ),
    );
  }
}
