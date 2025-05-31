import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:s1/providers/room_booking_provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/room_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/room.dart';
import '../../widgets/student_nav_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomBookingScreen extends StatefulWidget {
  const RoomBookingScreen({super.key});

  @override
  State<RoomBookingScreen> createState() => _RoomBookingScreenState();
}

class _RoomBookingScreenState extends State<RoomBookingScreen> {
  DateTime _selectedDate = DateTime.now();

  final List<String> _filters = ['All Rooms', 'Available', 'Occupied'];
  String _selectedFilter = 'All Rooms';

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    await roomProvider.fetchRooms();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  List<Room> _getFilteredRooms(List<Room> rooms) {
    if (_selectedFilter == 'Available') {
      return rooms.where((room) => !room.isReserved).toList();
    } else if (_selectedFilter == 'Occupied') {
      return rooms.where((room) => room.isReserved).toList();
    }
    return rooms;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark; // <-- Add this line
    final roomProvider = Provider.of<RoomProvider>(context);
    final rooms = roomProvider.rooms;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Booking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Date selection only
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF222222) : AppColors.white, // <-- updated
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Date',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary, // <-- updated
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: isDark ? const Color(0xFF222222) : Colors.white, // <-- updated
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 20, color: isDark ? Colors.white : AppColors.textPrimary), // <-- updated
                              const SizedBox(width: 8),
                              Text(
                                DateFormat(
                                  'MMM dd, yyyy',
                                ).format(_selectedDate),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white : AppColors.textPrimary, // <-- updated
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Filter buttons
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (_) => _applyFilter(filter),
                          backgroundColor: AppColors.lightGray,
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
          // Room list
          Expanded(
            child:
                roomProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : rooms.isEmpty
                    ? const Center(
                      child: Text(
                        'No rooms available for the selected criteria',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                    : FutureBuilder<List<Widget>>(
                      future: _buildFilteredRoomWidgets(context, rooms),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final filteredRoomWidgets = snapshot.data!;
                        if (filteredRoomWidgets.isEmpty) {
                          return const Center(
                            child: Text(
                              'No rooms available for the selected criteria',
                              style: TextStyle(fontSize: 16),
                            ),
                          );
                        }
                        return ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          children: filteredRoomWidgets,
                        );
                      },
                    ),
          ),
        ],
      ),
      bottomNavigationBar: StudentNavBar(currentIndex: 0, context: context),
    );
  }

  Future<List<Widget>> _buildFilteredRoomWidgets(
    BuildContext context,
    List<Room> rooms,
  ) async {
    final date = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    List<Widget> widgets = [];
    for (final room in rooms) {
      final slotsSnapshot =
          await FirebaseFirestore.instance
              .collection('slots')
              .doc(room.id)
              .collection('slots')
              .where(
                'date',
                isEqualTo: '${date.year}-${date.month}-${date.day}',
              )
              .get();
      final docs = slotsSnapshot.docs;
      bool allReserved =
          docs.length == 10 &&
          docs.every((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            return (data?['isReserved'] ?? false) == true;
          });
      bool anyAvailable =
          docs.length < 10 ||
          docs.any((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            return (data?['isReserved'] ?? false) == false;
          });
      if (_selectedFilter == 'Available' && !anyAvailable) continue;
      if (_selectedFilter == 'Occupied' && !allReserved) continue;
      widgets.add(_buildRoomItem(context, room));
    }
    return widgets;
  }

  Widget _buildRoomItem(BuildContext context, Room room) {
    final date = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    return FutureBuilder(
      future:
          FirebaseFirestore.instance
              .collection('slots')
              .doc(room.id)
              .collection('slots')
              .where(
                'date',
                isEqualTo: '${date.year}-${date.month}-${date.day}',
              )
              .get(),
      builder: (context, snapshot) {
        bool allReserved = false;
        if (snapshot.hasData) {
          final docs = (snapshot.data as QuerySnapshot).docs;
          if (docs.length == 10 &&
              docs.every((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                return (data?['isReserved'] ?? false) == true;
              })) {
            allReserved = true;
          }
        }
        final statusColor = allReserved ? AppColors.error : AppColors.success;
        final statusText = allReserved ? 'Occupied' : 'Available';
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.2),
              child: Icon(Icons.meeting_room, color: statusColor),
            ),
            title: Text(room.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ID: ${room.id}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text('Capacity: ${room.capacity}'),
                if (room.location != null) Text('Location: ${room.location}'),
              ],
            ),
            trailing: Text(statusText, style: TextStyle(color: statusColor)),
            onTap:
                allReserved
                    ? null
                    : () async {
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      if (authProvider.user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please login to book a room'),
                          ),
                        );
                        return;
                      }
                      final userId = authProvider.user!.id;
                      final allRoomsSnapshot =
                          await FirebaseFirestore.instance
                              .collection('rooms')
                              .get();
                      int totalUserSlots = 0;
                      for (var roomDoc in allRoomsSnapshot.docs) {
                        final userSlotsSnapshot =
                            await FirebaseFirestore.instance
                                .collection('slots')
                                .doc(roomDoc.id)
                                .collection('slots')
                                .where(
                                  'date',
                                  isEqualTo:
                                      '${date.year}-${date.month}-${date.day}',
                                )
                                .where('reservedBy', isEqualTo: userId)
                                .where('isReserved', isEqualTo: true)
                                .get();
                        totalUserSlots += userSlotsSnapshot.docs.length;
                      }
                      if (totalUserSlots >= 1) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'You can only reserve 1 slot per day.',
                            ),
                          ),
                        );
                        return;
                      }
                      final slots = List.generate(10, (i) {
                        final start = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          8 + i,
                          0,
                        );
                        final end = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          9 + i,
                          0,
                        );
                        return {
                          'id':
                              '${date.year}-${date.month}-${date.day}-${start.hour}',
                          'startTime': start,
                          'endTime': end,
                          'isReserved': false,
                          'reservedBy': null,
                        };
                      });
                      final reservedSnapshot =
                          await FirebaseFirestore.instance
                              .collection('slots')
                              .doc(room.id)
                              .collection('slots')
                              .where(
                                'date',
                                isEqualTo:
                                    '${date.year}-${date.month}-${date.day}',
                              )
                              .get();
                      for (var doc in reservedSnapshot.docs) {
                        final data = doc.data();
                        final slotId = doc.id;
                        final index = slots.indexWhere(
                          (s) => s['id'] == slotId,
                        );
                        if (index != -1) {
                          slots[index]['isReserved'] =
                              data['isReserved'] ?? false;
                          slots[index]['reservedBy'] = data['reservedBy'];
                          if (data['startTime'] != null) {
                            slots[index]['startTime'] =
                                (data['startTime'] as Timestamp).toDate();
                          }
                          if (data['endTime'] != null) {
                            slots[index]['endTime'] =
                                (data['endTime'] as Timestamp).toDate();
                          }
                        }
                      }
                      final selectedSlot = await showDialog<
                        Map<String, dynamic>
                      >(
                        context: context,
                        builder:
                            (ctx) => AlertDialog(
                              title: Text('Select a Slot'),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: slots.length,
                                  itemBuilder: (context, index) {
                                    final slot = slots[index];
                                    final reserved = slot['isReserved'] == true;
                                    return ListTile(
                                      title: Text(
                                        '${TimeOfDay.fromDateTime(slot['startTime'] as DateTime).format(context)} - ${TimeOfDay.fromDateTime(slot['endTime'] as DateTime).format(context)}',
                                      ),
                                      subtitle:
                                          reserved
                                              ? Text(
                                                'Occupied',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              )
                                              : Text(
                                                'Available',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                ),
                                              ),
                                      enabled: !reserved,
                                      onTap:
                                          reserved
                                              ? null
                                              : () => Navigator.pop(ctx, slot),
                                    );
                                  },
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text('Cancel'),
                                ),
                              ],
                            ),
                      );
                      if (selectedSlot == null) return;
                      await FirebaseFirestore.instance
                          .collection('slots')
                          .doc(room.id)
                          .collection('slots')
                          .doc(selectedSlot['id'])
                          .set({
                            'startTime': selectedSlot['startTime'],
                            'endTime': selectedSlot['endTime'],
                            'isReserved': true,
                            'reservedBy': userId,
                            'date': '${date.year}-${date.month}-${date.day}',
                          });
                      final allSlotsSnapshot =
                          await FirebaseFirestore.instance
                              .collection('slots')
                              .doc(room.id)
                              .collection('slots')
                              .where(
                                'date',
                                isEqualTo:
                                    '${date.year}-${date.month}-${date.day}',
                              )
                              .get();
                      final allReserved = allSlotsSnapshot.docs.every(
                        (doc) => (doc.data()['isReserved'] ?? false) == true,
                      );
                      if (allReserved) {
                        await FirebaseFirestore.instance
                            .collection('rooms')
                            .doc(room.id)
                            .update({'status': 'occupied'});
                      } else {
                        await FirebaseFirestore.instance
                            .collection('rooms')
                            .doc(room.id)
                            .update({'status': 'available'});
                      }
                      final roomProvider = Provider.of<RoomProvider>(
                        context,
                        listen: false,
                      );
                      await roomProvider.fetchRooms();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Room booked successfully')),
                      );
                    },
          ),
        );
      },
    );
  }
}