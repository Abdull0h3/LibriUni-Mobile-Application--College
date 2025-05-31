import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/room_booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_colors.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/student_nav_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    if (path.startsWith('/student/chat')) {
      currentIndex = 1;
    } else if (path.startsWith('/student/profile')) {
      currentIndex = 2;
    }
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    return Scaffold(
      appBar: AppBar(title: const Text('My Reserved Rooms')),
      body:
          userId == null
              ? const Center(
                child: Text('Please login to view your reservations'),
              )
              : FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchUserReservedSlots(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingIndicator();
                  }
                  if (snapshot.hasError) {
                    return CustomErrorWidget(
                      error: snapshot.error.toString(),
                      onRetry: () => setState(() {}),
                    );
                  }
                  final bookings = snapshot.data ?? [];
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
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Book a room to study or collaborate',
                            style: Theme.of(context).textTheme.bodyMedium,
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
                      final startTime = booking['startTime'] as DateTime;
                      final canCancel = startTime.isAfter(
                        DateTime.now().add(const Duration(hours: 1)),
                      );
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          booking['roomName'] ?? '',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Capacity: ${booking['roomCapacity'] ?? ''} people',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
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
                                      _formatDate(startTime),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildInfoRow(
                                      context,
                                      Icons.access_time_outlined,
                                      '${_formatTime(startTime)} - ${_formatTime(booking['endTime'] as DateTime)}',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (canCancel)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () async {
                                        await FirebaseFirestore.instance
                                            .collection('slots')
                                            .doc(booking['roomId'])
                                            .collection('slots')
                                            .doc(booking['slotId'])
                                            .update({
                                              'isReserved': false,
                                              'reservedBy': null,
                                            });
                                        setState(() {});
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

  Future<List<Map<String, dynamic>>> _fetchUserReservedSlots(
    String userId,
  ) async {
    final roomsSnapshot =
        await FirebaseFirestore.instance.collection('rooms').get();
    List<Map<String, dynamic>> reserved = [];
    for (final roomDoc in roomsSnapshot.docs) {
      final slotsSnapshot =
          await FirebaseFirestore.instance
              .collection('slots')
              .doc(roomDoc.id)
              .collection('slots')
              .where('reservedBy', isEqualTo: userId)
              .where('isReserved', isEqualTo: true)
              .get();
      for (final slotDoc in slotsSnapshot.docs) {
        final data = slotDoc.data();
        reserved.add({
          'roomId': roomDoc.id,
          'roomName': roomDoc.data()['name'],
          'roomCapacity': roomDoc.data()['capacity'],
          'startTime': (data['startTime'] as Timestamp).toDate(),
          'endTime': (data['endTime'] as Timestamp).toDate(),
          'slotId': slotDoc.id,
        });
      }
    }
    reserved.sort(
      (a, b) =>
          (a['startTime'] as DateTime).compareTo(b['startTime'] as DateTime),
    );
    return reserved;
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
