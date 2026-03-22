import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../widgets/event_card.dart';
import '../widgets/add_event_sheet_demo.dart';

class WeekViewScreenDemo extends StatefulWidget {
  final List<Event> events;
  final Function(Event) onAddEvent;
  final Function(String) onDeleteEvent;

  const WeekViewScreenDemo({
    super.key,
    required this.events,
    required this.onAddEvent,
    required this.onDeleteEvent,
  });

  @override
  State<WeekViewScreenDemo> createState() => _WeekViewScreenDemoState();
}

class _WeekViewScreenDemoState extends State<WeekViewScreenDemo> {
  late DateTime _startOfWeek;
  int _selectedDayIndex = DateTime.now().weekday - 1;

  @override
  void initState() {
    super.initState();
    _startOfWeek = _getStartOfWeek(DateTime.now());
  }

  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  List<DateTime> _getWeekDays() {
    return List.generate(7, (index) => _startOfWeek.add(Duration(days: index)));
  }

  void _previousWeek() {
    setState(() {
      _startOfWeek = _startOfWeek.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _startOfWeek = _startOfWeek.add(const Duration(days: 7));
    });
  }

  void _goToToday() {
    setState(() {
      _startOfWeek = _getStartOfWeek(DateTime.now());
      _selectedDayIndex = DateTime.now().weekday - 1;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showAddEventForDate(DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEventSheetDemo(
        onEventAdded: widget.onAddEvent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = _getWeekDays();
    final today = DateTime.now();
    final selectedDate = weekDays[_selectedDayIndex];
    final dayEvents = widget.events
        .where((e) => _isSameDay(e.dateTime, selectedDate))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildHeader(weekDays, today),
          _buildWeekStrip(weekDays, today),
          Expanded(
            child: _buildDayEvents(selectedDate, dayEvents),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventForDate(selectedDate),
        backgroundColor: const Color(0xFF1A73E8),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(List<DateTime> weekDays, DateTime today) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF5F6368)),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              const Text(
                'Week View',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF202124),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.today, color: Color(0xFF1A73E8)),
                onPressed: _goToToday,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Color(0xFF5F6368)),
                onPressed: _previousWeek,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Color(0xFF5F6368)),
                onPressed: _nextWeek,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${DateFormat('MMM d').format(_startOfWeek)} - ${DateFormat('MMM d, yyyy').format(weekDays.last)}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekStrip(List<DateTime> weekDays, DateTime today) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      color: Colors.white,
      child: Row(
        children: List.generate(7, (index) {
          final day = weekDays[index];
          final isSelected = _selectedDayIndex == index;
          final isToday = _isSameDay(day, today);
          final dayEvents = widget.events.where((e) => _isSameDay(e.dateTime, day)).length;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDayIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF1A73E8) 
                      : isToday 
                          ? const Color(0xFFE8F0FE) 
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('E').format(day).substring(0, 1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected 
                            ? Colors.white70 
                            : const Color(0xFF5F6368),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isSelected 
                            ? Colors.white 
                            : const Color(0xFF202124),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: dayEvents > 0
                            ? (isSelected ? Colors.white : const Color(0xFF1A73E8))
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayEvents(DateTime date, List<Event> dayEvents) {
    final isToday = _isSameDay(date, DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isToday ? const Color(0xFF1A73E8) : const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isToday 
                      ? 'Today' 
                      : DateFormat('EEEE, MMMM d').format(date),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isToday ? Colors.white : const Color(0xFF5F6368),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (dayEvents.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${dayEvents.length} event${dayEvents.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A73E8),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: dayEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No events',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add an event',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  itemCount: dayEvents.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: EventCard(
                        event: dayEvents[index],
                        onDelete: () => widget.onDeleteEvent(dayEvents[index].id),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
