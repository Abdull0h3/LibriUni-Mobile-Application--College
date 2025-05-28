import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ai_chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/ai_chat_message.dart';
import '../../constants/app_colors.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/student_nav_bar.dart';
import 'package:go_router/go_router.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
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
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthProvider>().user;
    int currentIndex = 1;
    final String path = GoRouterState.of(context).fullPath ?? '/student';
    if (path.startsWith('/student/profile')) {
      currentIndex = 2;
    } else if (path == '/student' ||
        (path.startsWith('/student') && !path.startsWith('/student/ai-chat'))) {
      currentIndex = 0;
    }
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to access AI chat')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('AI Assistant Help'),
                      content: const Text(
                        'This AI assistant can help you with:\n\n'
                        '• Book-related queries\n'
                        '• Room reservations\n'
                        '• Library policies\n'
                        '• Connecting with staff\n\n'
                        'You can type your question or select from the available options.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Got it'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<AIChatMessage>>(
              stream: context.read<AIChatProvider>().getAIChatMessages(
                currentUser.id,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return CustomErrorWidget(
                    error: snapshot.error.toString(),
                    onRetry: () {
                      setState(() {});
                    },
                  );
                }

                if (!snapshot.hasData) {
                  return const LoadingIndicator();
                }

                final messages = snapshot.data!;

                if (messages.isEmpty) {
                  // Send initial message
                  Future.microtask(() {
                    context.read<AIChatProvider>().sendMessage(
                      currentUser.id,
                      '',
                    );
                  });
                  return const LoadingIndicator();
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildMessageBubble(message);
                  },
                );
              },
            ),
          ),
          Consumer<AIChatProvider>(
            builder: (context, aiProvider, child) {
              if (aiProvider.isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: LinearProgressIndicator(),
                );
              }
              return const SizedBox();
            },
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (message) {
                        _sendMessage(currentUser.id);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded),
                      color: AppColors.white,
                      onPressed: () => _sendMessage(currentUser.id),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: StudentNavBar(
        currentIndex: currentIndex,
        context: context,
      ),
    );
  }

  void _sendMessage(String userId) {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      context.read<AIChatProvider>().sendMessage(userId, message);
      _messageController.clear();
      _scrollToBottom();
    }
  }

  Widget _buildMessageBubble(AIChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            message.isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (message.isAi) ...[
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.smart_toy, color: AppColors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  message.isAi
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        message.isAi
                            ? AppColors.secondary.withOpacity(0.1)
                            : AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        message.isAi
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.end,
                    children: [
                      Text(
                        message.message,
                        style: TextStyle(
                          color:
                              message.isAi
                                  ? AppColors.textPrimary
                                  : AppColors.white,
                        ),
                      ),
                      if (message.options != null) ...[
                        const SizedBox(height: 8),
                        ...message.options!.map(
                          (option) => TextButton(
                            onPressed: () {
                              _messageController.text = option.split('.').first;
                              _sendMessage(
                                context.read<AuthProvider>().user!.id,
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              alignment: Alignment.centerLeft,
                              foregroundColor:
                                  message.isAi
                                      ? AppColors.primary
                                      : AppColors.white,
                            ),
                            child: Text(option),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMessageTime(message.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!message.isAi) const SizedBox(width: 24),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
