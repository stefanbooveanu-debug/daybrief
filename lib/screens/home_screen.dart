import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../providers/voice_provider.dart';
import '../models/event.dart';
import 'auth_screen.dart';
import '../widgets/add_event_sheet.dart';
import '../widgets/event_card.dart';
import '../widgets/voice_assistant_button.dart';

export '../models/event.dart' show CalendarType;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CalendarType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    final voiceProvider = context.read<VoiceProvider>();
    await voiceProvider.initialize();
  }

  void _handleVoiceResult(String text) {
    final voiceProvider = context.read<VoiceProvider>();
    final eventProvider = context.read<EventProvider>();
    final authProvider = context.read<AuthProvider>();

    if (voiceProvider.isWakeWord(text)) {
      final queryPattern = RegExp(r'what\s+(do\s+i\s+have|i\s+have)\s+(scheduled\s+)?today', caseSensitive: false);
      final addPattern = RegExp(r'add\s+.+|schedule\s+.+', caseSensitive: false);

      if (queryPattern.hasMatch(text)) {
        final events = context.read<EventProvider>().events;
        final speech = eventProvider.formatEventsForSpeech(events);
        voiceProvider.speak(speech);
      } else if (addPattern.hasMatch(text)) {
        final event = eventProvider.parseVoiceEvent(text, authProvider.userId ?? '');
        if (event != null) {
          eventProvider.addEvent(event);
          voiceProvider.speak("Added ${event.title} at ${eventProvider.formatTime(event.dateTime)}");
        } else {
          voiceProvider.speak("Sorry, I didn't understand. Try saying 'add [event] at [time]'");
        }
      } else {
        voiceProvider.speak("Say 'what do I have today' to hear your schedule, or 'add [event] at [time]' to add an event.");
      }
    }
  }

  void _showAddEventSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddEventSheet(),
    );
  }

  void _signOut() async {
    await context.read<AuthProvider>().signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DayBrief'),
            Text(
              today,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddEventSheet,
            tooltip: 'Add Event',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Consumer<EventProvider>(
        builder: (context, eventProvider, _) {
          return StreamBuilder<List<Event>>(
            stream: eventProvider.todayEventsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allEvents = snapshot.data ?? [];
              eventProvider.updateEvents(allEvents);

              final events = _selectedFilter == null
                  ? allEvents
                  : allEvents.where((e) => e.calendarType == _selectedFilter).toList();

              if (allEvents.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No events today',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the microphone and say:\n"Add [event] at [time]"',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: _showAddEventSheet,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Event Manually'),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: _selectedFilter == null,
                          onSelected: (_) => setState(() => _selectedFilter = null),
                        ),
                        FilterChip(
                          label: const Text('Work'),
                          selected: _selectedFilter == CalendarType.work,
                          onSelected: (_) => setState(() => _selectedFilter = CalendarType.work),
                        ),
                        FilterChip(
                          label: const Text('Personal'),
                          selected: _selectedFilter == CalendarType.personal,
                          onSelected: (_) => setState(() => _selectedFilter = CalendarType.personal),
                        ),
                        FilterChip(
                          label: const Text('Family'),
                          selected: _selectedFilter == CalendarType.family,
                          onSelected: (_) => setState(() => _selectedFilter = CalendarType.family),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return EventCard(
                          event: event,
                          onDelete: () => eventProvider.deleteEvent(event.id),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: const VoiceAssistantButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
