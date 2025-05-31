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
  List<String> _statusFilters = [
    'All',
    'Available',
    'Occupied',
    'Under Maintenance',
  ];
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

    try {
      final roomProvider = Provider.of<RoomProvider>(context, listen: false);
      await roomProvider.fetchRooms();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load rooms: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
    roomProvider.filterByStatus(status);
  }

  void _addNewRoom() {
    context.push('/admin/rooms/add');
  }

  void _editRoom(Room room) {
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
                  _loadRooms();
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

  Color _getStatusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return AppColors.success;
      case RoomStatus.occupied:
        return AppColors.error;
      case RoomStatus.underMaintenance:
        return AppColors.warning;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return 'Available';
      case RoomStatus.occupied:
        return 'Occupied';
      case RoomStatus.underMaintenance:
        return 'Maintenance';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomProvider = Provider.of<RoomProvider>(context);
    final rooms = roomProvider.filteredRooms;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: const Text(
          'Manage Rooms',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _isLoading ? null : () => context.pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey[50]!],
          ),
        ),
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search rooms...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.primary,
                  ),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.primary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _searchRooms('');
                            },
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15.0,
                    horizontal: 20.0,
                  ),
                ),
                onChanged: _searchRooms,
                style: TextStyle(color: AppColors.textPrimary),
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
                      onSelected: (selected) => _filterByStatus(status),
                      backgroundColor: Colors.grey[200],
                      selectedColor: AppColors.primary,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color:
                            isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide.none,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Room list
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : rooms.isEmpty
                      ? const Center(child: Text('No rooms found'))
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        itemCount: rooms.length,
                        itemBuilder: (context, index) {
                          final room = rooms[index];
                          return _buildRoomListItem(room);
                        },
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _addNewRoom,
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.add, color: Colors.white),
        elevation: 4.0,
      ),
    );
  }

  Widget _buildRoomListItem(Room room) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Room Icon/Indicator
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getStatusColor(room.status).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.meeting_room,
              size: 30,
              color: _getStatusColor(room.status),
            ),
          ),
          const SizedBox(width: 16),
          // Room Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Capacity: ${room.capacity}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (room.location != null && room.location!.isNotEmpty)
                  Text(
                    'Location: ${room.location}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(room.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(room.status),
                    style: TextStyle(
                      color: _getStatusColor(room.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Action Buttons
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primary),
                onPressed: _isLoading ? null : () => _editRoom(room),
                tooltip: 'Edit Room',
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error),
                onPressed: _isLoading ? null : () => _deleteRoom(room),
                tooltip: 'Delete Room',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
