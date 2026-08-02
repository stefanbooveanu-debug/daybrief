import '../repositories/poll_repository.dart';

class PollService {
  PollService(this._repository);

  final PollRepository _repository;

  Future<String> createPoll({
    required String title,
    required List<DateTime> options,
  }) =>
      _repository.createPoll(title: title, options: options);

  Future<void> castVote({
    required String pollId,
    required String optionId,
    required String voterName,
  }) =>
      _repository.castVote(
        pollId: pollId,
        optionId: optionId,
        voterName: voterName,
      );

  Stream<PollWithResults> watchPoll(String pollId) =>
      _repository.watchPoll(pollId);

  Future<String?> getPollByShareCode(String code) =>
      _repository.getPollIdByShareCode(code);
}
