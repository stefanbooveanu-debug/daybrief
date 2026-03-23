import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../widgets/add_event_sheet_demo.dart';
import '../widgets/events_list_widget.dart';
import 'week_view_screen_demo.dart';
import 'settings_screen.dart';
import 'month_view_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, Color> categoryColors;
  final Function(Map<String, Color>)? onCategoryColorsChanged;
  final Function(bool)? onThemeChanged;
  
  const HomeScreen({
    super.key,
    required this.categoryColors,
    this.onCategoryColorsChanged,
    this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  List<Event> _events = [];
  late AnimationController _fabAnimController;
  late Animation<double> _fabScaleAnim;
  late Animation<double> _fabRotateAnim;
  
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabScaleAnim = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _fabAnimController, curve: Curves.easeInOut),
    );
    _fabRotateAnim = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _fabAnimController, curve: Curves.easeInOut),
    );
    _addSampleEvents();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onError: (e) => debugPrint('Speech error: $e'),
      onStatus: (e) => debugPrint('Speech status: $e'),
    );
    
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.55);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.1);
    
    final voices = await _tts.getVoices;
    if (voices != null && voices.isNotEmpty) {
      for (var voice in voices) {
        if (voice.toString().contains('en-US') && 
            (voice.toString().contains('female') || voice.toString().contains('Feminine') || voice.toString().contains('en-US-Standard'))) {
          await _tts.setVoice(voice);
          break;
        }
      }
    }
    
    if (!kIsWeb) {
      await _tts.setSharedInstance(true);
      await _tts.awaitSpeakCompletion(true);
    }
    
    _tts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });
    
    _tts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });
    
    if (mounted) setState(() {});
  }

  void _startListening() async {
    if (!_speechEnabled) {
      _showMessage('Speech not available');
      return;
    }
    
    setState(() => _isListening = true);
    
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _handleVoiceCommand(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(milliseconds: 800),
    );
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  void _handleVoiceCommand(String text) async {
    final lowerText = text.toLowerCase();
    final hasWakeWord = lowerText.contains('hey daybrief') || lowerText.contains('daybrief');
    final commandText = hasWakeWord ? lowerText.replaceAll(RegExp(r'hey daybrief|daybrief'), '').trim() : lowerText;
    
    if (!hasWakeWord && !_isListening) return;
    
    if (commandText.contains('what day is it') || commandText.contains("what's today's date") || commandText.contains('what is the date')) {
      final now = DateTime.now();
      final dayName = DateFormat('EEEE').format(now);
      final monthName = DateFormat('MMMM').format(now);
      await _speak("Today is $dayName, $monthName ${now.day}, ${now.year}");
    }
    else if (commandText.contains('what time is it') || commandText.contains("what's the time") || commandText.contains('tell me the time')) {
      final now = DateTime.now();
      final timeStr = DateFormat('h:mm a').format(now);
      await _speak("It's $timeStr");
    }
    else if (commandText.contains('what do i have today') || 
        commandText.contains('what do i have scheduled') ||
        commandText.contains("what's on my schedule") ||
        commandText.contains('my schedule')) {
      await _speakSchedule();
    } 
    else if (commandText.contains('add event') || commandText.contains('new event') || commandText.contains('schedule something') || commandText.contains('schedule') || commandText.contains('book')) {
      final created = await _handleNaturalCreateEvent(commandText);
      if (!created) {
        _showAddEventSheet();
        await _speak('Opening add event');
      }
    }
    else if (commandText.contains('move') || commandText.contains('change') || commandText.contains('reschedule') || commandText.contains('shift')) {
      await _handleMoveEvent(commandText);
    }
    else if (commandText.contains('delete') || commandText.contains('cancel') || commandText.contains('remove')) {
      await _handleDeleteByVoice(commandText);
    }
    else if (commandText.contains('insight') || commandText.contains('focus') || commandText.contains('recommend') || commandText.contains('suggest')) {
      await _giveInsights();
    }
    else if (commandText.contains('hello') || commandText.contains('hi') || commandText.contains('hey')) {
      await _speak('Hey there! How can I help you with your calendar today?');
    }
    else if (commandText.contains('help') || commandText.contains('what can you do')) {
      await _speak('I can help you. Try saying: what do I have today, schedule lunch tomorrow at 1pm, move my 3pm to 5pm, or what should I focus on?');
    }
    else if (commandText.contains('thank you') || commandText.contains('thanks')) {
      await _speak("You're welcome!");
    }
    else if (commandText.isNotEmpty) {
      await _speak("I'm not sure how to help with that. Try saying help to hear what I can do.");
    }
  }

  Future<void> _speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> _speakSchedule() async {
    final todayEvents = _events.where((e) => 
      e.dateTime.year == DateTime.now().year &&
      e.dateTime.month == DateTime.now().month &&
      e.dateTime.day == DateTime.now().day
    ).toList();
    
    if (todayEvents.isEmpty) {
      await _speak("Hey! You have nothing planned for today. Enjoy your free time!");
    } else if (todayEvents.length == 1) {
      final e = todayEvents.first;
      final time = DateFormat('h:mm a').format(e.dateTime);
      final desc = (e.description ?? '').isNotEmpty ? ' for ${e.description}' : '';
      await _speak("Hey! Today you need to go to ${e.title}$desc at $time");
    } else {
      final parts = <String>[];
      for (final e in todayEvents) {
        final time = DateFormat('h:mm a').format(e.dateTime);
        final desc = (e.description ?? '').isNotEmpty ? ' for ${e.description}' : '';
        parts.add("${e.title}$desc at $time");
      }
      await _speak("Hey! Today you have ${todayEvents.length} things to do. ${parts.join('. ')}");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating),
    );
  }

  void _addSampleEvents() {
    final now = DateTime.now();
    _events = [
      Event(id: '1', title: 'Team Standup', dateTime: DateTime(now.year, now.month, now.day, 9, 0), description: 'Daily sync with the team', category: 'Work', reminderEnabled: true, userId: 'demo'),
      Event(id: '2', title: 'Gym Workout', dateTime: DateTime(now.year, now.month, now.day, 18, 0), description: 'Leg day session', category: 'Health', reminderEnabled: true, userId: 'demo'),
      Event(id: '3', title: 'Coffee Break', dateTime: DateTime(now.year, now.month, now.day + 1, 14, 30), description: 'Meet with Alex', category: 'Personal', reminderEnabled: true, userId: 'demo'),
      Event(id: '4', title: 'Project Deadline', dateTime: DateTime(now.year, now.month, now.day + 2, 17, 0), description: 'Submit final deliverables', category: 'Work', reminderEnabled: true, userId: 'demo'),
    ];
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  void _addEvent(Event event) {
    final conflicts = _events.where((e) =>
      e.dateTime.year == event.dateTime.year &&
      e.dateTime.month == event.dateTime.month &&
      e.dateTime.day == event.dateTime.day &&
      (e.dateTime.hour == event.dateTime.hour || 
       (e.dateTime.hour - event.dateTime.hour).abs() < 1)
    ).toList();
    
    if (conflicts.isNotEmpty) {
      _showMessage('Warning: Overlaps with "${conflicts.first.title}" at ${DateFormat('h:mm a').format(conflicts.first.dateTime)}');
    }
    
    setState(() {
      _events.add(event);
      _events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    });
  }

  void _deleteEvent(String eventId) {
    setState(() {
      _events.removeWhere((e) => e.id == eventId);
    });
  }

  void _completeEvent(String eventId) {
    setState(() {
      final index = _events.indexWhere((e) => e.id == eventId);
      if (index != -1) {
        _events[index] = _events[index].copyWith(isCompleted: !_events[index].isCompleted);
      }
    });
  }

  Future<void> _handleMoveEvent(String command) async {
    final fromTime = _parseTime(command, ['from', 'at', 'my']);
    final toTime = _parseTime(command, ['to']);
    
    if (fromTime == null && toTime == null) {
      await _speak("I didn't catch the times. Try saying: move my 3pm to 5pm");
      return;
    }
    
    Event? targetEvent;
    
    if (fromTime != null) {
      targetEvent = _events.firstWhere(
        (e) => e.dateTime.hour == fromTime.hour && e.dateTime.day == _selectedDate.day,
        orElse: () => Event(id: '', title: '', dateTime: DateTime.now(), userId: ''),
      );
    } else {
      for (final e in _events) {
        if (command.contains(e.title.toLowerCase())) {
          targetEvent = e;
          break;
        }
      }
    }
    
    if (targetEvent == null || targetEvent.id.isEmpty) {
      await _speak("I couldn't find that event. Can you be more specific?");
      return;
    }
    
    if (toTime != null) {
      final newDateTime = DateTime(
        targetEvent.dateTime.year,
        targetEvent.dateTime.month,
        targetEvent.dateTime.day,
        toTime.hour,
        toTime.minute,
      );
      
      setState(() {
        final index = _events.indexWhere((e) => e.id == targetEvent!.id);
        if (index != -1) {
          _events[index] = targetEvent!.copyWith(dateTime: newDateTime);
        }
      });
      
      await _speak("Done! Moved ${targetEvent.title} to ${DateFormat('h:mm a').format(newDateTime)}");
    } else {
      await _speak("Which time do you want to move it to?");
    }
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
  
  Future<void> _handleDeleteByVoice(String command) async {
    String? eventName;
    
    for (final e in _events) {
      if (command.contains(e.title.toLowerCase())) {
        eventName = e.title;
        break;
      }
    }
    
    if (eventName == null) {
      await _speak("Which event do you want to delete?");
      return;
    }
    
    setState(() {
      _events.removeWhere((e) => e.title.toLowerCase() == eventName!.toLowerCase());
    });
    
    await _speak("Deleted $eventName");
  }

  Future<void> _giveInsights() async {
    final now = DateTime.now();
    final weekEvents = _events.where((e) => 
      e.dateTime.isAfter(now.subtract(Duration(days: now.weekday))) && 
      e.dateTime.isBefore(now.add(const Duration(days: 7)))
    ).toList();
    
    if (weekEvents.isEmpty) {
      await _speak("You have no events this week. Enjoy your free time!");
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
    
    await _speak(insight);
  }

  Future<bool> _handleNaturalCreateEvent(String command) async {
    final timePattern = RegExp(r'(\d{1,2})\s*(am|pm|oclock)?', caseSensitive: false);
    final timeMatch = timePattern.firstMatch(command);
    
    final dayPattern = RegExp(r'(today|tomorrow|next\s+\w+|monday|tuesday|wednesday|thursday|friday|saturday|sunday)', caseSensitive: false);
    final dayMatch = dayPattern.firstMatch(command);
    
    final words = command.split(' ');
    final stopWords = {'schedule', 'at', 'with', 'for', 'on', 'the', 'a', 'an', 'tomorrow', 'today', 'pm', 'am', 'oclock', 'o'};
    final titleWords = words.where((w) => !stopWords.contains(w.toLowerCase()) && !RegExp(r'\d').hasMatch(w) && !dayPattern.hasMatch(w)).toList();
    
    if (titleWords.isEmpty) return false;
    
    final title = titleWords.take(6).join(' ').replaceAll(RegExp(r'(schedule|book|event|meeting|call)'), '').trim();
    if (title.isEmpty) return false;
    
    TimeOfDay? time;
    if (timeMatch != null) {
      var hour = int.parse(timeMatch.group(1)!);
      final isPM = command.contains('pm');
      final isAM = command.contains('am');
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
      } else if (dayStr == 'monday' || dayStr == 'tuesday' || dayStr == 'wednesday' || dayStr == 'thursday' || dayStr == 'friday' || dayStr == 'saturday' || dayStr == 'sunday') {
        final weekdays = {'monday': 1, 'tuesday': 2, 'wednesday': 3, 'thursday': 4, 'friday': 5, 'saturday': 6, 'sunday': 7};
        final targetDay = weekdays[dayStr]!;
        final now = DateTime.now();
        var daysUntil = targetDay - now.weekday;
        if (daysUntil <= 0) daysUntil += 7;
        eventDate = now.add(Duration(days: daysUntil));
      }
    }
    
    time ??= const TimeOfDay(hour: 9, minute: 0);
    
    final event = Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      dateTime: DateTime(eventDate.year, eventDate.month, eventDate.day, time.hour, time.minute),
      category: _inferCategory(title),
      reminderEnabled: true,
      userId: 'demo',
    );
    
    _addEvent(event);
    await _speak("Created ${event.title} for ${DateFormat('EEEE').format(eventDate)} at ${DateFormat('h:mm a').format(event.dateTime)}");
    return true;
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

  void _duplicateEvent(Event event) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: event.dateTime.add(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (pickedDate != null) {
      final context = this.context;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(event.dateTime),
      );
      
      if (pickedTime != null && mounted) {
        final newEvent = Event(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: event.title,
          dateTime: DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute),
          description: event.description,
          category: event.category,
          reminderEnabled: event.reminderEnabled,
          userId: event.userId,
        );
        _addEvent(newEvent);
        _showMessage('Event duplicated to ${DateFormat('MMM d').format(pickedDate)}');
      }
    }
  }

  void _showAddEventSheet() {
    _fabAnimController.forward().then((_) => _fabAnimController.reverse());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEventSheetDemo(onEventAdded: _addEvent, categoryColors: widget.categoryColors),
    );
  }

  void _navigateToWeekView() {
    Navigator.of(context).push(_createRoute(WeekViewScreenDemo(
      events: _events,
      onAddEvent: _addEvent,
      onDeleteEvent: _deleteEvent,
      categoryColors: widget.categoryColors,
    )));
  }

  void _navigateToMonthView() {
    Navigator.of(context).push(_createRoute(MonthViewScreen(
      events: _events,
      onAddEvent: _addEvent,
      onSelectDate: (date) => setState(() => _selectedDate = date),
      categoryColors: widget.categoryColors,
    )));
  }

  void _navigateToSearch() {
    Navigator.of(context).push(_createRoute(SearchScreen(events: _events, onEventTap: (event) {
      setState(() => _selectedDate = event.dateTime);
      Navigator.pop(context);
    })));
  }

  void _navigateToSettings() {
    Navigator.of(context).push(_createRoute(SettingsScreen(
      categoryColors: widget.categoryColors,
      onThemeChanged: widget.onThemeChanged,
      onColorsChanged: widget.onCategoryColorsChanged,
    )));
  }

  PageRouteBuilder _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  void _goToPreviousDay() => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
  void _goToNextDay() => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  List<Event> _getFilteredEvents() => _events.where((e) => _isSameDay(e.dateTime, _selectedDate)).toList();

  int _getUpcomingCount() => _events.where((e) => e.dateTime.isAfter(DateTime.now()) && e.dateTime.isBefore(DateTime.now().add(const Duration(hours: 24)))).length;

  List<Color> _getMotionColors() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 8) {
      return [const Color(0xFFFF9A8B), const Color(0xFFFF6A88), const Color(0xFFFF99AC)]; // Sunrise
    } else if (hour >= 8 && hour < 12) {
      return [const Color(0xFF667EEA), const Color(0xFF764BA2)]; // Morning
    } else if (hour >= 12 && hour < 17) {
      return [const Color(0xFF11998E), const Color(0xFF38EF7D)]; // Afternoon
    } else if (hour >= 17 && hour < 20) {
      return [const Color(0xFFFDA085), const Color(0xFFF6D365)]; // Sunset
    } else if (hour >= 20 || hour < 5) {
      return [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)]; // Night
    }
    return [const Color(0xFF667EEA), const Color(0xFF764BA2)];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final dayEvents = _getFilteredEvents();
    final upcomingCount = _getUpcomingCount();
    final motionColors = _getMotionColors();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
                ? [const Color(0xFF121212), const Color(0xFF1E1E1E)]
                : motionColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isToday, isDark),
              _buildQuickStats(upcomingCount, isDark),
              _buildMiniCalendarStrip(isDark),
              Expanded(child: _buildEventsList(dayEvents, isDark)),
            ],
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_speechEnabled)
            FloatingActionButton(
              heroTag: 'voice',
              onPressed: _isListening ? _stopListening : _startListening,
              backgroundColor: _isListening ? Colors.red : (isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8)),
              child: Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.white),
            ),
          if (_speechEnabled) const SizedBox(width: 12),
          RotationTransition(
            turns: _fabRotateAnim,
            child: ScaleTransition(
              scale: _fabScaleAnim,
              child: FloatingActionButton.extended(
                heroTag: 'add',
                onPressed: _showAddEventSheet,
                backgroundColor: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
                elevation: 8,
                icon: const Icon(Icons.add_rounded, size: 28),
                label: const Text('New Event', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  Widget _buildHeader(bool isToday, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(isToday ? 'Today' : DateFormat('EEEE').format(_selectedDate),
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF202124))),
                    if (isToday) Container(
                      margin: const EdgeInsets.only(left: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('NOW', style: TextStyle(color: isDark ? const Color(0xFF121212) : Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(DateFormat('MMMM d, yyyy').format(_selectedDate),
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ],
            ),
          ),
          _buildCircleButton(Icons.chevron_left, _goToPreviousDay, isDark),
          _buildCircleButton(Icons.chevron_right, _goToNextDay, isDark),
          _buildCircleButton(Icons.search, _navigateToSearch, isDark),
          _buildCircleButton(Icons.settings_outlined, _navigateToSettings, isDark),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Material(
        color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(padding: const EdgeInsets.all(10), child: Icon(icon, color: isDark ? Colors.white70 : const Color(0xFF5F6368), size: 22)),
        ),
      ),
    );
  }

  Widget _buildQuickStats(int upcomingCount, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [const Color(0xFF1E1E1E), const Color(0xFF2D2D2D)] : [Colors.white, const Color(0xFFF8F9FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          _buildStatItem('Upcoming', '$upcomingCount', Icons.schedule, const Color(0xFF1A73E8), isDark),
          Container(width: 1, height: 40, color: isDark ? Colors.grey[800] : Colors.grey[200], margin: const EdgeInsets.symmetric(horizontal: 16)),
          _buildStatItem('Total', '${_events.length}', Icons.event_note, const Color(0xFF34A853), isDark),
          Container(width: 1, height: 40, color: isDark ? Colors.grey[800] : Colors.grey[200], margin: const EdgeInsets.symmetric(horizontal: 16)),
          _buildStatItem('Today', '${_getFilteredEvents().length}', Icons.today, const Color(0xFF9334E6), isDark),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF202124))),
          Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMiniCalendarStrip(bool isDark) {
    final today = DateTime.now();
    
    return Container(
      height: 85,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              reverse: true,
              itemCount: 7,
              itemBuilder: (context, index) {
                final date = today.add(Duration(days: index));
                final isSelected = _isSameDay(date, _selectedDate);
                
                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected ? (isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8)) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(DateFormat('E').format(date).substring(0, 1),
                          style: TextStyle(fontSize: 11, color: isSelected ? (isDark ? Colors.black54 : Colors.white70) : (isDark ? Colors.grey[400] : const Color(0xFF5F6368)))),
                        const SizedBox(height: 4),
                        Text('${date.day}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                            color: isSelected ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white : const Color(0xFF202124)))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMiniNavBtn(Icons.chevron_left, _goToPreviousDay, isDark),
                const SizedBox(height: 4),
                _buildMiniNavBtn(Icons.chevron_right, _goToNextDay, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniNavBtn(IconData icon, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF1F3F4), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: isDark ? Colors.white70 : const Color(0xFF5F6368)),
      ),
    );
  }

  Widget _buildEventsList(List<Event> dayEvents, bool isDark) {
    return EventsListWidget(
      events: dayEvents,
      categoryColors: widget.categoryColors,
      isDark: isDark,
      onNavigateToWeekView: _navigateToWeekView,
      onNavigateToMonthView: _navigateToMonthView,
      onEventTap: (event) {},
      onDelete: _deleteEvent,
      onDuplicate: _duplicateEvent,
      onComplete: _completeEvent,
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.1), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.calendar_today_rounded, 'Day', true, isDark),
              _buildNavItem(Icons.calendar_view_week_rounded, 'Week', false, isDark, onTap: _navigateToWeekView),
              _buildNavItem(Icons.calendar_month_rounded, 'Month', false, isDark, onTap: _navigateToMonthView),
              _buildNavItem(Icons.settings_outlined, 'Settings', false, isDark, onTap: _navigateToSettings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, bool isDark, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? (isDark ? const Color(0xFF8AB4F8).withOpacity(0.2) : const Color(0xFFE8F0FE)) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? (isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8)) : (isDark ? Colors.white70 : const Color(0xFF5F6368)), size: 22),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8), fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }
}
