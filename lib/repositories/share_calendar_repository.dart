import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore-backed share-calendar access (implemented in Phase 3).
class ShareCalendarRepository {
  ShareCalendarRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore firestore;
}
