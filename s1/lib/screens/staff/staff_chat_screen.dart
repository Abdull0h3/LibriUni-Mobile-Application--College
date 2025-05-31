import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart';
import '../../models/chat_message_model.dart';
import '../../constants/app_colors.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:go_router/go_router.dart';

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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Chats')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          // Student list
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getStudentsWithActiveChats(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final activeChats = snapshot.data!;

                final filteredChats =
                    activeChats.where((chat) {
                      final studentName =
                          chat['studentName']?.toLowerCase() ?? '';
                      return studentName.contains(_searchQuery);
                    }).toList();

                if (filteredChats.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No active student chats',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredChats.length,
                  itemBuilder: (context, index) {
                    final chat = filteredChats[index];
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
                        formattedTime = DateFormat('jm').format(messageTime);
                      } else {
                        formattedTime = DateFormat(
                          'MM/dd/yy',
                        ).format(messageTime);
                      }
                    }

                    return StreamBuilder<int>(
                      stream: _chatService.getUnreadMessageCountForStudent(
                        studentId,
                        widget.staffId,
                      ),
                      builder: (context, unreadSnapshot) {
                        final unreadCount = unreadSnapshot.data ?? 0;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(
                                  0.2,
                                ),
                                radius: 20,
                                child: Text(
                                  studentName.isNotEmpty
                                      ? studentName[0].toUpperCase()
                                      : '',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Icon(
                                    Icons.circle,
                                    color: AppColors.secondary,
                                    size: 12,
                                  ),
                                ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  studentName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight:
                                        unreadCount > 0
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (formattedTime.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    formattedTime,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          unreadCount > 0
                                              ? AppColors.secondary
                                              : Colors.grey,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            lastMessage.isEmpty
                                ? 'Start a conversation...'
                                : lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  unreadCount > 0
                                      ? AppColors.secondary
                                      : Colors.grey[600],
                            ),
                          ),
                          onTap: () {
                            print(
                              'Tapped on chat with student: $studentName (ID: $studentId)',
                            );

                            // Navigate to the chat detail screen
                            context.push(
                              '/staff/chat/student-detail',
                              extra: {
                                'studentId': studentId,
                                'staffId': widget.staffId,
                                'studentName': studentName,
                              },
                            );

                            // Mark messages as read when navigating to detail screen
                            print(
                              'Calling markMessagesAsRead for student: $studentId, staffId: ${widget.staffId}',
                            );
                            _chatService.markMessagesAsRead(
                              studentId,
                              widget.staffId,
                            );
                            print('markMessagesAsRead called.');
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
