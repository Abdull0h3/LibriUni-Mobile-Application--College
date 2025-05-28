import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/room_booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/room_booking.dart';
import '../../constants/app_colors.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/student_nav_bar.dart';
import 'package:go_router/go_router.dart';

class MyReservedRoomsScreen extends StatefulWidget {
  const MyReservedRoomsScreen({super.key});

  @override
  State<MyReservedRoomsScreen> createState() => _MyReservedRoomsScreenState();
}

class _MyReservedRoomsScreenState extends State<MyReservedRoomsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        context.read<RoomBookingProvider>().fetchUserBookings(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int currentIndex = 0;
    final String path = GoRouterState.of(context).fullPath ?? '/student';
    if (path.startsWith('/student/ai-chat')) {
      currentIndex = 1;
    } else if (path.startsWith('/student/profile')) {
      currentIndex = 2;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My Reserved Rooms')),
      body: Consumer<RoomBookingProvider>(
        builder: (context, bookingProvider, child) {
          if (bookingProvider.isLoading) {
            return const LoadingIndicator();
          }

          if (bookingProvider.error != null) {
            return CustomErrorWidget(
              error: bookingProvider.error!,
              onRetry: () {
                final userId = context.read<AuthProvider>().user?.id;
                if (userId != null) {
                  bookingProvider.fetchUserBookings(userId);
                }
              },
            );
          }

          final bookings = bookingProvider.userBookings;

          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.meeting_room_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No room reservations yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Book a room to study or collaborate',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to room booking screen
                      Navigator.pushNamed(context, '/student/room-booking');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Book a Room'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final isUpcoming = booking.startTime.isAfter(DateTime.now());
              final isOngoing =
                  booking.startTime.isBefore(DateTime.now()) &&
                  booking.endTime.isAfter(DateTime.now());

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.roomName,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Capacity: ${booking.roomCapacity} people',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          _buildStatusChip(context, isUpcoming, isOngoing),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoRow(
                              context,
                              Icons.calendar_today_outlined,
                              _formatDate(booking.startTime),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInfoRow(
                              context,
                              Icons.access_time_outlined,
                              '${_formatTime(booking.startTime)} - ${_formatTime(booking.endTime)}',
                            ),
                          ),
                        ],
                      ),
                      if (booking.purpose != null) ...[
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          context,
                          Icons.description_outlined,
                          booking.purpose!,
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (isUpcoming)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Cancel Reservation'),
                                        content: const Text(
                                          'Are you sure you want to cancel this room reservation?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                            child: const Text('No'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            child: const Text('Yes'),
                                          ),
                                        ],
                                      ),
                                ).then((shouldCancel) {
                                  if (shouldCancel == true) {
                                    bookingProvider.cancelBooking(booking.id);
                                  }
                                });
                              },
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Cancel'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                    ],
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

  Widget _buildStatusChip(
    BuildContext context,
    bool isUpcoming,
    bool isOngoing,
  ) {
    Color color;
    String text;
    IconData icon;

    if (isOngoing) {
      color = AppColors.primary;
      text = 'Ongoing';
      icon = Icons.meeting_room;
    } else if (isUpcoming) {
      color = Colors.orange;
      text = 'Upcoming';
      icon = Icons.upcoming;
    } else {
      color = AppColors.textSecondary;
      text = 'Past';
      icon = Icons.history;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
