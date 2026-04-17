import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';
import '../models/event.dart';

class EventProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<Event> _events = [];
  bool _isLoading = false;
  String? _error;

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<Event>> get todayEventsStream =>
      _firebaseService.getTodayEvents();

  void updateEvents(List<Event> events) {
    _events = events;
    notifyListeners();
  }

  List<Event> getEventsForDay(DateTime day) {
    return _events.where((event) {
      return event.dateTime.year == day.year &&
          event.dateTime.month == day.month &&
          event.dateTime.day == day.day;
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<void> addEvent(Event event) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firebaseService.addEvent(event);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _firebaseService.deleteEvent(eventId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Event? parseVoiceEvent(String voiceText, String userId) {
    final patterns = [
      RegExp(r'add\s+(.+?)\s+at\s+(\d{1,2})\s*(?:am|pm)?', caseSensitive: false),
      RegExp(r'add\s+(.+?)\s+at\s+(\d{1,2}):(\d{2})\s*(?:am|pm)?', caseSensitive: false),
      RegExp(r'schedule\s+(.+?)\s+at\s+(\d{1,2})\s*(?:am|pm)?', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(voiceText);
      if (match != null) {
        final title = match.group(1)?.trim() ?? '';
        int hour = int.parse(match.group(2)!);
        int minute = match.groupCount >= 3 ? int.parse(match.group(3)!) : 0;

        final isPM = voiceText.toLowerCase().contains('pm');
        if (isPM && hour < 12) hour += 12;
        if (!isPM && hour == 12) hour = 0;

        final now = DateTime.now();
        final eventDateTime = DateTime(now.year, now.month, now.day, hour, minute);

        return Event(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          dateTime: eventDateTime,
          userId: userId,
        );
      }
    }
    return null;
  }

  String formatEventsForSpeech(List<Event> events) {
    if (events.isEmpty) {
      return "You have nothing scheduled for today.";
    }

    final buffer = StringBuffer("Hi! You have ${events.length} ${events.length == 1 ? 'event' : 'events'} today. ");

    for (int i = 0; i < events.length; i++) {
      final event = events[i];
      final timeStr = formatTime(event.dateTime);
      buffer.write("${event.title} at $timeStr");
      if (i < events.length - 1) {
        buffer.write(", ");
      }
    }

    return buffer.toString();
  }

  String formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
