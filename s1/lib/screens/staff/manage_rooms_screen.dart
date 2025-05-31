//this is for the staff to manage rooms
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../providers/room_provider.dart';
import '../../models/room.dart';

class ManageRoomsScreen extends StatefulWidget {
  const ManageRoomsScreen({Key? key}) : super(key: key);

  @override
  State<ManageRoomsScreen> createState() => _ManageRoomsScreenState();
}

class _ManageRoomsScreenState extends State<ManageRoomsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  List<String> _statusFilters = ['All', 'Available', 'Occupied'];
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
    });

    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    await roomProvider.fetchRooms();

    setState(() {
      _isLoading = false;
    });
  }

  void _searchRooms(String query) {
    setState(() {
      _searchQuery = query;
    });
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    roomProvider.searchRooms(query);
  }

  void _filterByStatus(String status) {
    setState(() {
      _selectedStatus = status;
    });
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    if (status == 'All') {
      roomProvider.clearFilters();
    } else {
      roomProvider.filterByStatus(status.toLowerCase());
    }
  }

  void _addNewRoom() {
    // Navigate to add room screen
    context.push('/admin/rooms/add');
  }

  void _editRoom(Room room) {
    // Navigate to add room screen with room parameter
    context.push('/admin/rooms/add', extra: room);
  }

  void _deleteRoom(Room room) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Room'),
            content: Text('Are you sure you want to delete "${room.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final roomProvider = Provider.of<RoomProvider>(
                    context,
                    listen: false,
                  );
                  await roomProvider.deleteRoom(room.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Room deleted successfully')),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Color _getStatusColor(Room room) {
    return room.status == RoomStatus.available
        ? AppColors.success
        : room.status == RoomStatus.underMaintenance
        ? AppColors.warning
        : AppColors.error;
  }

  String _getStatusText(Room room) {
    return room.status == RoomStatus.available
        ? 'Available'
        : room.status == RoomStatus.underMaintenance
        ? 'Maintenance'
        : 'Occupied';
  }

  @override
  Widget build(BuildContext context) {
    final roomProvider = Provider.of<RoomProvider>(context);
    final rooms = roomProvider.filteredRooms;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Rooms'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search rooms...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchRooms('');
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _searchRooms,
            ),
          ),
          // Status filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _statusFilters.length,
              itemBuilder: (context, index) {
                final status = _statusFilters[index];
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (_) => _filterByStatus(status),
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
              },
            ),
          ),
          const Divider(),
          // Room list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : rooms.isEmpty
                    ? const Center(child: Text('No rooms found'))
                    : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        final room = rooms[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(
                                room,
                              ).withOpacity(0.2),
                              child: Icon(
                                Icons.meeting_room,
                                color: _getStatusColor(room),
                              ),
                            ),
                            title: Text(room.name),
                            subtitle: Text(
                              'Capacity: ${room.capacity} • ${room.location ?? "No location"}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      room,
                                    ).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getStatusText(room),
                                    style: TextStyle(
                                      color: _getStatusColor(room),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editRoom(room),
                                  color: AppColors.primary,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteRoom(room),
                                  color: AppColors.error,
                                ),
                              ],
                            ),
                            onTap: () => _editRoom(room),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewRoom,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
