import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static const String _eventsKey = 'daybrief_events';

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // In-memory cache
  List<Event> _events = [];
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_eventsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        _events = list.map((m) => Event.fromMap(Map<String, dynamic>.from(m))).toList();
      }
    } catch (e) {
      debugPrint('Error loading events: $e');
      _events = [];
    }
    _loaded = true;
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_events.map((e) => e.toMap()).toList());
      await prefs.setString(_eventsKey, jsonStr);
    } catch (e) {
      debugPrint('Error saving events: $e');
    }
  }

  Future<int> insertEvent(Event event) async {
    await _ensureLoaded();
    // Remove existing with same ID (replace)
    _events.removeWhere((e) => e.id == event.id);
    _events.add(event);
    await _save();
    return 1;
  }

  Future<List<Event>> getAllEvents() async {
    await _ensureLoaded();
    final sorted = List<Event>.from(_events)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return sorted;
  }

  Future<List<Event>> getEventsForDay(DateTime day) async {
    await _ensureLoaded();
    return _events.where((e) =>
      e.dateTime.year == day.year &&
      e.dateTime.month == day.month &&
      e.dateTime.day == day.day
    ).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<List<Event>> getUpcomingEvents() async {
    await _ensureLoaded();
    final now = DateTime.now();
    return _events.where((e) => e.dateTime.isAfter(now)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<int> updateEvent(Event event) async {
    await _ensureLoaded();
    final idx = _events.indexWhere((e) => e.id == event.id);
    if (idx >= 0) {
      _events[idx] = event;
      await _save();
      return 1;
    }
    return 0;
  }

  Future<int> deleteEvent(String eventId) async {
    await _ensureLoaded();
    final before = _events.length;
    _events.removeWhere((e) => e.id == eventId);
    await _save();
    return before - _events.length;
  }

  Future<int> deleteAllEvents() async {
    await _ensureLoaded();
    final count = _events.length;
    _events.clear();
    await _save();
    return count;
  }

  Future<void> close() async {
    _events.clear();
    _loaded = false;
  }
}
