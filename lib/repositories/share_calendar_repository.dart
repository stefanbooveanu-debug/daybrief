import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../models/event.dart';

class ShareCalendarRepository {
  ShareCalendarRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Uuid _uuid;

  Future<String> createShareCode({Duration? ttl}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in required to share a calendar');
    }

    final code = _uuid.v4().replaceAll('-', '').substring(0, 10).toUpperCase();
    final expiresAt =
        ttl == null ? null : Timestamp.fromDate(DateTime.now().add(ttl));

    final batch = _firestore.batch();
    batch.set(_firestore.collection('share_codes').doc(code), {
      'ownerId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': expiresAt,
      'isActive': true,
      'eventFilter': 'upcoming',
    });
    batch.set(
      _firestore.collection('public_calendars').doc(user.uid),
      {
        'isActive': true,
        'code': code,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
    await batch.commit();
    return code;
  }

  Future<void> revokeShareCode(String code) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in required');
    }

    final doc = await _firestore.collection('share_codes').doc(code).get();
    if (!doc.exists || doc.data()?['ownerId'] != user.uid) {
      throw StateError('Share code not found');
    }

    final batch = _firestore.batch();
    batch.update(doc.reference, {'isActive': false});
    batch.set(
      _firestore.collection('public_calendars').doc(user.uid),
      {
        'isActive': false,
        'code': code,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Stream<List<Event>> watchSharedEvents(String code) {
    return _firestore
        .collection('share_codes')
        .doc(code)
        .snapshots()
        .asyncExpand(
      (shareSnap) {
        if (!shareSnap.exists) {
          return Stream.value(const <Event>[]);
        }
        final data = shareSnap.data()!;
        if (data['isActive'] != true) {
          return Stream.value(const <Event>[]);
        }
        final expiresAt = data['expiresAt'];
        if (expiresAt is Timestamp &&
            expiresAt.toDate().isBefore(DateTime.now())) {
          return Stream.value(const <Event>[]);
        }

        final ownerId = data['ownerId'] as String?;
        if (ownerId == null || ownerId.isEmpty) {
          return Stream.value(const <Event>[]);
        }

        return _firestore
            .collection('events')
            .where('userId', isEqualTo: ownerId)
            .snapshots()
            .map((snapshot) {
          final now = DateTime.now();
          final events = snapshot.docs
              .map((doc) {
                final map = Map<String, dynamic>.from(doc.data());
                map['id'] = doc.id;
                return Event.fromMap(map);
              })
              .where((e) =>
                  e.dateTime.isAfter(now.subtract(const Duration(hours: 1))))
              .toList()
            ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
          return events;
        });
      },
    );
  }
}
