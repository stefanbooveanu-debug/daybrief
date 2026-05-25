import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/voice_provider.dart';
import '../providers/event_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/voice_template_provider.dart';
import '../services/voice_command_service.dart';

class VoiceAssistantButton extends StatefulWidget {
  const VoiceAssistantButton({super.key});

  @override
  State<VoiceAssistantButton> createState() => _VoiceAssistantButtonState();
}

class _VoiceAssistantButtonState extends State<VoiceAssistantButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    final voiceProvider = context.read<VoiceProvider>();

    if (voiceProvider.isListening) {
      voiceProvider.stopListening();
      _animationController.stop();
      _animationController.reset();
    } else {
      voiceProvider.startListening(
        onResult: _handleVoiceResult,
        onWakeWordDetected: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.mic, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Listening for your command...'),
                ],
              ),
              backgroundColor: Color(0xFF1A73E8),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
      _animationController.repeat(reverse: true);
    }
  }

  Future<void> _handleVoiceResult(String text) async {
    final voiceProvider = context.read<VoiceProvider>();
    final eventProvider = context.read<EventProvider>();
    final authProvider = context.read<AuthProvider>();
    final templateProvider = context.read<VoiceTemplateProvider>();

    if (!voiceProvider.isWakeWord(text)) return;

    _animationController.stop();
    _animationController.reset();

    final action = await voiceProvider.processCommand(
      text,
      events: eventProvider.events,
      userId: authProvider.userId ?? '',
      matchTemplate: templateProvider.matchTemplate,
      onAddEvent: eventProvider.addEvent,
    );

    switch (action) {
      case VoiceNoOp():
        return;
      case VoiceShowAddEvent():
        await voiceProvider.speak('Opening add event');
      case VoiceMoveEvent(eventId: final id, newTime: final time):
        final target = _findById(eventProvider.events, id);
        if (target != null) {
          await eventProvider.updateEvent(target.copyWith(dateTime: time));
          await voiceProvider.speak('Moved "${target.title}"');
        }
      case VoiceDeleteEvent(eventName: final name):
        final match = _findByTitle(eventProvider.events, name);
        if (match != null) {
          await eventProvider.deleteEvent(match.id);
          await voiceProvider.speak('Deleted "$name"');
        } else {
          await voiceProvider.speak("Couldn't find $name");
        }
      case VoiceSpoken(text: final t):
        await voiceProvider.speak(t);
    }
  }

  Event? _findById(List<Event> events, String id) {
    for (final e in events) {
      if (e.id == id) return e;
    }
    return null;
  }

  Event? _findByTitle(List<Event> events, String title) {
    for (final e in events) {
      if (e.title == title) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceProvider>(
      builder: (context, voiceProvider, _) {
        final isListening = voiceProvider.isListening;
        final isSpeaking = voiceProvider.isSpeaking;

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: isListening ? _scaleAnimation.value : 1.0,
              child: FloatingActionButton.extended(
                onPressed:
                    voiceProvider.isInitialized ? _toggleListening : null,
                backgroundColor: isListening
                    ? Colors.red
                    : isSpeaking
                        ? Colors.orange
                        : const Color(0xFF1A73E8),
                elevation: 4,
                icon: Icon(
                  isSpeaking
                      ? Icons.volume_up
                      : isListening
                          ? Icons.mic
                          : Icons.mic_none,
                  color: Colors.white,
                ),
                label: Text(
                  isSpeaking
                      ? 'Speaking...'
                      : isListening
                          ? 'Listening...'
                          : 'Hey DayBrief',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}
