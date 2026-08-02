import 'dart:convert';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../models/event.dart';
import '../utils/logger.dart';

class GoogleCalendarService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/calendar.events'],
  );

  GoogleSignInAccount? _currentUser;

  bool get isConnected => _currentUser != null;

  Future<bool> signIn() async {
    try {
      final signInResult = await _googleSignIn.signIn();
      if (signInResult == null) {
        return false;
      }
      _currentUser = signInResult;
      return true;
    } catch (error) {
      DayBriefLog.error('Error signing in', error: error);
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  Future<Map<String, String>?> _authHeaders() async {
    final user = _currentUser;
    if (user == null) return null;
    return user.authHeaders;
  }

  Future<bool> syncEvent(Event event) async {
    final headers = await _authHeaders();
    if (headers == null) return false;

    try {
      final response = await http.post(
        Uri.parse(
          'https://www.googleapis.com/calendar/v3/calendars/primary/events',
        ),
        headers: {
          ...headers,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(await _eventToCalendarJson(event)),
      );
      return response.statusCode == 200;
    } catch (error) {
      DayBriefLog.error('Error syncing event', error: error);
      return false;
    }
  }

  Future<Map<String, dynamic>> _eventToCalendarJson(Event event) async {
    final endTime = event.dateTime.add(const Duration(hours: 1));
    final timeZone = (await FlutterTimezone.getLocalTimezone()).identifier;

    return {
      'summary': event.title,
      'description': event.description ?? '',
      'start': {
        'dateTime': event.dateTime.toIso8601String(),
        'timeZone': timeZone,
      },
      'end': {
        'dateTime': endTime.toIso8601String(),
        'timeZone': timeZone,
      },
    };
  }

  String generateIcsFile(List<Event> events) {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//DayBrief//Calendar//EN');

    for (final event in events) {
      buffer.writeln('BEGIN:VEVENT');
      buffer.writeln('UID:${event.id}@daybrief');
      buffer.writeln('DTSTART:${_formatIcsDateTime(event.dateTime)}');
      buffer.writeln(
        'DTEND:${_formatIcsDateTime(event.dateTime.add(const Duration(hours: 1)))}',
      );
      buffer.writeln('SUMMARY:${_escapeIcs(event.title)}');
      if (event.description != null) {
        buffer.writeln('DESCRIPTION:${_escapeIcs(event.description!)}');
      }
      buffer.writeln('END:VEVENT');
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  /// RFC 5545 text escaping for SUMMARY / DESCRIPTION.
  String _escapeIcs(String input) {
    return input
        .replaceAll('\\', '\\\\')
        .replaceAll('\n', '\\n')
        .replaceAll(';', '\\;')
        .replaceAll(',', '\\,');
  }

  String _formatIcsDateTime(DateTime dt) {
    return '${dt.toUtc().toString().replaceAll('-', '').replaceAll(':', '').split('.')[0]}Z';
  }

  List<Event> parseIcsEvents(String icsContent) {
    final events = <Event>[];
    final lines = icsContent.split('\n');

    String? currentEventUid;
    DateTime? start;
    String title = '';
    String? description;

    for (final line in lines) {
      if (line.startsWith('BEGIN:VEVENT')) {
        currentEventUid = DateTime.now().millisecondsSinceEpoch.toString();
        start = null;
        title = '';
        description = null;
      } else if (line.startsWith('END:VEVENT') &&
          currentEventUid != null &&
          start != null) {
        events.add(Event(
          id: currentEventUid,
          title: title.isNotEmpty ? title : 'Imported Event',
          dateTime: start,
          description: description,
          userId: 'imported',
        ));
        currentEventUid = null;
      } else if (currentEventUid != null) {
        if (line.startsWith('DTSTART:')) {
          start = _parseIcsDateTime(line.substring(8));
        } else if (line.startsWith('SUMMARY:')) {
          title = line.substring(8);
        } else if (line.startsWith('DESCRIPTION:')) {
          description = line.substring(12);
        }
      }
    }

    return events;
  }

  DateTime? _parseIcsDateTime(String icsDate) {
    try {
      final cleaned = icsDate.replaceAll('Z', '');
      return DateTime.tryParse(cleaned);
    } catch (e) {
      return null;
    }
  }
}
