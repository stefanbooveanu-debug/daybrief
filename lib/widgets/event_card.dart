import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onDelete;
  final bool isDark;
  final Map<String, Color> categoryColors;

  const EventCard({
    super.key,
    required this.event,
    required this.onDelete,
    this.isDark = false,
    this.categoryColors = const {
      'Work': Color(0xFF1A73E8),
      'Personal': Color(0xFF34A853),
      'Health': Color(0xFFEA4335),
      'Social': Color(0xFF9334E6),
      'Shopping': Color(0xFFFBBC04),
    },
  });

  Color _getEventColor() {
    final cat = event.category?.toLowerCase() ?? '';
    if (cat.contains('work')) return categoryColors['Work'] ?? const Color(0xFF1A73E8);
    if (cat.contains('personal')) return categoryColors['Personal'] ?? const Color(0xFF34A853);
    if (cat.contains('health')) return categoryColors['Health'] ?? const Color(0xFFEA4335);
    if (cat.contains('social')) return categoryColors['Social'] ?? const Color(0xFF9334E6);
    if (cat.contains('shopping')) return categoryColors['Shopping'] ?? const Color(0xFFFBBC04);
    
    final title = event.title.toLowerCase();
    if (title.contains('meeting') || title.contains('call') || title.contains('work') || title.contains('standup') || title.contains('deadline')) {
      return categoryColors['Work'] ?? const Color(0xFF1A73E8);
    } else if (title.contains('gym') || title.contains('workout') || title.contains('run') || title.contains('yoga') || title.contains('sport')) {
      return categoryColors['Health'] ?? const Color(0xFFEA4335);
    } else if (title.contains('doctor') || title.contains('med') || title.contains('health') || title.contains('dentist')) {
      return categoryColors['Health'] ?? const Color(0xFFEA4335);
    } else if (title.contains('birthday') || title.contains('party') || title.contains('social') || title.contains('hangout')) {
      return categoryColors['Social'] ?? const Color(0xFF9334E6);
    } else if (title.contains('shop') || title.contains('grocery') || title.contains('store')) {
      return categoryColors['Shopping'] ?? const Color(0xFFFBBC04);
    } else if (title.contains('coffee') || title.contains('lunch') || title.contains('dinner') || title.contains('food')) {
      return categoryColors['Personal'] ?? const Color(0xFF34A853);
    } else if (title.contains('travel') || title.contains('flight') || title.contains('trip')) {
      return categoryColors['Social'] ?? const Color(0xFF9334E6);
    }
    return categoryColors['Work'] ?? (isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8));
  }

  IconData _getEventIcon() {
    final title = event.title.toLowerCase();
    if (title.contains('meeting') || title.contains('standup') || title.contains('call')) {
      return Icons.videocam_outlined;
    } else if (title.contains('gym') || title.contains('workout') || title.contains('yoga')) {
      return Icons.fitness_center_outlined;
    } else if (title.contains('doctor') || title.contains('med') || title.contains('health')) {
      return Icons.medical_services_outlined;
    } else if (title.contains('lunch') || title.contains('dinner') || title.contains('coffee') || title.contains('food')) {
      return Icons.restaurant_outlined;
    } else if (title.contains('birthday')) {
      return Icons.cake_outlined;
    } else if (title.contains('shop') || title.contains('grocery')) {
      return Icons.shopping_cart_outlined;
    } else if (title.contains('travel') || title.contains('flight')) {
      return Icons.flight_outlined;
    } else if (title.contains('email') || title.contains('message')) {
      return Icons.email_outlined;
    } else if (title.contains('study') || title.contains('class') || title.contains('course')) {
      return Icons.school_outlined;
    }
    return Icons.event_outlined;
  }

  bool _isUpcoming() {
    final now = DateTime.now();
    final diff = event.dateTime.difference(now);
    return diff.inHours >= 0 && diff.inHours <= 2;
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final color = _getEventColor();
    final isUpcoming = _isUpcoming();

    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEventDetails(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isUpcoming
                  ? Border.all(color: color.withOpacity(0.5), width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(isDark ? 0.2 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          _getEventIcon(),
                          color: color,
                          size: 28,
                        ),
                      ),
                      if (isUpcoming)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
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
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF202124),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isUpcoming)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'SOON',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.access_time, size: 12, color: color),
                                const SizedBox(width: 4),
                                Text(
                                  timeFormat.format(event.dateTime),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (event.description != null) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.notes, size: 14, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEventDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _getEventColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _getEventIcon(),
                    color: _getEventColor(),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF202124),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('EEEE, MMMM d, yyyy').format(event.dateTime),
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('h:mm a').format(event.dateTime),
                            style: TextStyle(
                              color: _getEventColor(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (event.description != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes, size: 20, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        event.description!,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF202124),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDelete(context);
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check),
                    label: const Text('Done'),
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text('Delete Event', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF202124))),
        content: Text('Are you sure you want to delete "${event.title}"?', style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
