import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';
import '../widgets/event_card.dart';
import '../widgets/add_event_sheet.dart';

class WeekViewScreen extends StatefulWidget {
  const WeekViewScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  State<WeekViewScreen> createState() => _WeekViewScreenState();
}

class _WeekViewScreenState extends State<WeekViewScreen> {
  late DateTime _startOfWeek;

  @override
  void initState() {
    super.initState();
    _startOfWeek = _getStartOfWeek(DateTime.now());
  }

  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
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
    });
  }

  List<DateTime> _getWeekDays() {
    return List.generate(7, (index) => _startOfWeek.add(Duration(days: index)));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showAddEventForDate(DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddEventSheet(initialDate: date),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = _getWeekDays();
    final today = DateTime.now();
    final body = _buildBody(context, weekDays, today);

    if (widget.embeddedInShell) {
      return body;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5F6368)),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Week',
              style: TextStyle(
                color: Color(0xFF202124),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              '${DateFormat('MMM d').format(_startOfWeek)} - ${DateFormat('MMM d, yyyy').format(weekDays.last)}',
              style: const TextStyle(
                color: Color(0xFF5F6368),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _goToToday,
            child: const Text('Today'),
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
      body: body,
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<DateTime> weekDays,
    DateTime today,
  ) {
    return Column(
      children: [
        if (widget.embeddedInShell)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${DateFormat('MMM d').format(_startOfWeek)} - ${DateFormat('MMM d, yyyy').format(weekDays.last)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.today, color: Color(0xFF1A73E8)),
                  onPressed: _goToToday,
                  tooltip: 'Go to today',
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousWeek,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextWeek,
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: weekDays.map((day) {
              final isToday = _isSameDay(day, today);
              return Expanded(
                child: InkWell(
                  onTap: () => _showAddEventForDate(day),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isToday
                          ? const Color(0xFFE8F0FE)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('E').format(day).substring(0, 1),
                          style: TextStyle(
                            fontSize: 12,
                            color: isToday
                                ? const Color(0xFF1A73E8)
                                : const Color(0xFF5F6368),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isToday
                                ? const Color(0xFF1A73E8)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isToday
                                    ? Colors.white
                                    : const Color(0xFF202124),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Container(
          height: 1,
          color: Colors.grey[200],
        ),
        Expanded(
          child: Consumer<EventProvider>(
            builder: (context, eventProvider, _) {
              final allEvents = eventProvider.events;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: weekDays.length,
                itemBuilder: (context, index) {
                  final day = weekDays[index];
                  final isToday = _isSameDay(day, today);
                  final dayEvents = allEvents
                      .where((e) => _isSameDay(e.dateTime, day))
                      .toList()
                    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isToday || dayEvents.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? const Color(0xFF1A73E8)
                                      : const Color(0xFFF1F3F4),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  isToday
                                      ? 'Today'
                                      : DateFormat('EEE, MMM d').format(day),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isToday
                                        ? Colors.white
                                        : const Color(0xFF5F6368),
                                  ),
                                ),
                              ),
                              if (dayEvents.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F0FE),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${dayEvents.length} event${dayEvents.length > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF1A73E8),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      if (dayEvents.isEmpty && isToday)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'No events',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else if (dayEvents.isNotEmpty)
                        ...dayEvents.map((event) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: EventCard(
                                event: event,
                                onDelete: () =>
                                    eventProvider.deleteEvent(event.id),
                              ),
                            )),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
