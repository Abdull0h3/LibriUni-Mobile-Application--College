import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../providers/room_provider.dart';
import '../../models/room.dart';

class AddRoomScreen extends StatefulWidget {
  final Room? room; // Pass room for editing, null for adding
  const AddRoomScreen({Key? key, this.room}) : super(key: key);

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  RoomStatus _selectedStatus = RoomStatus.available;
  bool _isLoading = false;

  // Room from route extra
  Room? _room;
  bool _didInitialize = false;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    _populateFormIfEditing();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitialize) {
      final Object? extra = GoRouterState.of(context).extra;
      if (extra != null && extra is Room && _room == null) {
        _room = extra;
        _populateFormIfEditing();
      }
      _didInitialize = true;
    }
  }

  void _populateFormIfEditing() {
    if (_room != null) {
      _nameController.text = _room!.name;
      _capacityController.text = _room!.capacity.toString();
      _locationController.text = _room!.location ?? '';
      _descriptionController.text = _room!.description ?? '';
      _selectedStatus = _room!.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveRoom() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final roomProvider = Provider.of<RoomProvider>(context, listen: false);

      final room = Room(
        id: _room?.id ?? '', // Empty for new rooms, will be set by Firestore
        name: _nameController.text.trim(),
        capacity: int.parse(_capacityController.text.trim()),
        status: _selectedStatus,
        location:
            _locationController.text.trim().isEmpty
                ? null
                : _locationController.text.trim(),
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
      );

      bool success;
      if (_room == null) {
        // Add new room
        success = await roomProvider.addRoom(room);
      } else {
        // Update existing room
        success = await roomProvider.updateRoom(room);
      }

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_room == null ? 'Room added' : 'Room updated'} successfully',
            ),
          ),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              roomProvider.error ??
                  'Failed to ${_room == null ? 'add' : 'update'} room',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_room == null ? 'Add New Room' : 'Edit Room'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Room name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Room Name',
                  hintText: 'Enter room name (e.g. "Study Room 101")',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a room name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Capacity
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Capacity',
                  hintText: 'Enter maximum number of people',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter capacity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (int.parse(value) <= 0) {
                    return 'Capacity must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (Optional)',
                  hintText: 'Enter room location (e.g. "2nd Floor, East Wing")',
                ),
              ),
              const SizedBox(height: 16),
              // Status selection
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Room Status',
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<RoomStatus>(
                    value: _selectedStatus,
                    isExpanded: true,
                    onChanged: (RoomStatus? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedStatus = newValue;
                        });
                      }
                    },
                    items:
                        RoomStatus.values.map((RoomStatus status) {
                          return DropdownMenuItem<RoomStatus>(
                            value: status,
                            child: Text(_getRoomStatusLabel(status)),
                          );
                        }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Enter room description, features, or equipment',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              // Submit button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveRoom,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                          _room == null ? 'Add Room' : 'Update Room',
                          style: const TextStyle(fontSize: 16),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoomStatusLabel(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return 'Available';
      case RoomStatus.occupied:
        return 'Occupied';
      case RoomStatus.underMaintenance:
        return 'Under Maintenance';
      default:
        return 'Unknown';
    }
  }
}
