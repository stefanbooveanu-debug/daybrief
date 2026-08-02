import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore-backed family calendar access (implemented in Phase 3).
class FamilyRepository {
  FamilyRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore firestore;
}
