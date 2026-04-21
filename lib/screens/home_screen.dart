import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../services/claude_service.dart';
import '../widgets/add_event_sheet.dart';
import '../widgets/event_card.dart';
import '../widgets/voice_assistant_button.dart';
import '../widgets/animated_theme.dart';
import 'settings_screen.dart';
import 'search_screen.dart';
import 'time_report_screen.dart';
import 'month_view_screen.dart';
import 'week_view_screen.dart';
import 'driving_mode_screen.dart';
import 'family_calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, Color>? categoryColors;
  final Function(Map<String, Color>)? onCategoryColorsChanged;
  final Function(bool)? onThemeChanged;

  const HomeScreen({
    super.key,
    this.categoryColors,
    this.onCategoryColorsChanged,
    this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  DateTime _selectedDay = DateTime.now();
  int _currentView = 0;
  bool _showThemeAnimation = false;

  late AnimationController _fabController;
  late Animation<double> _fabAnim;
  late AnimationController _headerController;
  late Animation<double> _headerFade;

  final List<String> _viewLabels = ['Day', 'Week', 'Month'];

  @override
  void initState() {
    super.initState();

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fabAnim = CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    );
    _fabController.forward();

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );
    _headerController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().refreshEvents();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  void _changeDay(int delta) {
    setState(() {
      _selectedDay = _selectedDay.add(Duration(days: delta));
    });
  }

  void _openAddEvent() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEventSheet(initialDate: _selectedDay),
    );
  }

  void _toggleTheme() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    setState(() => _showThemeAnimation = true);
    widget.onThemeChanged?.call(!isDark);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showThemeAnimation = false);
    });
  }

  Future<void> _showAISummary() async {
    final events = context.read<EventProvider>().getEventsForDay(_selectedDay);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? const Color(0xFF2A1A0A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9334E6), Color(0xFF1A73E8)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI Daily Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF202124),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FutureBuilder<String>(
                future: ClaudeService.generateDailySummary(events),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: Color(0xFF9334E6)),
                            SizedBox(height: 12),
                            Text('Thinking...', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  }
                  return Text(
                    snapshot.data ?? 'Unable to generate summary',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: isDark ? Colors.white70 : const Color(0xFF5F6368),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Color(0xFF9334E6), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToView(int view) {
    if (view == 1) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const WeekViewScreen()));
    } else if (view == 2) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const MonthViewScreen()));
    }
    setState(() => _currentView = view);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF1A0E00)
        : const Color(0xFFFFF5EC);
    final cardColor = isDark
        ? const Color(0xFF2A1A0A)
        : Colors.white;
    final textColor = isDark
        ? const Color(0xFFFFF5EC)
        : const Color(0xFF1A0A00);

    return SmoothThemeTransition(
      isDark: isDark,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              FadeTransition(
                opacity: _headerFade,
                child: _buildHeader(isDark, textColor, cardColor),
              ),
              _buildViewSelector(isDark, textColor),
              _buildDateNavigator(isDark, textColor),
              Expanded(
                child: _buildEventsList(isDark, textColor, cardColor),
              ),
            ],
          ),
        ),
        floatingActionButton: ScaleTransition(
          scale: _fabAnim,
          child: _buildFAB(),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _buildBottomBar(isDark, cardColor),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textColor, Color cardColor) {
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.userName ?? 'User';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          _buildHeaderButton(
            icon: Icons.auto_awesome,
            onTap: _showAISummary,
            isDark: isDark,
            color: const Color(0xFF9334E6),
          ),
          const SizedBox(width: 8),
          _buildHeaderButton(
            icon: Icons.directions_car_rounded,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DrivingModeScreen())),
            isDark: isDark,
            color: const Color(0xFFFF8C69),
          ),
          const SizedBox(width: 8),
          _buildHeaderButton(
            icon: Icons.search_rounded,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SearchScreen())),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildHeaderButton(
            icon: isDark ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded,
            onTap: _toggleTheme,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildHeaderButton(
            icon: Icons.settings_rounded,
            onTap: () async {
              final result = await Navigator.push<Map<String, dynamic>>(context,
                  MaterialPageRoute(builder: (_) => SettingsScreen(
                    categoryColors: widget.categoryColors ?? {},
                    onThemeChanged: widget.onThemeChanged,
                    onColorsChanged: widget.onCategoryColorsChanged,
                  )));
              if (result != null && mounted) {
                // Update colors if changed
                if (result['categoryColors'] != null) {
                  final newColors = Map<String, Color>.from(result['categoryColors'] as Map);
                  widget.onCategoryColorsChanged?.call(newColors);
                }
                // Theme change is handled via callback in main.dart
              }
            },
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2A1A0A)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8C69).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color ?? const Color(0xFFFF8C69),
          size: 18,
        ),
      ),
    );
  }

  Widget _buildViewSelector(bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2A1A0A)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_viewLabels.length, (index) {
            final isSelected = _currentView == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => _navigateToView(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFF8C69)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF8C69).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    _viewLabels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : Colors.grey[500],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDateNavigator(bool isDark, Color textColor) {
    final isToday = DateUtils.isSameDay(_selectedDay, DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeDay(-1),
            icon: const Icon(Icons.chevron_left_rounded),
            color: const Color(0xFFFF8C69),
            iconSize: 28,
          ),
          GestureDetector(
            onTap: () {
              setState(() => _selectedDay = DateTime.now());
            },
            child: Column(
              children: [
                Text(
                  DateFormat('EEEE', 'en_US').format(_selectedDay),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      DateFormat('MMMM d, yyyy', 'en_US').format(_selectedDay),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    if (isToday)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8C69),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Today',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _changeDay(1),
            icon: const Icon(Icons.chevron_right_rounded),
            color: const Color(0xFFFF8C69),
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(bool isDark, Color textColor, Color cardColor) {
    return Consumer<EventProvider>(
      builder: (context, eventProvider, _) {
        final events = eventProvider.getEventsForDay(_selectedDay);

        if (eventProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF8C69)),
          );
        }

        if (events.isEmpty) {
          return _buildEmptyState(isDark, textColor);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: events.length,
          cacheExtent: 200,
          itemBuilder: (context, index) {
            return EventCard(
              event: events[index],
              isDark: isDark,
              categoryColors: widget.categoryColors ?? {},
              onDelete: () => context
                  .read<EventProvider>()
                  .deleteEvent(events[index].id),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB347).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_rounded,
              size: 40,
              color: Color(0xFFFFB347),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Niciun eveniment',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Apasă + pentru a adăuga ceva',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB347), Color(0xFFFF6B35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8C69).withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IconButton(
        onPressed: _openAddEvent,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildBottomBar(bool isDark, Color cardColor) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.calendar_today_rounded,
            label: 'Calendar',
            onTap: () {},
            isActive: true,
            isDark: isDark,
          ),
          _buildNavItem(
            icon: Icons.people_alt_rounded,
            label: 'Familie',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FamilyCalendarScreen()),
            ),
            isDark: isDark,
          ),
          const SizedBox(width: 60),
          _buildNavItem(
            icon: Icons.bar_chart_rounded,
            label: 'Rapoarte',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TimeReportScreen()),
            ),
            isDark: isDark,
          ),
          const VoiceAssistantButton(),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive
                ? const Color(0xFFFF8C69)
                : Colors.grey[400],
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive
                  ? const Color(0xFFFF8C69)
                  : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}