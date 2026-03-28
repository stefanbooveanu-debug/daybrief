import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_provider.dart';
import '../providers/event_provider.dart';
import '../providers/auth_provider.dart';

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
        onResult: (text) {
          _handleVoiceResult(text);
        },
        onWakeWordDetected: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.mic, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Listening for your command...'),
                ],
              ),
              backgroundColor: const Color(0xFF1A73E8),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
      _animationController.repeat(reverse: true);
    }
  }

  void _handleVoiceResult(String text) {
    final voiceProvider = context.read<VoiceProvider>();
    final eventProvider = context.read<EventProvider>();
    final authProvider = context.read<AuthProvider>();

    if (voiceProvider.isWakeWord(text)) {
      _animationController.stop();
      _animationController.reset();

      final queryPattern = RegExp(r'what\s+(do\s+i\s+have|i\s+have)\s+(scheduled\s+)?today', caseSensitive: false);
      final addPattern = RegExp(r'add\s+.+|schedule\s+.+', caseSensitive: false);

      if (queryPattern.hasMatch(text)) {
        final events = eventProvider.events;
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
                onPressed: voiceProvider.isInitialized ? _toggleListening : null,
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
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
