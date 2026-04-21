import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/event.dart';

class ClaudeService {
  static Future<Map<String, dynamic>> _sendMessage(String prompt, {String? systemPrompt}) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.claudeApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': AppConfig.anthropicApiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': AppConfig.claudeModel,
          'max_tokens': AppConfig.maxTokens,
          if (systemPrompt != null) 'system': systemPrompt,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'text': data['content']?[0]?['text'] ?? '',
        };
      } else {
        return {
          'success': false,
          'error': 'API Error: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network Error: $e',
      };
    }
  }

  /// Parse natural language text into an Event object
  /// Example: "Meeting with John tomorrow at 3pm" → Event
  static Future<Event?> parseEventFromText(String userText, String userId) async {
    final now = DateTime.now();
    final systemPrompt = '''You are a calendar assistant. Parse the user's message into a JSON event.
Current date/time: ${now.toIso8601String()}
Respond ONLY with valid JSON, no markdown, no explanation.

Format:
{
  "title": "short event title",
  "description": "optional description or null",
  "dateTime": "YYYY-MM-DDTHH:mm:00",
  "category": "Work|Personal|Health|Social|Shopping|Other",
  "location": "optional location or null"
}

If you can't parse it, respond with: {"error": "reason"}''';

    final result = await _sendMessage(userText, systemPrompt: systemPrompt);
    
    if (!result['success']) {
      return null;
    }

    try {
      final text = result['text'] as String;
      // Clean up markdown if present
      final cleanedText = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      
      final json = jsonDecode(cleanedText);
      
      if (json['error'] != null) {
        return null;
      }

      return Event(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'] ?? 'New Event',
        dateTime: DateTime.parse(json['dateTime']),
        description: json['description'],
        category: json['category'] ?? 'Other',
        location: json['location'],
        userId: userId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Generate a daily summary of events
  static Future<String> generateDailySummary(List<Event> events) async {
    if (events.isEmpty) {
      return "You have no events scheduled for today. Enjoy your free day!";
    }

    final eventsList = events.map((e) => 
      '- ${e.title} at ${e.dateTime.hour}:${e.dateTime.minute.toString().padLeft(2, '0')}${e.description != null ? " (${e.description})" : ""}'
    ).join('\n');

    final prompt = '''Give me a brief, friendly daily briefing for these events. Keep it under 3 sentences, warm and encouraging:

$eventsList''';

    final result = await _sendMessage(prompt);
    return result['success'] ? result['text'] : 'Unable to generate summary';
  }

  /// Answer questions about the calendar
  static Future<String> answerQuestion(String question, List<Event> events) async {
    final now = DateTime.now();
    final eventsList = events.map((e) => 
      '${e.title} - ${e.dateTime.toIso8601String()}${e.category != null ? " (${e.category})" : ""}'
    ).join('\n');

    final systemPrompt = '''You are a calendar assistant. The user will ask questions about their schedule.
Current date/time: ${now.toIso8601String()}

Their events:
$eventsList

Answer concisely and conversationally.''';

    final result = await _sendMessage(question, systemPrompt: systemPrompt);
    return result['success'] ? result['text'] : 'Unable to answer right now';
  }

  /// Get smart suggestions based on event patterns
  static Future<String> getSmartSuggestions(List<Event> events) async {
    if (events.length < 3) {
      return 'Add more events to get personalized suggestions';
    }

    final eventsList = events.map((e) => 
      '${e.title} - ${e.dateTime.toIso8601String()} (${e.category ?? "uncategorized"})'
    ).join('\n');

    final prompt = '''Looking at these events, suggest 1-2 helpful insights or patterns in 2 sentences:

$eventsList''';

    final result = await _sendMessage(prompt);
    return result['success'] ? result['text'] : 'No suggestions available';
  }
}
