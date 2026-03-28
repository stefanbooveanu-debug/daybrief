import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signUp(String email, String password, String name, String surname) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        await _saveUserProfile(credential.user!.uid, name, surname, email);
      }
      
      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveUserProfile(String uid, String name, String surname, String email) async {
    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'surname': surname,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<User?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Stream<List<Event>> getTodayEvents() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('events')
        .where('userId', isEqualTo: currentUser?.uid)
        .where('dateTime', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('dateTime', isLessThan: endOfDay.toIso8601String())
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Event.fromMap(doc.data())).toList());
  }

  Future<void> addEvent(Event event) async {
    final userId = currentUser?.uid;
    if (userId == null) return;
    
    final eventWithUser = event.copyWith(userId: userId);
    await _firestore.collection('users').doc(userId).collection('events').add(eventWithUser.toMap());
  }

  Future<void> deleteEvent(String eventId) async {
    final userId = currentUser?.uid;
    if (userId == null) return;
    
    await _firestore.collection('users').doc(userId).collection('events').doc(eventId).delete();
  }

  Future<void> updateEvent(Event event) async {
    final userId = currentUser?.uid;
    if (userId == null) return;
    
    await _firestore.collection('users').doc(userId).collection('events').doc(event.id).update(event.toMap());
  }

  Stream<List<Event>> getUserEvents() {
    final userId = currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('events')
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Event.fromMap(doc.data())).toList());
  }
}
