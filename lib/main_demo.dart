import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const DayBriefApp());
}

class DayBriefApp extends StatelessWidget {
  const DayBriefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DemoState(),
      child: MaterialApp(
        title: 'DayBrief',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const DemoHomePage(),
      ),
    );
  }
}

class DemoEvent {
  final String title;
  final TimeOfDay time;
  final String? description;
  DemoEvent({required this.title, required this.time, this.description});
}

class DemoState extends ChangeNotifier {
  final List<DemoEvent> _events = [];
  List<DemoEvent> get events => _events;

  void addEvent(String title, TimeOfDay time, String? desc) {
    _events.add(DemoEvent(title: title, time: time, description: desc));
    _events.sort((a, b) => _timeToMinutes(a.time).compareTo(_timeToMinutes(b.time)));
    notifyListeners();
  }

  void deleteEvent(int index) {
    _events.removeAt(index);
    notifyListeners();
  }

  int _timeToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  String getScheduleSpeech() {
    if (_events.isEmpty) return "You have nothing scheduled today.";
    final buffer = StringBuffer("Hi! You have ${_events.length} events today. ");
    for (final e in _events) {
      final hour = e.time.hourOfPeriod == 0 ? 12 : e.time.hourOfPeriod;
      final minute = e.time.minute.toString().padLeft(2, '0');
      final period = e.time.period == DayPeriod.am ? 'AM' : 'PM';
      buffer.write("${e.title} at $hour:$minute $period. ");
    }
    return buffer.toString();
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  bool _isListening = false;

  void _showAddEvent() {
    final titleController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add Event', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  prefixIcon: Icon(Icons.event),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                tileColor: Colors.grey[100],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                leading: const Icon(Icons.access_time),
                title: Text(selectedTime.format(context)),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setSheetState(() => selectedTime = picked);
                  }
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty) {
                    context.read<DemoState>().addEvent(
                      titleController.text,
                      selectedTime,
                      null,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add Event'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _simulateVoiceCommand() {
    final state = context.read<DemoState>();
    final speech = state.getScheduleSpeech();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Voice: $speech")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DayBrief'),
            Text(
              'Today',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddEvent,
          ),
        ],
      ),
      body: Consumer<DemoState>(
        builder: (context, state, _) {
          if (state.events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No events today',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add an event',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.events.length,
            itemBuilder: (context, index) {
              final event = state.events[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      event.time.format(context).split(' ')[0],
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(event.time.format(context)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => state.deleteEvent(index),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() => _isListening = !_isListening);
          if (_isListening) {
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() => _isListening = false);
                _simulateVoiceCommand();
              }
            });
          }
        },
        backgroundColor: _isListening ? Colors.red : Theme.of(context).colorScheme.primary,
        icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
        label: Text(
          _isListening ? 'Listening...' : 'Hey DayBrief',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
