import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../models/event.dart';
import '../widgets/event_card.dart';
import '../widgets/add_event_sheet_demo.dart';

class MonthViewScreen extends StatefulWidget {
  final List<Event>? events;
  final Function(Event)? onAddEvent;
  final Function(DateTime)? onSelectDate;
  final Map<String, Color>? categoryColors;

  const MonthViewScreen({
    super.key,
    this.events,
    this.onAddEvent,
    this.onSelectDate,
    this.categoryColors,
  });

  @override
  State<MonthViewScreen> createState() => _MonthViewScreenState();
}

class _MonthViewScreenState extends State<MonthViewScreen> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _selectedDate = DateTime.now();
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  int _getDaysInMonth(DateTime date) => DateTime(date.year, date.month + 1, 0).day;
  int _getFirstDayOfWeek(DateTime date) => DateTime(date.year, date.month, 1).weekday % 7;

  List<Event> _getEventsForDay(List<Event> events, DateTime day) => events.where((e) => _isSameDay(e.dateTime, day)).toList();

  void _goToToday() {
    setState(() {
      _currentMonth = DateTime.now();
      _selectedDate = DateTime.now();
    });
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final eventProvider = context.watch<EventProvider>();
    final events = widget.events ?? eventProvider.events;
    final daysInMonth = _getDaysInMonth(_currentMonth);
    final firstDayOffset = _getFirstDayOfWeek(_currentMonth);
    final selectedDayEvents = _selectedDate != null ? _getEventsForDay(events, _selectedDate!) : <Event>[];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF5F6368)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Month View',
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF202124), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.today, color: const Color(0xFF1A73E8)),
            onPressed: _goToToday,
          ),
          IconButton(
            icon: Icon(Icons.chevron_left, color: isDark ? Colors.white70 : const Color(0xFF5F6368)),
            onPressed: _previousMonth,
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: isDark ? Colors.white70 : const Color(0xFF5F6368)),
            onPressed: _nextMonth,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              DateFormat('MMMM yyyy').format(_currentMonth),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF202124)),
            ),
          ),
          _buildWeekdayHeader(isDark),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.7,
              ),
              itemCount: 42,
              itemBuilder: (context, index) {
                final dayNumber = index - firstDayOffset + 1;
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const SizedBox();
                }
                final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
                final isToday = _isSameDay(date, DateTime.now());
                final isSelected = _selectedDate != null && _isSameDay(date, _selectedDate!);
                final hasEvents = _getEventsForDay(events, date).isNotEmpty;
                final eventCount = _getEventsForDay(events, date).length;

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? (isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8))
                          : isToday 
                              ? (isDark ? const Color(0xFF8AB4F8).withOpacity(0.2) : const Color(0xFFE8F0FE))
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isToday && !isSelected 
                          ? Border.all(color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8), width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected 
                                ? (isDark ? Colors.black : Colors.white)
                                : isToday 
                                    ? (isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8))
                                    : (isDark ? Colors.white : const Color(0xFF202124)),
                          ),
                        ),
                        if (hasEvents) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? (isDark ? Colors.black54 : Colors.white70)
                                  : (isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8)),
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (eventCount > 1)
                            Text(
                              '+$eventCount',
                              style: TextStyle(fontSize: 8, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                            ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_selectedDate != null && selectedDayEvents.isNotEmpty)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            DateFormat('EEEE, MMM d').format(_selectedDate!),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF202124)),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text('${selectedDayEvents.length} event${selectedDayEvents.length > 1 ? 's' : ''}',
                              style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: selectedDayEvents.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: EventCard(event: selectedDayEvents[index], onDelete: () {}, isDark: isDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AddEventSheetDemo(onEventAdded: widget.onAddEvent, categoryColors: widget.categoryColors),
        ),
        backgroundColor: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildWeekdayHeader(bool isDark) {
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: weekdays.map((day) => Expanded(
          child: Center(
            child: Text(day, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey[400] : Colors.grey[600])),
          ),
        )).toList(),
      ),
    );
  }
}
