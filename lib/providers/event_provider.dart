import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/event.dart';

class EventProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Event> _events = [];
  bool _isLoading = false;
  String? _error;

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  EventProvider() {
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    _isLoading = true;
    notifyListeners();

    try {
      _events = await _databaseService.getAllEvents();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshEvents() async {
    await _loadEvents();
  }

  List<Event> getEventsForDay(DateTime day) {
    return _events.where((event) {
      return event.dateTime.year == day.year &&
          event.dateTime.month == day.month &&
          event.dateTime.day == day.day;
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<Event> getUpcomingEvents() {
    final now = DateTime.now();
    return _events.where((e) => e.dateTime.isAfter(now)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<void> addEvent(Event event) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _databaseService.insertEvent(event);
      _events.add(event);
      _events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateEvent(Event event) async {
    try {
      await _databaseService.updateEvent(event);
      final index = _events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _events[index] = event;
        _events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _databaseService.deleteEvent(eventId);
      _events.removeWhere((e) => e.id == eventId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleEventCompletion(String eventId) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      final event = _events[index];
      final updatedEvent = event.copyWith(isCompleted: !event.isCompleted);
      await updateEvent(updatedEvent);
    }
  }

  int getUpcomingCount({int hours = 24}) {
    final now = DateTime.now();
    final cutoff = now.add(Duration(hours: hours));
    return _events.where((e) => 
      e.dateTime.isAfter(now) && e.dateTime.isBefore(cutoff)
    ).length;
  }

  Map<String, int> getCategoryStats({int days = 7}) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: now.weekday - 1));
    final endDate = startDate.add(Duration(days: days));
    
    final weekEvents = _events.where((e) => 
      e.dateTime.isAfter(startDate) && e.dateTime.isBefore(endDate)
    ).toList();

    final stats = <String, int>{};
    for (final event in weekEvents) {
      final category = event.category ?? 'Other';
      stats[category] = (stats[category] ?? 0) + 1;
    }
    return stats;
  }

  String formatEventsForSpeech(List<Event> events) {
    if (events.isEmpty) return 'No events scheduled';
    final buffer = StringBuffer('You have ${events.length} event${events.length > 1 ? 's' : ''}');
    for (final event in events) {
      final time = DateFormat('h:mm a').format(event.dateTime);
      buffer.write('. ${event.title} at $time');
    }
    return buffer.toString();
  }

  Event? parseVoiceEvent(String text, String userId) {
    final timePattern = RegExp(r'at\s+(\d{1,2})\s*(am|pm)?', caseSensitive: false);
    final match = timePattern.firstMatch(text);
    if (match == null) return null;
    
    final hour = int.tryParse(match.group(1) ?? '') ?? 0;
    final isPm = match.group(2)?.toLowerCase() == 'pm';
    final hour24 = isPm && hour != 12 ? hour + 12 : (!isPm && hour == 12 ? 0 : hour);
    
    final title = text.replaceAll(timePattern, '').replaceAll(RegExp(r'\b(add|schedule)\b', caseSensitive: false), '').trim();
    if (title.isEmpty) return null;
    
    return Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      dateTime: DateTime.now().copyWith(hour: hour24, minute: 0),
      userId: userId,
    );
  }

  String formatTime(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }
}