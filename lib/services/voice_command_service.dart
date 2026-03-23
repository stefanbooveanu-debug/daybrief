import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';

class VoiceCommandService {
  static const String wakeWord = 'hey daybrief';

  Future<String> processCommand(String text, List<Event> events, Future<void> Function(String) speak) async {
    final lowerText = text.toLowerCase();
    final hasWakeWord = lowerText.contains(wakeWord) || lowerText.contains('daybrief');
    final commandText = hasWakeWord 
        ? lowerText.replaceAll(RegExp(r'hey daybrief|daybrief'), '').trim() 
        : lowerText;
    
    if (!hasWakeWord) {
      return '';
    }
    
    if (commandText.contains('what day is it') || commandText.contains("what's today's date") || commandText.contains('what is the date')) {
      final now = DateTime.now();
      final dayName = DateFormat('EEEE').format(now);
      final monthName = DateFormat('MMMM').format(now);
      await speak("Today is $dayName, $monthName ${now.day}, ${now.year}");
    }
    else if (commandText.contains('what time is it') || commandText.contains("what's the time") || commandText.contains('tell me the time')) {
      final now = DateTime.now();
      final timeStr = DateFormat('h:mm a').format(now);
      await speak("It's $timeStr");
    }
    else if (commandText.contains('what do i have today') || 
        commandText.contains('what do i have scheduled') ||
        commandText.contains("what's on my schedule") ||
        commandText.contains('my schedule')) {
      await _speakSchedule(events, speak);
    } 
    else if (commandText.contains('add event') || commandText.contains('new event') || commandText.contains('schedule something') || commandText.contains('schedule') || commandText.contains('book')) {
      await speak('Opening add event');
      return 'SHOW_ADD_EVENT';
    }
    else if (commandText.contains('move') || commandText.contains('change') || commandText.contains('reschedule') || commandText.contains('shift')) {
      await _handleMoveEvent(commandText, events, speak);
    }
    else if (commandText.contains('delete') || commandText.contains('cancel') || commandText.contains('remove')) {
      await _handleDeleteByVoice(commandText, events, speak);
    }
    else if (commandText.contains('insight') || commandText.contains('focus') || commandText.contains('recommend') || commandText.contains('suggest')) {
      await _giveInsights(events, speak);
    }
    else if (commandText.contains('hello') || commandText.contains('hi') || commandText.contains('hey')) {
      await speak('Hey there! How can I help you with your calendar today?');
    }
    else if (commandText.contains('help') || commandText.contains('what can you do')) {
      await speak('I can help you. Try saying: what do I have today, schedule lunch tomorrow at 1pm, move my 3pm to 5pm, or what should I focus on?');
    }
    else if (commandText.contains('thank you') || commandText.contains('thanks')) {
      await speak("You're welcome!");
    }
    else if (commandText.isNotEmpty) {
      await speak("I'm not sure how to help with that. Try saying help to hear what I can do.");
    }
    
    return '';
  }

  Future<void> _speakSchedule(List<Event> events, Future<void> Function(String) speak) async {
    final todayEvents = events.where((e) => 
      e.dateTime.year == DateTime.now().year &&
      e.dateTime.month == DateTime.now().month &&
      e.dateTime.day == DateTime.now().day
    ).toList();
    
    if (todayEvents.isEmpty) {
      await speak("Hey! You have nothing planned for today. Enjoy your free time!");
    } else if (todayEvents.length == 1) {
      final e = todayEvents.first;
      final time = DateFormat('h:mm a').format(e.dateTime);
      final desc = (e.description ?? '').isNotEmpty ? ' for ${e.description}' : '';
      await speak("Hey! Today you need to go to ${e.title}$desc at $time");
    } else {
      final parts = <String>[];
      for (final e in todayEvents) {
        final time = DateFormat('h:mm a').format(e.dateTime);
        final desc = (e.description ?? '').isNotEmpty ? ' for ${e.description}' : '';
        parts.add("${e.title}$desc at $time");
      }
      await speak("Hey! Today you have ${todayEvents.length} things to do. ${parts.join('. ')}");
    }
  }

  Future<void> _handleMoveEvent(String command, List<Event> events, Future<void> Function(String) speak) async {
    final fromTime = _parseTime(command, ['from', 'at', 'my']);
    final toTime = _parseTime(command, ['to']);
    
    if (fromTime == null && toTime == null) {
      await speak("I didn't catch the times. Try saying: move my 3pm to 5pm");
      return;
    }
    
    Event? targetEvent;
    
    if (fromTime != null) {
      try {
        targetEvent = events.firstWhere(
          (e) => e.dateTime.hour == fromTime.hour && e.dateTime.day == DateTime.now().day,
        );
      } catch (_) {
        targetEvent = null;
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
      await speak("I couldn't find that event. Can you be more specific?");
      return;
    }
    
    if (toTime != null) {
      await speak("MOVE_EVENT:${targetEvent.id}|${toTime.hour}:${toTime.minute}");
    } else {
      await speak("Which time do you want to move it to?");
    }
  }

  Future<void> _handleDeleteByVoice(String command, List<Event> events, Future<void> Function(String) speak) async {
    String? eventName;
    
    for (final e in events) {
      if (command.contains(e.title.toLowerCase())) {
        eventName = e.title;
        break;
      }
    }
    
    if (eventName == null) {
      await speak("Which event do you want to delete?");
      return;
    }
    
    await speak("DELETE_EVENT:$eventName");
  }

  Future<void> _giveInsights(List<Event> events, Future<void> Function(String) speak) async {
    final now = DateTime.now();
    final weekEvents = events.where((e) => 
      e.dateTime.isAfter(now.subtract(Duration(days: now.weekday))) && 
      e.dateTime.isBefore(now.add(Duration(days: 7)))
    ).toList();
    
    if (weekEvents.isEmpty) {
      await speak("You have no events this week. Enjoy your free time!");
      return;
    }
    
    final categoryCount = <String, int>{};
    for (final e in weekEvents) {
      final cat = e.category ?? 'Other';
      categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
    }
    
    final sorted = categoryCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topCat = sorted.isNotEmpty ? sorted.first.key : 'work';
    
    final workEvents = weekEvents.where((e) => e.category == 'Work' || e.category == 'Personal').length;
    final healthEvents = weekEvents.where((e) => e.category == 'Health').length;
    
    String insight = "Here's your week at a glance. You have ${weekEvents.length} events, mostly $topCat. ";
    
    if (healthEvents == 0 && workEvents > 3) {
      insight += "Consider adding some exercise time - you have no health activities scheduled.";
    } else if (workEvents > 10) {
      insight += "That's a busy week! Make sure to take breaks between meetings.";
    } else {
      insight += "You've got a good balance. Keep it up!";
    }
    
    await speak(insight);
  }

  TimeOfDay? _parseTime(String text, List<String> markers) {
    final hourPattern = RegExp(r'(\d{1,2})\s*(am|pm)', caseSensitive: false);
    
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

  Event? parseVoiceEvent(String text, String userId) {
    final timePattern = RegExp(r'(\d{1,2})\s*(am|pm|oclock)?', caseSensitive: false);
    final timeMatch = timePattern.firstMatch(text);
    
    final dayPattern = RegExp(r'(today|tomorrow|next\s+\w+|monday|tuesday|wednesday|thursday|friday|saturday|sunday)', caseSensitive: false);
    final dayMatch = dayPattern.firstMatch(text);
    
    final words = text.split(' ');
    final stopWords = {'schedule', 'at', 'with', 'for', 'on', 'the', 'a', 'an', 'tomorrow', 'today', 'pm', 'am', 'oclock', 'o'};
    final titleWords = words.where((w) => !stopWords.contains(w.toLowerCase()) && !RegExp(r'\d').hasMatch(w) && !dayPattern.hasMatch(w)).toList();
    
    if (titleWords.isEmpty) return null;
    
    final title = titleWords.take(6).join(' ').replaceAll(RegExp(r'(schedule|book|event|meeting|call)'), '').trim();
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
    
    DateTime eventDate = DateTime.now();
    if (dayMatch != null) {
      final dayStr = dayMatch.group(1)!.toLowerCase();
      if (dayStr == 'today') {
        eventDate = DateTime.now();
      } else if (dayStr == 'tomorrow') {
        eventDate = DateTime.now().add(const Duration(days: 1));
      } else if (['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'].contains(dayStr)) {
        final weekdays = {'monday': 1, 'tuesday': 2, 'wednesday': 3, 'thursday': 4, 'friday': 5, 'saturday': 6, 'sunday': 7};
        final targetDay = weekdays[dayStr]!;
        final now = DateTime.now();
        var daysUntil = targetDay - now.weekday;
        if (daysUntil <= 0) daysUntil += 7;
        eventDate = now.add(Duration(days: daysUntil));
      }
    }
    
    if (time == null) {
      time = const TimeOfDay(hour: 9, minute: 0);
    }
    
    return Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      dateTime: DateTime(eventDate.year, eventDate.month, eventDate.day, time.hour, time.minute),
      category: _inferCategory(title),
      reminderEnabled: true,
      userId: userId,
    );
  }

  String _inferCategory(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('meeting') || lower.contains('work') || lower.contains('call') || lower.contains('standup')) return 'Work';
    if (lower.contains('gym') || lower.contains('workout') || lower.contains('run') || lower.contains('doctor')) return 'Health';
    if (lower.contains('lunch') || lower.contains('dinner') || lower.contains('coffee') || lower.contains('date')) return 'Personal';
    if (lower.contains('birthday') || lower.contains('party') || lower.contains('hangout')) return 'Social';
    if (lower.contains('shop') || lower.contains('buy') || lower.contains('grocery')) return 'Shopping';
    return 'Other';
  }
}
