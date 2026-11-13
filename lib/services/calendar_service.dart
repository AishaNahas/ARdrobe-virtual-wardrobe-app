import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/calendar_event.dart';

class CalendarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addEvent(String email, CalendarEvent event) async {
    try {
      await _firestore
          .collection('users')
          .doc(email)
          .collection('calendar_events')
          .doc(event.id)
          .set(event.toMap());
      // Also save to global 'events' collection
      final userDoc = await _firestore.collection('users').where('email', isEqualTo: email).get();
      final userId = userDoc.docs.isNotEmpty ? userDoc.docs.first.id : null;
      if (userId != null) {
        await _firestore.collection('events').doc(event.id).set({
          'userId': userId,
          'event_date': event.date.toIso8601String(),
          'event_type': event.type,
          'event_name': event.title,
          'outfit_chosen': event.items.isNotEmpty ? event.items.first.imageUrl : '',
        });
      }
    } catch (e) {
      print('Error adding calendar event: $e');
      rethrow;
    }
  }

  Future<void> updateEvent(String email, CalendarEvent event) async {
    try {
      // Overwrite the event document to ensure only the new outfit is saved
      await _firestore
          .collection('users')
          .doc(email)
          .collection('calendar_events')
          .doc(event.id)
          .set(event.toMap(), SetOptions(merge: false));
    } catch (e) {
      print('Error updating calendar event: $e');
      rethrow;
    }
  }

  Future<void> deleteEvent(String email, String eventId) async {
    try {
      await _firestore
          .collection('users')
          .doc(email)
          .collection('calendar_events')
          .doc(eventId)
          .delete();
    } catch (e) {
      print('Error deleting calendar event: $e');
      rethrow;
    }
  }

  Stream<List<CalendarEvent>> getEvents(String email) {
    return _firestore
        .collection('users')
        .doc(email)
        .collection('calendar_events')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CalendarEvent.fromMap(doc.data()))
          .toList();
    });
  }

  Future<List<CalendarEvent>> getEventsForDate(
      String email, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('users')
          .doc(email)
          .collection('calendar_events')
          .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('date', isLessThan: endOfDay.toIso8601String())
          .get();

      return snapshot.docs
          .map((doc) => CalendarEvent.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting events for date: $e');
      rethrow;
    }
  }
}
