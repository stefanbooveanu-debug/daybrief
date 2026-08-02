import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore-backed poll access (implemented in Phase 3).
class PollRepository {
  PollRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore firestore;
}
