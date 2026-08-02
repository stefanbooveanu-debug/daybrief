import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';
import '../repositories/auth_repository.dart';
import '../repositories/event_repository.dart';
import '../utils/async_value.dart';
import '../utils/logger.dart';

class EventProvider with ChangeNotifier {
  EventProvider({
    required AuthRepository authRepository,
    required EventRepository eventRepository,
  })  : _authRepository = authRepository,
        _eventRepository = eventRepository {
    unawaited(_bootstrap());
  }

  final AuthRepository _authRepository;
  final EventRepository _eventRepository;

  List<Event> _events = [];
  AsyncValue<List<Event>> _state = const AsyncLoading();
  StreamSubscription<List<Event>>? _firestoreSubscription;
  String? _activeUserId;
  bool _activeDemoMode = false;

  List<Event> get events => List.unmodifiable(_events);
  AsyncValue<List<Event>> get state => _state;
  bool get isLoading => _state is AsyncLoading<List<Event>>;
  String? get error => switch (_state) {
        AsyncError(:final error) => error.toString(),
        _ => null,
      };

  Future<void> _bootstrap() async {
    await syncWithAuth(
      userId: _resolveUserId(),
      isAuthenticated: _authRepository.currentUser != null,
      isDemoMode: false,
    );
  }

  String? _resolveUserId() => _authRepository.currentUser?.uid;

  Future<void> syncWithAuth({
    required String? userId,
    required bool isAuthenticated,
    required bool isDemoMode,
  }) async {
    if (userId == _activeUserId &&
        isDemoMode == _activeDemoMode &&
        _firestoreSubscription != null &&
        userId != null) {
      return;
    }

    _activeUserId = userId;
    _activeDemoMode = isDemoMode;

    await _firestoreSubscription?.cancel();
    _firestoreSubscription = null;

    final scopedUserId = isDemoMode ? 'demo_user' : userId;
    await _eventRepository.setActiveUser(scopedUserId);

    if (userId != null && !isDemoMode) {
      _listenToFirestoreEvents(userId);
      return;
    }

    _events = [];
    notifyListeners();
    await _loadLocalEvents();
  }

  Future<void> _loadLocalEvents() async {
    _state = const AsyncLoading();
    notifyListeners();

    try {
      _events = await _eventRepository.getLocalEvents();
      _state = AsyncData(List.unmodifiable(_events));
    } catch (e, st) {
      _state = AsyncError<List<Event>>(e, st);
    }

    notifyListeners();
  }

  void _listenToFirestoreEvents(String userId) {
    _state = const AsyncLoading();
    notifyListeners();

    _firestoreSubscription =
        _eventRepository.watchFirestoreEvents(userId).listen(
      (events) {
        _events = events;
        _state = AsyncData(List.unmodifiable(_events));
        notifyListeners();
      },
      onError: (Object error, StackTrace st) {
        DayBriefLog.error('Firestore listen error', error: error, st: st);
        _state = AsyncError<List<Event>>(error, st);
        notifyListeners();
      },
    );
  }

  Future<void> refreshEvents() async {
    if (_activeUserId != null && !_activeDemoMode) {
      return;
    }
    await _loadLocalEvents();
  }

  String? get _persistUserId {
    if (_activeDemoMode) return 'demo_user';
    return _activeUserId;
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
    try {
      final userId = _persistUserId;
      if (userId != null && !_activeDemoMode) {
        await _eventRepository.addEvent(event, userId: userId);
        return;
      }

      await _eventRepository.addEvent(event, userId: null);
      _events = [..._events, event]
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      _state = AsyncData(List.unmodifiable(_events));
      notifyListeners();
    } catch (e, st) {
      _state = AsyncError<List<Event>>(e, st);
      DayBriefLog.error('Add event error', error: e, st: st);
      notifyListeners();
    }
  }

  Future<void> updateEvent(Event event) async {
    try {
      final userId = _persistUserId;
      if (userId != null && !_activeDemoMode) {
        await _eventRepository.updateEvent(event, userId: userId);
        return;
      }

      await _eventRepository.updateEvent(event, userId: null);
      final idx = _events.indexWhere((e) => e.id == event.id);
      if (idx >= 0) {
        _events = [..._events]..[idx] = event;
        _state = AsyncData(List.unmodifiable(_events));
        notifyListeners();
      }
    } catch (e, st) {
      _state = AsyncError<List<Event>>(e, st);
      notifyListeners();
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      final userId = _persistUserId;
      if (userId != null && !_activeDemoMode) {
        await _eventRepository.deleteEvent(eventId, userId: userId);
        return;
      }

      await _eventRepository.deleteEvent(eventId, userId: null);
      _events = _events.where((e) => e.id != eventId).toList();
      _state = AsyncData(List.unmodifiable(_events));
      notifyListeners();
    } catch (e, st) {
      _state = AsyncError<List<Event>>(e, st);
      notifyListeners();
    }
  }

  Map<EventCategory, int> getCategoryStats({int days = 7}) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: now.weekday - 1));
    final endDate = startDate.add(Duration(days: days));

    final weekEvents = _events
        .where((e) =>
            e.dateTime.isAfter(startDate) && e.dateTime.isBefore(endDate))
        .toList();

    final stats = <EventCategory, int>{};
    for (final event in weekEvents) {
      final category = event.category ?? EventCategory.other;
      stats[category] = (stats[category] ?? 0) + 1;
    }
    return stats;
  }

  String formatTime(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    super.dispose();
  }
}
