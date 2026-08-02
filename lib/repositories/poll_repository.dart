import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class PollOptionResult {
  const PollOptionResult({
    required this.id,
    required this.time,
    required this.voteCount,
    required this.voters,
  });

  final String id;
  final DateTime time;
  final int voteCount;
  final List<String> voters;
}

class PollWithResults {
  const PollWithResults({
    required this.id,
    required this.title,
    required this.createdBy,
    required this.options,
    this.shareCode,
  });

  final String id;
  final String title;
  final String createdBy;
  final String? shareCode;
  final List<PollOptionResult> options;
}

class PollRepository {
  PollRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Uuid _uuid;

  Future<String> createPoll({
    required String title,
    required List<DateTime> options,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in required to create a poll');
    }
    if (title.trim().isEmpty) {
      throw ArgumentError('Poll title is required');
    }
    if (options.isEmpty) {
      throw ArgumentError('At least one option is required');
    }

    final pollRef = _firestore.collection('polls').doc();
    final shareCode = _uuid.v4().substring(0, 8).toUpperCase();
    final batch = _firestore.batch();

    batch.set(pollRef, {
      'title': title.trim(),
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'open',
      'shareCode': shareCode,
    });

    for (final time in options) {
      final optionRef = pollRef.collection('options').doc();
      batch.set(optionRef, {
        'time': Timestamp.fromDate(time),
        'voteCount': 0,
      });
    }

    await batch.commit();
    return pollRef.id;
  }

  Future<void> castVote({
    required String pollId,
    required String optionId,
    required String voterName,
  }) async {
    final name = voterName.trim();
    if (name.isEmpty) {
      throw ArgumentError('Voter name is required');
    }

    final pollRef = _firestore.collection('polls').doc(pollId);
    final optionRef = pollRef.collection('options').doc(optionId);
    final voteRef = pollRef.collection('votes').doc();

    await _firestore.runTransaction((tx) async {
      final optionSnap = await tx.get(optionRef);
      if (!optionSnap.exists) {
        throw StateError('Poll option not found');
      }
      final current = (optionSnap.data()?['voteCount'] as num?)?.toInt() ?? 0;
      tx.set(voteRef, {
        'optionId': optionId,
        'voterName': name,
        'voterId': _auth.currentUser?.uid,
        'votedAt': FieldValue.serverTimestamp(),
      });
      tx.update(optionRef, {'voteCount': current + 1});
    });
  }

  Stream<PollWithResults> watchPoll(String pollId) {
    final pollRef = _firestore.collection('polls').doc(pollId);

    return pollRef.snapshots().asyncExpand((pollSnap) {
      if (!pollSnap.exists) {
        return Stream.error(StateError('Poll not found'));
      }
      final pollData = pollSnap.data()!;

      final optionsStream = pollRef.collection('options').snapshots();
      final votesStream = pollRef.collection('votes').snapshots();

      return optionsStream.asyncExpand((optionsSnap) {
        return votesStream.map((votesSnap) {
          final votersByOption = <String, List<String>>{};
          for (final vote in votesSnap.docs) {
            final data = vote.data();
            final optionId = data['optionId'] as String? ?? '';
            final voterName = data['voterName'] as String? ?? 'Anonymous';
            votersByOption.putIfAbsent(optionId, () => []).add(voterName);
          }

          final options = optionsSnap.docs.map((doc) {
            final data = doc.data();
            final timeRaw = data['time'];
            final time = timeRaw is Timestamp
                ? timeRaw.toDate()
                : DateTime.tryParse(timeRaw?.toString() ?? '') ??
                    DateTime.now();
            return PollOptionResult(
              id: doc.id,
              time: time,
              voteCount: (data['voteCount'] as num?)?.toInt() ?? 0,
              voters: List<String>.unmodifiable(
                votersByOption[doc.id] ?? const [],
              ),
            );
          }).toList()
            ..sort((a, b) => a.time.compareTo(b.time));

          return PollWithResults(
            id: pollSnap.id,
            title: pollData['title'] as String? ?? 'Poll',
            createdBy: pollData['createdBy'] as String? ?? '',
            shareCode: pollData['shareCode'] as String?,
            options: options,
          );
        });
      });
    });
  }

  Future<String?> getPollIdByShareCode(String code) async {
    final query = await _firestore
        .collection('polls')
        .where('shareCode', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return query.docs.first.id;
  }
}
