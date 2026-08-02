import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_base.dart';
import '../models/event.dart';

/// Calls the DayBrief Claude proxy (`server.js`) instead of Anthropic directly.
/// AI features are intended for web builds served via `node server.js`.
class ClaudeService {
  static Uri _uri(String path) => ApiBase.uri(path);

  static bool get isSupportedOnPlatform => kIsWeb;

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    if (!isSupportedOnPlatform) {
      return {
        'success': false,
        'error': 'AI features are available on web only.',
      };
    }

    try {
      final response = await http.post(
        _uri(path),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 400 && data['success'] != true) {
        return {
          'success': false,
          'error': data['error'] ?? 'Request failed (${response.statusCode})',
        };
      }
      return data;
    } catch (error) {
      return {
        'success': false,
        'error': 'Network Error: $error',
      };
    }
  }

  static Map<String, dynamic> _eventToJson(Event event) => {
        'title': event.title,
        'dateTime': event.dateTime.toIso8601String(),
        if (event.description != null) 'description': event.description,
        if (event.category != null) 'category': event.category!.name,
      };

  /// Parse natural language text into an Event object.
  static Future<Event?> parseEventFromText(
      String userText, String userId) async {
    final result = await _post('/api/claude/parse-event', {
      'userText': userText,
      'userId': userId,
    });

    if (result['success'] != true || result['event'] == null) {
      return null;
    }

    try {
      final eventJson = Map<String, dynamic>.from(result['event'] as Map);
      return Event(
        id: eventJson['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: eventJson['title']?.toString() ?? 'New Event',
        dateTime: DateTime.parse(eventJson['dateTime'].toString()),
        description: eventJson['description']?.toString(),
        category:
            EventCategory.parse(eventJson['category']) ?? EventCategory.other,
        location: eventJson['location']?.toString(),
        userId: eventJson['userId']?.toString() ?? userId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Generate a daily summary of events.
  static Future<String> generateDailySummary(List<Event> events) async {
    if (events.isEmpty) {
      return 'You have no events scheduled for today. Enjoy your free day!';
    }

    final result = await _post('/api/claude/daily-summary', {
      'events': events.map(_eventToJson).toList(),
    });

    if (result['success'] == true && result['text'] != null) {
      return result['text'] as String;
    }
    return 'Unable to generate summary';
  }

  /// Answer questions about the calendar.
  static Future<String> answerQuestion(
      String question, List<Event> events) async {
    final result = await _post('/api/claude/answer-question', {
      'question': question,
      'events': events.map(_eventToJson).toList(),
    });

    if (result['success'] == true && result['text'] != null) {
      return result['text'] as String;
    }
    return 'Unable to answer right now';
  }

  /// Get smart suggestions based on event patterns.
  static Future<String> getSmartSuggestions(List<Event> events) async {
    if (events.length < 3) {
      return 'Add more events to get personalized suggestions';
    }

    final result = await _post('/api/claude/smart-suggestions', {
      'events': events.map(_eventToJson).toList(),
    });

    if (result['success'] == true && result['text'] != null) {
      return result['text'] as String;
    }
    return 'No suggestions available';
  }
}
