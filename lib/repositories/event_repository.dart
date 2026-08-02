import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event.dart';
import '../services/local_event_store.dart';

class EventRepository {
  EventRepository({
    LocalEventStore? localStore,
    FirebaseFirestore? firestore,
  })  : _localStore = localStore ?? LocalEventStore(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final LocalEventStore _localStore;
  final FirebaseFirestore _firestore;

  Future<void> setActiveUser(String? userId) =>
      _localStore.setActiveUser(userId);

  Stream<List<Event>> watchFirestoreEvents(String userId) {
    return _firestore
        .collection('events')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final events = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Event.fromMap(data);
      }).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return events;
    });
  }

  Future<List<Event>> getLocalEvents() => _localStore.getAllEvents();

  Future<void> addEvent(Event event, {required String? userId}) async {
    if (userId != null) {
      final eventData = event.toMap();
      eventData['userId'] = userId;
      await _firestore.collection('events').doc(event.id).set(eventData);
      return;
    }
    await _localStore.insertEvent(event);
  }

  Future<void> updateEvent(Event event, {required String? userId}) async {
    if (userId != null) {
      final eventData = event.toMap();
      eventData['userId'] = userId;
      await _firestore.collection('events').doc(event.id).update(eventData);
      return;
    }
    await _localStore.updateEvent(event);
  }

  Future<void> deleteEvent(String eventId, {required String? userId}) async {
    if (userId != null) {
      await _firestore.collection('events').doc(eventId).delete();
      return;
    }
    await _localStore.deleteEvent(eventId);
  }
}
