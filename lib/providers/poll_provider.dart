import 'dart:async';

import 'package:flutter/foundation.dart';

import '../repositories/poll_repository.dart';
import '../services/poll_service.dart';
import '../utils/async_value.dart';

class PollProvider with ChangeNotifier {
  PollProvider(this._service);

  final PollService _service;

  StreamSubscription<PollWithResults>? _pollSub;
  AsyncValue<PollWithResults?> _state = const AsyncIdle();
  String? _activePollId;

  AsyncValue<PollWithResults?> get state => _state;
  PollWithResults? get poll => _state.valueOrNull;
  bool get isLoading => _state.isLoading;
  String? get error => _state.errorOrNull?.toString();
  String? get activePollId => _activePollId;

  void watchPoll(String pollId) {
    if (_activePollId == pollId && _pollSub != null) return;

    _activePollId = pollId;
    unawaited(_pollSub?.cancel());
    _state = const AsyncLoading();
    notifyListeners();

    _pollSub = _service.watchPoll(pollId).listen(
      (poll) {
        _state = AsyncData(poll);
        notifyListeners();
      },
      onError: (Object e, StackTrace st) {
        _state = AsyncError(e, st);
        notifyListeners();
      },
    );
  }

  void clear() {
    unawaited(_pollSub?.cancel());
    _pollSub = null;
    _activePollId = null;
    _state = const AsyncIdle();
    notifyListeners();
  }

  Future<String> createPoll({
    required String title,
    required List<DateTime> options,
  }) async {
    final pollId = await _service.createPoll(title: title, options: options);
    watchPoll(pollId);
    return pollId;
  }

  Future<void> castVote({
    required String optionId,
    required String voterName,
  }) async {
    final pollId = _activePollId;
    if (pollId == null) {
      throw StateError('No active poll');
    }
    await _service.castVote(
      pollId: pollId,
      optionId: optionId,
      voterName: voterName,
    );
  }

  @override
  void dispose() {
    unawaited(_pollSub?.cancel());
    super.dispose();
  }
}
