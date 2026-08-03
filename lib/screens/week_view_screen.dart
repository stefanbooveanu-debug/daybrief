import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app/app_scope.dart';
import '../providers/event_provider.dart';
import '../widgets/add_event_sheet.dart';
import '../widgets/event_card.dart';

class WeekViewScreen extends StatefulWidget {
  const WeekViewScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  State<WeekViewScreen> createState() => _WeekViewScreenState();
}

class _WeekViewScreenState extends State<WeekViewScreen> {
  late DateTime _startOfWeek;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startOfWeek = _getStartOfWeek(now);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  void _previousWeek() {
    setState(() {
      _startOfWeek = _startOfWeek.subtract(const Duration(days: 7));
      if (_selectedDay != null) {
        _selectedDay = _selectedDay!.subtract(const Duration(days: 7));
      }
    });
  }

  void _nextWeek() {
    setState(() {
      _startOfWeek = _startOfWeek.add(const Duration(days: 7));
      if (_selectedDay != null) {
        _selectedDay = _selectedDay!.add(const Duration(days: 7));
      }
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _startOfWeek = _getStartOfWeek(now);
      _selectedDay = DateTime(now.year, now.month, now.day);
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
      backgroundColor: Colors.transparent,
      builder: (context) => AddEventSheet(initialDate: date),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weekDays = _getWeekDays();
    final today = DateTime.now();
    final body = _buildBody(context, weekDays, today, isDark);

    if (widget.embeddedInShell) {
      return body;
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A0E00) : const Color(0xFFFFF5EC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF2A1A0A) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white70 : const Color(0xFF5F6368),
          ),
          tooltip: 'Back',
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Week',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF202124),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              '${DateFormat('MMM d').format(_startOfWeek)} - ${DateFormat('MMM d, yyyy').format(weekDays.last)}',
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF5F6368),
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
            icon: Icon(
              Icons.chevron_left,
              color: isDark ? Colors.white70 : const Color(0xFF5F6368),
            ),
            tooltip: 'Previous week',
            onPressed: _previousWeek,
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white70 : const Color(0xFF5F6368),
            ),
            tooltip: 'Next week',
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
    bool isDark,
  ) {
    final accent = isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8);
    final muted = isDark ? Colors.white54 : const Color(0xFF5F6368);
    final primaryText = isDark ? Colors.white : const Color(0xFF202124);
    final cardSurface = isDark ? const Color(0xFF2A1A0A) : Colors.white;
    final categoryColors = AppScope.of(context).categoryColors;

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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryText,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.today, color: accent),
                  onPressed: _goToToday,
                  tooltip: 'Go to today',
                ),
                IconButton(
                  icon: Icon(Icons.chevron_left, color: muted),
                  tooltip: 'Previous week',
                  onPressed: _previousWeek,
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: muted),
                  tooltip: 'Next week',
                  onPressed: _nextWeek,
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Row(
            children: weekDays.map((day) {
              final isToday = _isSameDay(day, today);
              final isSelected =
                  _selectedDay != null && _isSameDay(day, _selectedDay!);
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() {
                    _selectedDay = DateTime(day.year, day.month, day.day);
                  }),
                  onLongPress: () => _showAddEventForDate(day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? accent.withValues(alpha: 0.18)
                              : const Color(0xFFE8F0FE))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: isSelected
                          ? Border.all(
                              color: accent.withValues(alpha: 0.45),
                            )
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('E').format(day).substring(0, 1),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected || isToday ? accent : muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isToday
                                ? accent
                                : isSelected
                                    ? accent.withValues(alpha: 0.25)
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
                                    ? (isDark ? Colors.black : Colors.white)
                                    : primaryText,
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
        Divider(
          height: 1,
          color: isDark ? Colors.white12 : Colors.grey[200],
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
                  final isSelected =
                      _selectedDay != null && _isSameDay(day, _selectedDay!);
                  final dayEvents = allEvents
                      .where((e) => _isSameDay(e.dateTime, day))
                      .toList()
                    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

                  final showSection =
                      isToday || isSelected || dayEvents.isNotEmpty;

                  if (!showSection) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isToday
                                    ? accent
                                    : (isDark
                                        ? cardSurface
                                        : const Color(0xFFF1F3F4)),
                                borderRadius: BorderRadius.circular(16),
                                border: !isToday && isDark
                                    ? Border.all(color: Colors.white12)
                                    : null,
                              ),
                              child: Text(
                                isToday
                                    ? 'Today'
                                    : DateFormat('EEE, MMM d').format(day),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isToday
                                      ? (isDark ? Colors.black : Colors.white)
                                      : muted,
                                ),
                              ),
                            ),
                            if (dayEvents.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? accent.withValues(alpha: 0.2)
                                      : const Color(0xFFE8F0FE),
                                  borderRadius: BorderRadius.circular(10),
                                  border: isDark
                                      ? Border.all(
                                          color: accent.withValues(alpha: 0.35),
                                        )
                                      : null,
                                ),
                                child: Text(
                                  '${dayEvents.length} event${dayEvents.length > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (dayEvents.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'No events',
                            style: TextStyle(
                              color: muted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        ...dayEvents.map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: EventCard(
                              event: event,
                              isDark: isDark,
                              categoryColors: categoryColors,
                              onDelete: () =>
                                  eventProvider.deleteEvent(event.id),
                            ),
                          ),
                        ),
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
