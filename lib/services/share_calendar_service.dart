import '../models/event.dart';
import '../repositories/share_calendar_repository.dart';

/// Thin service facade over [ShareCalendarRepository].
class ShareCalendarService {
  ShareCalendarService(this._repository);

  final ShareCalendarRepository _repository;

  Future<String> createShareCode({Duration? ttl}) =>
      _repository.createShareCode(ttl: ttl);

  Future<void> revokeShareCode(String code) =>
      _repository.revokeShareCode(code);

  Stream<List<Event>> watchSharedEvents(String code) =>
      _repository.watchSharedEvents(code);
}
