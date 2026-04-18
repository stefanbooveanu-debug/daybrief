import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'settings_screen.dart';

class HomePage extends StatefulWidget {
  final bool isDemo;

  const HomePage({super.key, this.isDemo = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _tasks = [];
  bool _isListening = false;
  bool _isLoading = true;

  late AnimationController _micAnimController;
  late Animation<double> _micPulse;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  final List<Map<String, dynamic>> _demoTasks = [
    {'title': 'Revizuit notițe matematică', 'done': true,  'time': '09:00'},
    {'title': 'Laborator chimie',           'done': true,  'time': '10:30'},
    {'title': 'Rezolvat exerciții C++',     'done': false, 'time': '14:00'},
    {'title': 'Citit capitol fizică',       'done': false, 'time': '16:00'},
    {'title': 'Update DayBrief app',        'done': false, 'time': '18:00'},
  ];

  @override
  void initState() {
    super.initState();

    _micAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _micPulse = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _micAnimController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    _loadTasks();
  }

  @override
  void dispose() {
    _micAnimController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    if (widget.isDemo) {
      setState(() {
        _tasks = List.from(_demoTasks);
        _isLoading = false;
      });
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('date')
          .get();

      setState(() {
        _tasks = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? '',
            'done': data['done'] ?? false,
            'time': data['time'] ?? '',
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleTask(int index) async {
    final task = _tasks[index];
    final newDone = !task['done'];

    setState(() => _tasks[index]['done'] = newDone);

    if (!widget.isDemo && task['id'] != null) {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .collection('tasks')
          .doc(task['id'])
          .update({'done': newDone});
    }
  }

  double get _progressValue {
    if (_tasks.isEmpty) return 0.0;
    final done = _tasks.where((t) => t['done'] == true).length;
    return done / _tasks.length;
  }

  int get _doneTasks => _tasks.where((t) => t['done'] == true).length;

  void _toggleVoice() {
    setState(() => _isListening = !_isListening);
    if (_isListening) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _isListening = false);
      });
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bună dimineața';
    if (hour < 18) return 'Bună ziua';
    return 'Bună seara';
  }

  String get _userName {
    if (widget.isDemo) return 'Demo';
    final user = _auth.currentUser;
    if (user?.displayName != null) return user!.displayName!.split(' ')[0];
    return user?.email?.split('@')[0] ?? 'Utilizator';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5EC),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildProgressCard(),
              const SizedBox(height: 8),
              _buildTasksHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(
                        color: Color(0xFFFF8C69),
                      ))
                    : _buildTasksList(),
              ),
              _buildVoiceButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D1B00),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (widget.isDemo)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB347).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'DEMO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFF8C69),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen(categoryColors: {})),
                ),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8C69).withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.settings_rounded,
                      color: Color(0xFFFF8C69), size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB347), Color(0xFFFF7F50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8C69).withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progresul zilei',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$_doneTasks/${_tasks.length} taskuri',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progressValue,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _progressValue == 1.0
                  ? '🎉 Toate taskurile completate!'
                  : '${(_progressValue * 100).round()}% completat',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      child: Row(
        children: [
          const Text(
            'Astăzi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D1B00),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB347).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_tasks.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFF8C69),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList() {
    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Niciun task pentru azi!',
              style: TextStyle(color: Colors.grey[400], fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              'Folosește microfonul pentru a adăuga',
              style: TextStyle(color: Colors.grey[350], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        final isDone = task['done'] == true;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDone
                ? const Color(0xFFFFF0E8).withOpacity(0.6)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDone
                  ? const Color(0xFFFFD4B8)
                  : Colors.grey.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: isDone
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: GestureDetector(
              onTap: () => _toggleTask(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFFFF8C69)
                      : Colors.transparent,
                  border: Border.all(
                    color: isDone
                        ? const Color(0xFFFF8C69)
                        : Colors.grey.withOpacity(0.35),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 16)
                    : null,
              ),
            ),
            title: Text(
              task['title'] ?? '',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDone
                    ? Colors.grey[400]
                    : const Color(0xFF2D1B00),
                decoration: isDone
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
            trailing: task['time'] != null && task['time'].isNotEmpty
                ? Text(
                    task['time'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildVoiceButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [
          if (_isListening)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Ascult...',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ScaleTransition(
            scale: _isListening ? _micPulse : const AlwaysStoppedAnimation(1.0),
            child: GestureDetector(
              onTap: _toggleVoice,
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isListening
                        ? [const Color(0xFFFF6B6B), const Color(0xFFFF4444)]
                        : [const Color(0xFFFFB347), const Color(0xFFFF7F50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening
                              ? const Color(0xFFFF6B6B)
                              : const Color(0xFFFF8C69))
                          .withOpacity(0.45),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}