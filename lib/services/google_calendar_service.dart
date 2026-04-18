import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/event.dart';

class GoogleCalendarService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/calendar.events'],
  );

  GoogleSignInAccount? _currentUser;
  String? _accessToken;

  bool get isConnected => _currentUser != null;

  Future<void> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      final auth = await _currentUser!.authentication;
      _accessToken = auth.accessToken;
    } catch (error) {
      print('Error signing in: $error');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _accessToken = null;
  }

  Future<bool> syncEvent(Event event) async {
    if (_accessToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('https://www.googleapis.com/calendar/v3/calendars/primary/events'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(_eventToCalendarJson(event)),
      );
      return response.statusCode == 200;
    } catch (error) {
      print('Error syncing event: $error');
      return false;
    }
  }

  Map<String, dynamic> _eventToCalendarJson(Event event) {
    final endTime = event.dateTime.add(const Duration(hours: 1));
    
    return {
      'summary': event.title,
      'description': event.description ?? '',
      'start': {
        'dateTime': event.dateTime.toIso8601String(),
        'timeZone': 'UTC',
      },
      'end': {
        'dateTime': endTime.toIso8601String(),
        'timeZone': 'UTC',
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
      buffer.writeln('DTEND:${_formatIcsDateTime(event.dateTime.add(const Duration(hours: 1)))}');
      buffer.writeln('SUMMARY:${event.title}');
      if (event.description != null) {
        buffer.writeln('DESCRIPTION:${event.description}');
      }
      buffer.writeln('END:VEVENT');
    }
    
    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
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
      } else if (line.startsWith('END:VEVENT') && currentEventUid != null && start != null) {
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
