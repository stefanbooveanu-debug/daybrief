import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../models/event.dart';
import '../models/family.dart';

class FamilyRepository {
  FamilyRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Uuid _uuid;

  static const _avatars = ['👩', '👨', '👧', '👦', '🧑', '👵', '👴'];
  static const _colors = [
    0xFFE91E63,
    0xFF2196F3,
    0xFF9C27B0,
    0xFF4CAF50,
    0xFFFF9800,
    0xFF00BCD4,
    0xFF795548,
  ];

  User get _requireUser {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in required for family calendar');
    }
    return user;
  }

  Stream<FamilyInfo?> watchMyFamily() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('families')
        .where('memberIds', arrayContains: user.uid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return FamilyInfo.fromMap(doc.id, doc.data());
    });
  }

  Stream<List<FamilyMember>> watchMembers(String familyId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('members')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FamilyMember.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Event>> watchFamilyEvents(String familyId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('events')
        .snapshots()
        .map((snapshot) {
      final events = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        data['userId'] = data['createdBy'] ?? data['userId'] ?? '';
        return Event.fromMap(data);
      }).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return events;
    });
  }

  Future<String> createFamily({required String name}) async {
    final user = _requireUser;
    final familyRef = _firestore.collection('families').doc();
    final inviteCode = _uuid.v4().substring(0, 8).toUpperCase();
    final member = _memberForUser(user, role: 'owner');

    final batch = _firestore.batch();
    batch.set(familyRef, {
      'name': name.trim(),
      'ownerId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'inviteCode': inviteCode,
      'memberIds': [user.uid],
    });
    batch.set(
      familyRef.collection('members').doc(user.uid),
      {
        ...member.toMap(),
        'joinedAt': FieldValue.serverTimestamp(),
      },
    );
    batch.set(
      _firestore.collection('users').doc(user.uid),
      {'familyId': familyRef.id},
      SetOptions(merge: true),
    );
    await batch.commit();
    return familyRef.id;
  }

  Future<void> joinFamily({required String inviteCode}) async {
    final user = _requireUser;
    final code = inviteCode.trim().toUpperCase();
    final query = await _firestore
        .collection('families')
        .where('inviteCode', isEqualTo: code)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw StateError('No family found for that invite code');
    }

    final familyDoc = query.docs.first;
    final member = _memberForUser(user, role: 'member');

    final batch = _firestore.batch();
    batch.update(familyDoc.reference, {
      'memberIds': FieldValue.arrayUnion([user.uid]),
    });
    batch.set(
      familyDoc.reference.collection('members').doc(user.uid),
      {
        ...member.toMap(),
        'joinedAt': FieldValue.serverTimestamp(),
      },
    );
    batch.set(
      _firestore.collection('users').doc(user.uid),
      {'familyId': familyDoc.id},
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> inviteMember({
    required String familyId,
    required String email,
  }) async {
    final user = _requireUser;
    final familyDoc =
        await _firestore.collection('families').doc(familyId).get();
    if (!familyDoc.exists) {
      throw StateError('Family not found');
    }
    if (familyDoc.data()?['ownerId'] != user.uid) {
      throw StateError('Only the family owner can send invites');
    }

    final normalized = email.trim().toLowerCase();
    final inviteId = normalized.replaceAll(RegExp(r'[^a-z0-9]'), '_');
    await familyDoc.reference.collection('invites').doc(inviteId).set({
      'email': normalized,
      'invitedBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'inviteCode': familyDoc.data()?['inviteCode'],
    });
  }

  Future<void> addFamilyEvent(String familyId, Event event) async {
    final user = _requireUser;
    final data = event.toMap();
    data['createdBy'] = user.uid;
    data['userId'] = user.uid;
    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('events')
        .doc(event.id)
        .set(data);
  }

  Future<void> removeFamilyEvent(String familyId, String eventId) async {
    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('events')
        .doc(eventId)
        .delete();
  }

  FamilyMember _memberForUser(User user, {required String role}) {
    final seed = user.uid.hashCode.abs();
    return FamilyMember(
      uid: user.uid,
      displayName: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!
          : (user.email?.split('@').first ?? 'Me'),
      avatar: _avatars[seed % _avatars.length],
      colorValue: _colors[seed % _colors.length],
      role: role,
    );
  }
}
