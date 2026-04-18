import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_provider.dart';
import '../providers/event_provider.dart';
import '../models/event.dart';
import 'package:intl/intl.dart';

class DrivingModeScreen extends StatefulWidget {
  const DrivingModeScreen({super.key});

  @override
  State<DrivingModeScreen> createState() => _DrivingModeScreenState();
}

class _DrivingModeScreenState extends State<DrivingModeScreen>
    with TickerProviderStateMixin {
  bool _isListening = false;    // microfonul e activ
  String _statusText = 'Apasă pentru a vorbi'; // textul de status
  String _lastCommand = '';                    // ultimul command recunoscut
  List<Event> _todayEvents = [];               // evenimentele de azi

  late AnimationController _pulseController;  // controller puls microfon
  late AnimationController _waveController;   // controller animatie unde
  late Animation<double> _pulse;              // animatie scala puls
  late Animation<double> _wave1;              // unda 1
  late Animation<double> _wave2;              // unda 2
  late Animation<double> _wave3;              // unda 3

  @override
  void initState() {
    super.initState();

    // animatie puls pentru butonul de microfon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true); // repeta dus-intors

    _pulse = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // animatii pentru undele sonore (cu delay-uri diferite)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(); // repeta continuu

    _wave1 = CurvedAnimation(
      parent: _waveController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _wave2 = CurvedAnimation(
      parent: _waveController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    );
    _wave3 = CurvedAnimation(
      parent: _waveController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _loadTodayEvents(); // incarcam evenimentele de azi
  }

  @override
  void dispose() {
    _pulseController.dispose(); // eliberam controllere
    _waveController.dispose();
    super.dispose();
  }

  // incarcam evenimentele de azi din provider
  void _loadTodayEvents() {
    final events =
        context.read<EventProvider>().getEventsForDay(DateTime.now());
    setState(() => _todayEvents = events);
  }

  // toggle microfon - pornire/oprire ascultare
  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      if (_isListening) {
        _statusText = 'Ascult...'; // textul cand asculta
        _startListening();
      } else {
        _statusText = 'Apasă pentru a vorbi'; // textul default
        _stopListening();
      }
    });
  }

  // pornim ascultarea vocii
  void _startListening() {
    final voiceProvider = context.read<VoiceProvider>();
    voiceProvider.startListening(onResult: (command) {
      setState(() {
        _lastCommand = command;          // salvam comanda recunoscuta
        _isListening = false;
        _statusText = 'Înțeles!';        // confirmare
      });
      _processVoiceCommand(command);    // procesam comanda
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _statusText = 'Apasă pentru a vorbi');
      });
    });
  }

  // oprim ascultarea
  void _stopListening() {
    context.read<VoiceProvider>().stopListening();
  }

  // procesam comanda vocala si raspundem
  void _processVoiceCommand(String command) {
    final lower = command.toLowerCase(); // normalizam comanda

    if (lower.contains('evenimente') || lower.contains('ce am')) {
      _speakEvents(); // citim evenimentele
    } else if (lower.contains('urmatorul') || lower.contains('următor')) {
      _speakNextEvent(); // citim urmatorul eveniment
    } else if (lower.contains('adaugă') || lower.contains('adauga')) {
      setState(() => _statusText = 'Nu poți adăuga în modul șofat'); // restrictie
      _speak('Nu poți adăuga evenimente în timp ce conduci');
    } else if (lower.contains('ora') || lower.contains('cât e')) {
      final now = DateFormat('HH:mm').format(DateTime.now());
      _speak('Este ora $now');
      setState(() => _statusText = 'Ora: $now');
    } else {
      _speak('Nu am înțeles comanda. Încearcă din nou.');
      setState(() => _statusText = 'Nu am înțeles');
    }
  }

  // citim evenimentele de azi
  void _speakEvents() {
    if (_todayEvents.isEmpty) {
      _speak('Nu ai niciun eveniment astăzi. Zi liberă!');
      setState(() => _statusText = 'Niciun eveniment azi');
    } else {
      final count = _todayEvents.length;
      _speak('Ai $count eveniment${count > 1 ? 'e' : ''} astăzi');
      setState(() => _statusText = '$count evenimente azi');
    }
  }

  // citim urmatorul eveniment
  void _speakNextEvent() {
    final now = DateTime.now();
    final upcoming = _todayEvents
        .where((e) => e.dateTime.isAfter(now)) // doar viitoare
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime)); // sortam

    if (upcoming.isEmpty) {
      _speak('Nu mai ai evenimente azi');
      setState(() => _statusText = 'Niciun eveniment următor');
    } else {
      final next = upcoming.first;
      final time = DateFormat('HH:mm').format(next.dateTime);
      _speak('Urmatorul eveniment este ${next.title} la ora $time');
      setState(() => _statusText = '${next.title} - $time');
    }
  }

  // TTS - text to speech
  void _speak(String text) {
    context.read<VoiceProvider>().speak(text); // delegate catre provider
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0500), // fundal aproape negru (siguranta sofer)
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),        // bara de sus cu titlu si iesire
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMicButton(),      // butonul mare de microfon
                  const SizedBox(height: 40),
                  _buildStatusText(),     // textul de status
                  if (_lastCommand.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildLastCommand(),  // ultima comanda recunoscuta
                  ],
                  const SizedBox(height: 60),
                  _buildEventsPreview(),  // preview evenimente azi
                ],
              ),
            ),
            _buildQuickCommands(), // comenzi rapide afistate jos
          ],
        ),
      ),
    );
  }

  // bara de sus cu titlu si buton iesire
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context), // iesim din driving mode
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1A0A).withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFF8C69).withOpacity(0.3),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFFFF8C69), size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Ieși',
                    style: TextStyle(
                      color: Color(0xFFFF8C69),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // titlu mod sofat
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Mod Șofat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Control doar prin voce',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.directions_car_rounded,
              color: Color(0xFFFF8C69), size: 22),
        ],
      ),
    );
  }

  // butonul mare circular de microfon cu unde
  Widget _buildMicButton() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // unda 3 - cea mai exterioara
              if (_isListening)
                Opacity(
                  opacity: (1.0 - _wave3.value) * 0.15, // fade out pe masura ce se extinde
                  child: Container(
                    width: 240 + _wave3.value * 40,
                    height: 240 + _wave3.value * 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF8C69),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              // unda 2
              if (_isListening)
                Opacity(
                  opacity: (1.0 - _wave2.value) * 0.25,
                  child: Container(
                    width: 200 + _wave2.value * 40,
                    height: 200 + _wave2.value * 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF8C69),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              // unda 1 - cea mai interioara
              if (_isListening)
                Opacity(
                  opacity: (1.0 - _wave1.value) * 0.35,
                  child: Container(
                    width: 160 + _wave1.value * 40,
                    height: 160 + _wave1.value * 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF8C69).withOpacity(0.05),
                      border: Border.all(
                        color: const Color(0xFFFF8C69),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              // butonul principal de microfon
              ScaleTransition(
                scale: _isListening ? _pulse : const AlwaysStoppedAnimation(1.0),
                child: GestureDetector(
                  onTap: _toggleListening,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: _isListening
                            ? [ // rosu cand asculta - atentie sofer
                                const Color(0xFFFF4444),
                                const Color(0xFFCC2222),
                              ]
                            : [ // portocaliu normal
                                const Color(0xFFFFB347),
                                const Color(0xFFFF6B35),
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening
                                  ? const Color(0xFFFF4444)
                                  : const Color(0xFFFF8C69))
                              .withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening
                          ? Icons.stop_rounded    // stop cand asculta
                          : Icons.mic_rounded,    // microfon normal
                      color: Colors.white,
                      size: 56,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // textul de status sub microfon
  Widget _buildStatusText() {
    return Text(
      _statusText,
      style: TextStyle(
        color: _isListening
            ? const Color(0xFFFF8C69)  // portocaliu cand asculta
            : Colors.grey[500],
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ultima comanda recunoscuta
  Widget _buildLastCommand() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0E00),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF8C69).withOpacity(0.2),
        ),
      ),
      child: Text(
        '"$_lastCommand"', // comanda recunoscuta intre ghilimele
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // preview cu numarul de evenimente azi
  Widget _buildEventsPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0E00),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF8C69).withOpacity(0.15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_rounded,
              color: Color(0xFFFF8C69), size: 20),
          const SizedBox(width: 10),
          Text(
            _todayEvents.isEmpty
                ? 'Niciun eveniment azi'
                : '${_todayEvents.length} eveniment${_todayEvents.length > 1 ? 'e' : ''} azi',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // comenzi rapide afisate in josul ecranului
  Widget _buildQuickCommands() {
    final commands = [
      ('Ce am azi?', Icons.list_alt_rounded),
      ('Urmatorul', Icons.skip_next_rounded),
      ('Cât e ora?', Icons.access_time_rounded),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          Text(
            'Comenzi rapide',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: commands.map((cmd) {
              return Expanded(
                child: GestureDetector(
                  onTap: () => _processVoiceCommand(cmd.$1), // procesam comanda direct
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A0E00),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFFF8C69).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(cmd.$2,
                            color: const Color(0xFFFF8C69), size: 20),
                        const SizedBox(height: 6),
                        Text(
                          cmd.$1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}