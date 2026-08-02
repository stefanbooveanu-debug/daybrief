import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/event.dart';

/// SharedPreferences-backed local event store, scoped per user.
class LocalEventStore {
  static final LocalEventStore _instance = LocalEventStore._internal();

  static const _legacyKey = 'daybrief_events';

  factory LocalEventStore() => _instance;
  LocalEventStore._internal();

  String? _activeUserId;
  List<Event> _events = [];
  bool _loaded = false;

  String get _storageKey {
    final userId = _activeUserId;
    if (userId == null || userId.isEmpty) {
      return 'daybrief_events_anonymous';
    }
    return 'daybrief_events_$userId';
  }

  /// Switch the active user bucket. Reloads cache on change.
  Future<void> setActiveUser(String? userId) async {
    if (_activeUserId == userId && _loaded) return;
    _activeUserId = userId;
    _loaded = false;
    _events = [];
    await _ensureLoaded();
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await _migrateLegacyIfNeeded(prefs);

      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
        _events = list
            .map((m) => Event.fromMap(Map<String, dynamic>.from(m as Map)))
            .toList();
      } else {
        _events = [];
      }
    } catch (e) {
      debugPrint('Error loading events: $e');
      _events = [];
    }
    _loaded = true;
  }

  Future<void> _migrateLegacyIfNeeded(SharedPreferences prefs) async {
    final legacy = prefs.getString(_legacyKey);
    if (legacy == null || legacy.isEmpty) return;

    final current = prefs.getString(_storageKey);
    if (current == null || current.isEmpty) {
      await prefs.setString(_storageKey, legacy);
    }
    await prefs.remove(_legacyKey);
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_events.map((e) => e.toMap()).toList());
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      debugPrint('Error saving events: $e');
    }
  }

  Future<int> insertEvent(Event event) async {
    await _ensureLoaded();
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
    return _events
        .where((e) =>
            e.dateTime.year == day.year &&
            e.dateTime.month == day.month &&
            e.dateTime.day == day.day)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
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
