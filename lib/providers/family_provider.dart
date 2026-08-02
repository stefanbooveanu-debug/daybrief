import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/event.dart';
import '../models/family.dart';
import '../repositories/family_repository.dart';
import '../utils/async_value.dart';

class FamilyProvider with ChangeNotifier {
  FamilyProvider(this._repository);

  final FamilyRepository _repository;

  StreamSubscription<FamilyInfo?>? _familySub;
  StreamSubscription<List<FamilyMember>>? _membersSub;
  StreamSubscription<List<Event>>? _eventsSub;

  AsyncValue<FamilyInfo?> _state = const AsyncIdle();
  FamilyInfo? _family;
  List<FamilyMember> _members = const [];
  List<Event> _events = const [];
  String? _actionError;

  AsyncValue<FamilyInfo?> get state => _state;
  FamilyInfo? get family => _family;
  List<FamilyMember> get members => List.unmodifiable(_members);
  List<Event> get events => List.unmodifiable(_events);
  bool get isLoading => _state is AsyncLoading<FamilyInfo?>;
  String? get error =>
      _actionError ??
      switch (_state) {
        AsyncError(:final error) => error.toString(),
        _ => null,
      };

  void start() {
    _familySub?.cancel();
    _state = const AsyncLoading();
    notifyListeners();

    _familySub = _repository.watchMyFamily().listen(
      (family) {
        _family = family;
        _state = AsyncData(family);
        _actionError = null;
        _bindFamilyStreams(family?.id);
        notifyListeners();
      },
      onError: (Object e, StackTrace st) {
        _state = AsyncError(e, st);
        notifyListeners();
      },
    );
  }

  void stop() {
    unawaited(_familySub?.cancel());
    unawaited(_membersSub?.cancel());
    unawaited(_eventsSub?.cancel());
    _familySub = null;
    _membersSub = null;
    _eventsSub = null;
    _family = null;
    _members = const [];
    _events = const [];
    _state = const AsyncIdle();
    notifyListeners();
  }

  void _bindFamilyStreams(String? familyId) {
    unawaited(_membersSub?.cancel());
    unawaited(_eventsSub?.cancel());
    _membersSub = null;
    _eventsSub = null;

    if (familyId == null) {
      _members = const [];
      _events = const [];
      return;
    }

    _membersSub = _repository.watchMembers(familyId).listen((members) {
      _members = members;
      notifyListeners();
    });
    _eventsSub = _repository.watchFamilyEvents(familyId).listen((events) {
      _events = events;
      notifyListeners();
    });
  }

  Future<void> createFamily(String name) async {
    _actionError = null;
    notifyListeners();
    try {
      await _repository.createFamily(name: name);
    } catch (e) {
      _actionError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> joinFamily(String inviteCode) async {
    _actionError = null;
    notifyListeners();
    try {
      await _repository.joinFamily(inviteCode: inviteCode);
    } catch (e) {
      _actionError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> inviteMember(String email) async {
    final familyId = _family?.id;
    if (familyId == null) {
      throw StateError('No family to invite to');
    }
    _actionError = null;
    notifyListeners();
    try {
      await _repository.inviteMember(familyId: familyId, email: email);
    } catch (e) {
      _actionError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addFamilyEvent(Event event) async {
    final familyId = _family?.id;
    if (familyId == null) {
      throw StateError('No family to add event to');
    }
    await _repository.addFamilyEvent(familyId, event);
  }

  Future<void> removeFamilyEvent(String eventId) async {
    final familyId = _family?.id;
    if (familyId == null) return;
    await _repository.removeFamilyEvent(familyId, eventId);
  }

  FamilyMember? memberFor(String userId) {
    for (final member in _members) {
      if (member.uid == userId) return member;
    }
    return null;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
