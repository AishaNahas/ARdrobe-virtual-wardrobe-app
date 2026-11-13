import 'package:flutter/material.dart';
import '../models/wardrobe_item.dart';
import '../models/calendar_event.dart';
import '../services/wardrobe_service.dart';
import '../services/calendar_service.dart';

class AddEventScreen extends StatefulWidget {
  final String email;
  final DateTime selectedDate;
  final CalendarEvent? event;

  const AddEventScreen({
    super.key,
    required this.email,
    required this.selectedDate,
    this.event,
  });

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final WardrobeService _wardrobeService = WardrobeService();
  final CalendarService _calendarService = CalendarService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  List<WardrobeItem> _allItems = [];
  List<WardrobeItem> _selectedItems = [];
  String? _selectedType;
  final _titleController = TextEditingController();

  final List<String> _eventTypes = ['Casual', 'Formal', 'Party', 'Sports'];

  @override
  void initState() {
    super.initState();
    _loadWardrobeItems();
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _selectedType = widget.event!.type;
      _selectedItems = List.from(widget.event!.items);
    }
  }

  Future<void> _loadWardrobeItems() async {
    try {
      final items = await _wardrobeService.getWardrobeItems(widget.email);
      setState(() {
        _allItems = items;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      setState(() => _isLoading = false);
    }
  }

  void _toggleItemSelection(WardrobeItem item) {
    setState(() {
      if (_selectedItems.any((i) => i.id == item.id)) {
        _selectedItems.removeWhere((i) => i.id == item.id);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      try {
        final event = CalendarEvent(
          id: widget.event?.id ?? DateTime.now().toString(),
          title: _titleController.text,
          type: _selectedType!,
          items: List<WardrobeItem>.from(_selectedItems), // ensure a new list
          date: widget.selectedDate,
        );

        if (widget.event != null) {
          await _calendarService.updateEvent(widget.email, event);
        } else {
          await _calendarService.addEvent(widget.email, event);
        }

        if (mounted) {
          Navigator.pop(context, event);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3E0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.event != null ? 'Edit Event' : 'Add Event',
          style: const TextStyle(color: Color(0xFF4B4B4B)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF4B4B4B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Event Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an event title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Event Type
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        labelText: 'Event Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _eventTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedType = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select an event type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Selected Date
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              color: Color(0xFFA4D3A0)),
                          const SizedBox(width: 12),
                          Text(
                            'Date: ${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF4B4B4B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Currently Selected Outfit
                    if (_selectedItems.isNotEmpty) ...[
                      const Text(
                        'Currently Selected Outfit',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4B4B4B)),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedItems.length,
                          itemBuilder: (context, index) {
                            final item = _selectedItems[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: item.imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(item.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                                    )
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFA4D3A0),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.image, color: Colors.white),
                                    ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Outfit Selection
                    const Text(
                      'Select Outfit Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4B4B4B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _allItems.length,
                      itemBuilder: (context, index) {
                        final item = _allItems[index];
                        final isSelected = _selectedItems.any((i) => i.id == item.id);
                        return GestureDetector(
                          onTap: () => _toggleItemSelection(item),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFA4D3A0)
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    item.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.error_outline,
                                          color: Colors.grey,
                                          size: 40,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFA4D3A0),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.black,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveEvent,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: const Color(0xFFA4D3A0),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'SAVE EVENT',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
