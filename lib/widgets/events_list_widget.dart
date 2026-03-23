import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';

class EventsListWidget extends StatelessWidget {
  final List<Event> events;
  final Map<String, Color> categoryColors;
  final bool isDark;
  final VoidCallback onNavigateToWeekView;
  final VoidCallback onNavigateToMonthView;
  final Function(Event) onEventTap;
  final Function(String) onDelete;
  final Function(Event) onDuplicate;
  final Function(String) onComplete;

  const EventsListWidget({
    super.key,
    required this.events,
    required this.categoryColors,
    required this.isDark,
    required this.onNavigateToWeekView,
    required this.onNavigateToMonthView,
    required this.onEventTap,
    required this.onDelete,
    required this.onDuplicate,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 180),
      itemCount: events.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeader();
        }
        
        final event = events[index - 1];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Transform.translate(
            offset: Offset(50 * (1 - value), 0),
            child: Opacity(opacity: value, child: child),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _EventCardWrapper(
              event: event,
              isDark: isDark,
              categoryColors: categoryColors,
              onTap: () => onEventTap(event),
              onDelete: () => onDelete(event.id),
              onDuplicate: () => onDuplicate(event),
              onComplete: () => onComplete(event.id),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) => Transform.scale(scale: value, child: child),
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.event_available_rounded, 
                size: 60, 
                color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8)
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No events scheduled', 
            style: TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.bold, 
              color: isDark ? Colors.white : const Color(0xFF202124)
            )
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to add one', 
            style: TextStyle(
              fontSize: 15, 
              color: isDark ? Colors.grey[400] : Colors.grey[600]
            )
          ),
          const SizedBox(height: 140),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8), 
              borderRadius: BorderRadius.circular(20)
            ),
            child: Text(
              '${events.length} event${events.length > 1 ? 's' : ''}',
              style: TextStyle(
                color: isDark ? Colors.black : Colors.white, 
                fontWeight: FontWeight.bold, 
                fontSize: 13
              )
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onNavigateToWeekView,
            icon: Icon(Icons.calendar_view_week, color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8)),
            label: Text('Week View', style: TextStyle(color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8))),
          ),
          TextButton.icon(
            onPressed: onNavigateToMonthView,
            icon: Icon(Icons.calendar_month, color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8)),
            label: Text('Month', style: TextStyle(color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8))),
          ),
        ],
      ),
    );
  }
}

class _EventCardWrapper extends StatelessWidget {
  final Event event;
  final bool isDark;
  final Map<String, Color> categoryColors;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onComplete;

  const _EventCardWrapper({
    required this.event,
    required this.isDark,
    required this.categoryColors,
    required this.onTap,
    required this.onDelete,
    required this.onDuplicate,
    required this.onComplete,
  });

  static final DateFormat _timeFormat = DateFormat('h:mm a');

  Color _getEventColor() {
    return categoryColors[event.category] ?? const Color(0xFF5F6368);
  }

  IconData _getEventIcon() {
    switch (event.category) {
      case 'Work': return Icons.work_outline;
      case 'Personal': return Icons.person_outline;
      case 'Health': return Icons.favorite_outline;
      case 'Social': return Icons.people_outline;
      case 'Shopping': return Icons.shopping_cart_outlined;
      default: return Icons.event;
    }
  }

  bool _isUpcoming() {
    final now = DateTime.now();
    final diff = event.dateTime.difference(now);
    return diff.inMinutes > 0 && diff.inHours <= 1;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getEventColor();
    final isUpcoming = _isUpcoming();

    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: event.isCompleted 
                ? null 
                : Border.all(color: color.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getEventIcon(), color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF202124),
                              decoration: event.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        if (isUpcoming)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'SOON',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time, 
                          size: 14, 
                          color: isDark ? Colors.grey[400] : Colors.grey[600]
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _timeFormat.format(event.dateTime),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        if (event.description != null && event.description!.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.notes, 
                            size: 14, 
                            color: isDark ? Colors.grey[400] : Colors.grey[600]
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                onSelected: (value) {
                  switch (value) {
                    case 'complete': onComplete(); break;
                    case 'duplicate': onDuplicate(); break;
                    case 'delete': onDelete(); break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'complete',
                    child: Row(
                      children: [
                        Icon(
                          event.isCompleted ? Icons.undo : Icons.check,
                          size: 20,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(event.isCompleted ? 'Mark Incomplete' : 'Mark Complete'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy, size: 20, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Duplicate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
