import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/calendar_event.dart';
import '../services/calendar_service.dart';
import 'add_event_screen.dart';
import '../widgets/bottom_nav_bar.dart';
import 'wardrobe_dashboard.dart';

class CalendarScreen extends StatefulWidget {
  final String email;
  final String? highlightEventId;
  final List<dynamic>? outfitItems;

  const CalendarScreen({
    super.key,
    required this.email,
    this.highlightEventId,
    this.outfitItems,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarService _calendarService = CalendarService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<CalendarEvent>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  void _loadEvents() {
    _calendarService.getEvents(widget.email).listen((events) {
      final groupedEvents = <DateTime, List<CalendarEvent>>{};
      for (final event in events) {
        final date = DateTime(
          event.date.year,
          event.date.month,
          event.date.day,
        );
        if (!groupedEvents.containsKey(date)) {
          groupedEvents[date] = [];
        }
        groupedEvents[date]!.add(event);
      }
      setState(() {
        _events = groupedEvents;
      });
    });
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _onFormatChanged(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
  }

  Color _getEventColor(String type) {
    switch (type.toLowerCase()) {
      case 'formal':
        return const Color(0xFFA4D3A0);
      case 'casual':
        return const Color(0xFFFFE4E1); // Light peach color
      case 'party':
        return const Color(0xFFFFB5A7); // Peach color
      case 'sports':
        return const Color(0xFFFFDAB9); // Peach puff color
      default:
        return const Color(0xFFA4D3A0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3E0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Calendar',
          style: TextStyle(color: Color(0xFF4B4B4B)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4B4B4B)),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => WardrobeDashboard(email: widget.email),
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          TableCalendar<CalendarEvent>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: _onDaySelected,
            onFormatChanged: _onFormatChanged,
            onPageChanged: _onPageChanged,
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(color: Color(0xFF4B4B4B)),
              holidayTextStyle: TextStyle(color: Color(0xFF4B4B4B)),
              selectedDecoration: BoxDecoration(
                color: Color(0xFFFFE4E1), // Light peach color for selected day
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: Color(0xFFFFE4E1), // Light peach color
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              formatButtonTextStyle: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              titleTextStyle: TextStyle(
                color: Color(0xFF4B4B4B),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 12, // Increased from 8
                      height: 12, // Increased from 8
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getEventColor(events.first.type),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 8),
          if (widget.outfitItems != null && widget.outfitItems!.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Outfit for this event:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: widget.outfitItems!.map<Widget>((item) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: item.imageUrl != null && item.imageUrl.isNotEmpty
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
                    }).toList(),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _selectedDay == null
                ? const Center(
                    child: Text(
                      'Select a day to view events',
                      style: TextStyle(
                        color: Color(0xFF4B4B4B),
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _getEventsForDay(_selectedDay!).length,
                    itemBuilder: (context, index) {
                      final event = _getEventsForDay(_selectedDay!)[index];
                      final isHighlighted = widget.highlightEventId == event.id;
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: isHighlighted ? Colors.yellow[100] : Colors.white,
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.all(16),
                          title: Text(
                            event.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4B4B4B),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                event.type,
                                style: TextStyle(
                                  color: _getEventColor(event.type),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (event.items.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '${event.items.length} items selected',
                                  style: const TextStyle(
                                    color: Color(0xFF4B4B4B),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          children: [
                            if (event.items.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Outfit for this event:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 80,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: event.items.length,
                                        itemBuilder: (context, idx) {
                                          final item = event.items[idx];
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 8.0),
                                            child: item.imageUrl != null && item.imageUrl.isNotEmpty
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
                                  ],
                                ),
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () async {
                                    final updatedEvent = await Navigator.push<CalendarEvent>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddEventScreen(
                                          email: widget.email,
                                          selectedDate: event.date,
                                          event: event,
                                        ),
                                      ),
                                    );
                                    if (updatedEvent != null) {
                                      await _calendarService.updateEvent(
                                        widget.email,
                                        updatedEvent,
                                      );
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Event?'),
                                        content: const Text('Are you sure you want to delete this event?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await _calendarService.deleteEvent(widget.email, event.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final event = await Navigator.push<CalendarEvent>(
            context,
            MaterialPageRoute(
              builder: (context) => AddEventScreen(
                email: widget.email,
                selectedDate: _selectedDay ?? DateTime.now(),
              ),
            ),
          );
          if (event != null) {
            await _calendarService.addEvent(widget.email, event);
          }
        },
        backgroundColor: const Color(0xFFFFE4E1), // Light peach color
        child: const Icon(Icons.add, color: Colors.black),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 2,
        email: widget.email,
      ),
    );
  }
}
