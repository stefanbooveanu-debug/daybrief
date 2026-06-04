import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';

sealed class VoiceAction {
  const VoiceAction();
}

class VoiceNoOp extends VoiceAction {
  const VoiceNoOp();
}

class VoiceShowAddEvent extends VoiceAction {
  const VoiceShowAddEvent();
}

class VoiceMoveEvent extends VoiceAction {
  const VoiceMoveEvent(this.eventId, this.newTime);
  final String eventId;
  final DateTime newTime;
}

class VoiceDeleteEvent extends VoiceAction {
  const VoiceDeleteEvent(this.eventName);
  final String eventName;
}

class VoiceSpoken extends VoiceAction {
  const VoiceSpoken(this.text);
  final String text;
}

class VoiceCommandService {
  static const String wakeWord = 'hey daybrief';

  Future<VoiceAction> processCommand(String text, List<Event> events) async {
    final lowerText = text.toLowerCase();
    final hasWakeWord =
        lowerText.contains(wakeWord) || lowerText.contains('daybrief');
    final commandText = hasWakeWord
        ? lowerText.replaceAll(RegExp(r'hey daybrief|daybrief'), '').trim()
        : lowerText;

    if (!hasWakeWord) {
      return const VoiceNoOp();
    }

    if (commandText.contains('what day is it') ||
        commandText.contains("what's today's date") ||
        commandText.contains('what is the date')) {
      final now = DateTime.now();
      final dayName = DateFormat('EEEE').format(now);
      final monthName = DateFormat('MMMM').format(now);
      return VoiceSpoken('Today is $dayName, $monthName ${now.day}, ${now.year}');
    }

    if (commandText.contains('what time is it') ||
        commandText.contains("what's the time") ||
        commandText.contains('tell me the time')) {
      final timeStr = DateFormat('h:mm a').format(DateTime.now());
      return VoiceSpoken("It's $timeStr");
    }

    if (commandText.contains('what do i have today') ||
        commandText.contains('what do i have scheduled') ||
        commandText.contains("what's on my schedule") ||
        commandText.contains('my schedule')) {
      return VoiceSpoken(formatScheduleForSpeech(events));
    }

    if (commandText.contains('add event') ||
        commandText.contains('new event') ||
        commandText.contains('schedule something') ||
        commandText.contains('schedule') ||
        commandText.contains('book')) {
      return const VoiceShowAddEvent();
    }

    if (commandText.contains('move') ||
        commandText.contains('change') ||
        commandText.contains('reschedule') ||
        commandText.contains('shift')) {
      return parseMoveEvent(commandText, events);
    }

    if (commandText.contains('delete') ||
        commandText.contains('cancel') ||
        commandText.contains('remove')) {
      return parseDeleteEvent(commandText, events);
    }

    if (commandText.contains('insight') ||
        commandText.contains('focus') ||
        commandText.contains('recommend') ||
        commandText.contains('suggest')) {
      return VoiceSpoken(_buildInsights(events));
    }

    if (commandText.contains('hello') ||
        commandText.contains('hi') ||
        commandText.contains('hey')) {
      return const VoiceSpoken(
          'Hey there! How can I help you with your calendar today?');
    }

    if (commandText.contains('help') ||
        commandText.contains('what can you do')) {
      return const VoiceSpoken(
          'I can help you. Try saying: what do I have today, schedule lunch tomorrow at 1pm, move my 3pm to 5pm, or what should I focus on?');
    }

    if (commandText.contains('thank you') || commandText.contains('thanks')) {
      return const VoiceSpoken("You're welcome!");
    }

    if (commandText.isNotEmpty) {
      return const VoiceSpoken(
          "I'm not sure how to help with that. Try saying help to hear what I can do.");
    }

    return const VoiceNoOp();
  }

  String formatScheduleForSpeech(List<Event> events) {
    final now = DateTime.now();
    final todayEvents = events
        .where((e) =>
            e.dateTime.year == now.year &&
            e.dateTime.month == now.month &&
            e.dateTime.day == now.day)
        .toList();

    if (todayEvents.isEmpty) {
      return "Hey! You have nothing planned for today. Enjoy your free time!";
    }
    if (todayEvents.length == 1) {
      final e = todayEvents.first;
      final time = DateFormat('h:mm a').format(e.dateTime);
      final desc =
          (e.description ?? '').isNotEmpty ? ' for ${e.description}' : '';
      return "Hey! Today you need to go to ${e.title}$desc at $time";
    }
    final parts = <String>[];
    for (final e in todayEvents) {
      final time = DateFormat('h:mm a').format(e.dateTime);
      final desc =
          (e.description ?? '').isNotEmpty ? ' for ${e.description}' : '';
      parts.add("${e.title}$desc at $time");
    }
    return "Hey! Today you have ${todayEvents.length} things to do. ${parts.join('. ')}";
  }

  static String formatEventsForSpeech(List<Event> events) {
    if (events.isEmpty) return 'No events scheduled';
    final buffer = StringBuffer(
        'You have ${events.length} event${events.length > 1 ? 's' : ''}');
    for (final event in events) {
      final time = DateFormat('h:mm a').format(event.dateTime);
      buffer.write('. ${event.title} at $time');
    }
    return buffer.toString();
  }

  VoiceAction parseMoveEvent(String command, List<Event> events) {
    final fromTime = _parseTime(command, ['from', 'at', 'my']);
    final toTime = _parseTime(command, ['to']);

    if (fromTime == null && toTime == null) {
      return const VoiceSpoken(
          "I didn't catch the times. Try saying: move my 3pm to 5pm");
    }

    Event? targetEvent;
    final now = DateTime.now();

    if (fromTime != null) {
      for (final e in events) {
        if (e.dateTime.hour == fromTime.hour && e.dateTime.day == now.day) {
          targetEvent = e;
          break;
        }
      }
    } else {
      for (final e in events) {
        if (command.contains(e.title.toLowerCase())) {
          targetEvent = e;
          break;
        }
      }
    }

    if (targetEvent == null) {
      return const VoiceSpoken(
          "I couldn't find that event. Can you be more specific?");
    }
    if (toTime == null) {
      return const VoiceSpoken("Which time do you want to move it to?");
    }

    final newDateTime = DateTime(
      targetEvent.dateTime.year,
      targetEvent.dateTime.month,
      targetEvent.dateTime.day,
      toTime.hour,
      toTime.minute,
    );
    return VoiceMoveEvent(targetEvent.id, newDateTime);
  }

  VoiceAction parseDeleteEvent(String command, List<Event> events) {
    for (final e in events) {
      if (command.contains(e.title.toLowerCase())) {
        return VoiceDeleteEvent(e.title);
      }
    }
    return const VoiceSpoken("Which event do you want to delete?");
  }

  String _buildInsights(List<Event> events) {
    final now = DateTime.now();
    final weekEvents = events
        .where((e) =>
            e.dateTime.isAfter(now.subtract(Duration(days: now.weekday))) &&
            e.dateTime.isBefore(now.add(const Duration(days: 7))))
        .toList();

    if (weekEvents.isEmpty) {
      return "You have no events this week. Enjoy your free time!";
    }

    final categoryCount = <String, int>{};
    for (final e in weekEvents) {
      final cat = (e.category ?? EventCategory.other).displayName;
      categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
    }

    final sorted = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCat = sorted.isNotEmpty ? sorted.first.key : 'Other';

    final workEvents = weekEvents
        .where((e) =>
            e.category == EventCategory.work ||
            e.category == EventCategory.personal)
        .length;
    final healthEvents = weekEvents
        .where((e) => e.category == EventCategory.health)
        .length;

    final pieces = <String>[];
    if (workEvents > 10) {
      pieces.add("That's a busy week! Make sure to take breaks between meetings.");
    }
    if (healthEvents == 0 && workEvents > 3) {
      pieces.add(
          "Consider adding some exercise time - you have no health activities scheduled.");
    }
    if (pieces.isEmpty) {
      pieces.add("You've got a good balance. Keep it up!");
    }

    return "Here's your week at a glance. You have ${weekEvents.length} events, mostly $topCat. ${pieces.join(' ')}";
  }

  TimeOfDay? _parseTime(String text, List<String> markers) {
    final hourPattern =
        RegExp(r'(\d{1,2})\s*(am|pm)', caseSensitive: false);

    for (final marker in markers) {
      final idx = text.indexOf(marker);
      if (idx != -1) {
        final substr = text.substring(idx);
        final match = hourPattern.firstMatch(substr);
        if (match != null) {
          var hour = int.parse(match.group(1)!);
          final period = match.group(2)!.toLowerCase();
          if (period == 'pm' && hour != 12) hour += 12;
          if (period == 'am' && hour == 12) hour = 0;
          return TimeOfDay(hour: hour, minute: 0);
        }
      }
    }
    return null;
  }

  Event? parseAddEvent(String text, String userId) {
    final timePattern =
        RegExp(r'(\d{1,2})\s*(am|pm|oclock)?', caseSensitive: false);
    final timeMatch = timePattern.firstMatch(text);

    final dayPattern = RegExp(
        r'(today|tomorrow|next\s+\w+|monday|tuesday|wednesday|thursday|friday|saturday|sunday)',
        caseSensitive: false);
    final dayMatch = dayPattern.firstMatch(text);

    final words = text.split(' ');
    const stopWords = {
      'schedule',
      'at',
      'with',
      'for',
      'on',
      'the',
      'a',
      'an',
      'tomorrow',
      'today',
      'pm',
      'am',
      'oclock',
      'o'
    };
    final titleWords = words
        .where((w) =>
            !stopWords.contains(w.toLowerCase()) &&
            !RegExp(r'\d').hasMatch(w) &&
            !dayPattern.hasMatch(w))
        .toList();

    if (titleWords.isEmpty) return null;

    // Strip only command verbs ("schedule", "book", "event") so the actual
    // event nouns ("meeting", "call", etc.) survive into the title.
    final title = titleWords
        .take(6)
        .join(' ')
        .replaceAll(RegExp(r'\b(schedule|book|event)\b'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (title.isEmpty) return null;

    TimeOfDay? time;
    if (timeMatch != null) {
      var hour = int.parse(timeMatch.group(1)!);
      final isPM = text.contains('pm');
      final isAM = text.contains('am');
      if (isPM && hour != 12) hour += 12;
      if (isAM && hour == 12) hour = 0;
      time = TimeOfDay(hour: hour, minute: 0);
    }

    var eventDate = DateTime.now();
    if (dayMatch != null) {
      final dayStr = dayMatch.group(1)!.toLowerCase();
      if (dayStr == 'today') {
        eventDate = DateTime.now();
      } else if (dayStr == 'tomorrow') {
        eventDate = DateTime.now().add(const Duration(days: 1));
      } else if ([
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday'
      ].contains(dayStr)) {
        const weekdays = {
          'monday': 1,
          'tuesday': 2,
          'wednesday': 3,
          'thursday': 4,
          'friday': 5,
          'saturday': 6,
          'sunday': 7
        };
        final targetDay = weekdays[dayStr]!;
        final now = DateTime.now();
        var daysUntil = targetDay - now.weekday;
        if (daysUntil <= 0) daysUntil += 7;
        eventDate = now.add(Duration(days: daysUntil));
      }
    }

    time ??= const TimeOfDay(hour: 9, minute: 0);

    return Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      dateTime: DateTime(eventDate.year, eventDate.month, eventDate.day,
          time.hour, time.minute),
      category: _inferCategory(title),
      reminderEnabled: true,
      userId: userId,
    );
  }

  EventCategory _inferCategory(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('meeting') ||
        lower.contains('work') ||
        lower.contains('call') ||
        lower.contains('standup')) {
      return EventCategory.work;
    }
    if (lower.contains('gym') ||
        lower.contains('workout') ||
        lower.contains('run') ||
        lower.contains('doctor')) {
      return EventCategory.health;
    }
    if (lower.contains('lunch') ||
        lower.contains('dinner') ||
        lower.contains('coffee') ||
        lower.contains('date')) {
      return EventCategory.personal;
    }
    if (lower.contains('birthday') ||
        lower.contains('party') ||
        lower.contains('hangout')) {
      return EventCategory.social;
    }
    if (lower.contains('shop') ||
        lower.contains('buy') ||
        lower.contains('grocery')) {
      return EventCategory.shopping;
    }
    return EventCategory.other;
  }
}
