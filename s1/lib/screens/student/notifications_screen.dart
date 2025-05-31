import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/notification.dart';
import '../../constants/app_colors.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/student_nav_bar.dart';
import 'package:go_router/go_router.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        context.read<NotificationProvider>().fetchNotifications(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int currentIndex = 0;
    final String path = GoRouterState.of(context).fullPath ?? '/student';
    if (path.startsWith('/student/chat')) {
      currentIndex = 1;
    } else if (path.startsWith('/student/profile')) {
      currentIndex = 2;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              final userId = context.read<AuthProvider>().user?.id;
              if (userId != null) {
                // Show confirmation dialog
                final shouldClear = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Clear All Notifications'),
                        content: const Text(
                          'Are you sure you want to clear all notifications?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                );

                if (shouldClear == true) {
                  await context
                      .read<NotificationProvider>()
                      .clearAllNotifications(userId);
                }
              }
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (notificationProvider.isLoading) {
            return const LoadingIndicator();
          }

          if (notificationProvider.error != null) {
            return CustomErrorWidget(
              error: notificationProvider.error!,
              onRetry: () {
                final userId = context.read<AuthProvider>().user?.id;
                if (userId != null) {
                  notificationProvider.fetchNotifications(userId);
                }
              },
            );
          }

          final notifications = notificationProvider.notifications;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Dismissible(
                key: Key(notification.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: AppColors.error,
                  child: const Icon(
                    Icons.delete_outline,
                    color: AppColors.white,
                  ),
                ),
                onDismissed: (_) {
                  notificationProvider.deleteNotification(notification.id);
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      if (!notification.isRead) {
                        notificationProvider.markAsRead(notification.id);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getNotificationIcon(
                                  notification.type.toString(),
                                ),
                                color:
                                    notification.isRead
                                        ? AppColors.textSecondary
                                        : AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    fontWeight:
                                        notification.isRead
                                            ? FontWeight.normal
                                            : FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (!notification.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                  ),
                                ),
                            ],
                          ),
                          if (notification.message != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              notification.message!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            _formatDate(notification.date),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: StudentNavBar(
        currentIndex: currentIndex,
        context: context,
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'book':
        return Icons.book_outlined;
      case 'room':
        return Icons.meeting_room_outlined;
      case 'due':
        return Icons.timer_outlined;
      case 'fine':
        return Icons.attach_money_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
