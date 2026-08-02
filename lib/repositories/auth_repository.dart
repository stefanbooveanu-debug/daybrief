import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();

  Future<void> updateDisplayName(User user, String displayName) =>
      user.updateDisplayName(displayName);

  Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String surname,
    required String email,
  }) =>
      _firestore.collection('users').doc(uid).set({
        'name': name,
        'surname': surname,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
}
