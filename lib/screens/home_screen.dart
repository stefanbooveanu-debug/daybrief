import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../widgets/add_event_sheet_demo.dart';
import '../widgets/event_card.dart';
import 'week_view_screen_demo.dart';
import 'settings_screen.dart';
import 'month_view_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  List<Event> _events = [];
  late AnimationController _fabAnimController;
  late Animation<double> _fabScaleAnim;
  late Animation<double> _fabRotateAnim;
  bool _showSearch = false;

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
  }

  void _addSampleEvents() {
    final now = DateTime.now();
    _events = [
      Event(id: '1', title: 'Team Standup', dateTime: DateTime(now.year, now.month, now.day, 9, 0), description: 'Daily sync with the team', userId: 'demo'),
      Event(id: '2', title: 'Gym Workout', dateTime: DateTime(now.year, now.month, now.day, 18, 0), description: 'Leg day session', userId: 'demo'),
      Event(id: '3', title: 'Coffee Break', dateTime: DateTime(now.year, now.month, now.day + 1, 14, 30), description: 'Meet with Alex', userId: 'demo'),
      Event(id: '4', title: 'Project Deadline', dateTime: DateTime(now.year, now.month, now.day + 2, 17, 0), description: 'Submit final deliverables', userId: 'demo'),
    ];
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  void _addEvent(Event event) {
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

  void _showAddEventSheet() {
    _fabAnimController.forward().then((_) => _fabAnimController.reverse());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEventSheetDemo(onEventAdded: _addEvent),
    );
  }

  void _navigateToWeekView() {
    Navigator.of(context).push(_createRoute(WeekViewScreenDemo(
      events: _events,
      onAddEvent: _addEvent,
      onDeleteEvent: _deleteEvent,
    )));
  }

  void _navigateToMonthView() {
    Navigator.of(context).push(_createRoute(MonthViewScreen(
      events: _events,
      onAddEvent: _addEvent,
      onSelectDate: (date) => setState(() => _selectedDate = date),
    )));
  }

  void _navigateToSearch() {
    Navigator.of(context).push(_createRoute(SearchScreen(events: _events, onEventTap: (event) {
      setState(() => _selectedDate = event.dateTime);
      Navigator.pop(context);
    })));
  }

  void _navigateToSettings() {
    Navigator.of(context).push(_createRoute(const SettingsScreen()));
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

  void _goToToday() => setState(() => _selectedDate = DateTime.now());
  void _goToPreviousDay() => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
  void _goToNextDay() => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  List<Event> _getFilteredEvents() => _events.where((e) => _isSameDay(e.dateTime, _selectedDate)).toList();

  int _getUpcomingCount() => _events.where((e) => e.dateTime.isAfter(DateTime.now()) && e.dateTime.isBefore(DateTime.now().add(const Duration(hours: 24)))).length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final dayEvents = _getFilteredEvents();
    final upcomingCount = _getUpcomingCount();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isToday, isDark),
            _buildQuickStats(upcomingCount, isDark),
            _buildMiniCalendarStrip(isDark),
            Expanded(child: _buildEventsList(dayEvents, isDark)),
          ],
        ),
      ),
      floatingActionButton: RotationTransition(
        turns: _fabRotateAnim,
        child: ScaleTransition(
          scale: _fabScaleAnim,
          child: FloatingActionButton.extended(
            onPressed: _showAddEventSheet,
            backgroundColor: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
            elevation: 8,
            icon: const Icon(Icons.add_rounded, size: 28),
            label: const Text('New Event', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
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
          colors: isDark 
              ? [const Color(0xFF1E1E1E), const Color(0xFF2D2D2D)]
              : [Colors.white, const Color(0xFFF8F9FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem('Upcoming', '$upcomingCount', Icons.schedule, const Color(0xFF1A73E8), isDark),
          Container(width: 1, height: 40, color: isDark ? Colors.grey[800] : Colors.grey[200], margin: const EdgeInsets.symmetric(horizontal: 16)),
          _buildStatItem('Total Events', '${_events.length}', Icons.event_note, const Color(0xFF34A853), isDark),
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
    final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    
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
                final isToday = _isSameDay(date, today);
                
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
    if (dayEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) => Transform.scale(scale: value, child: child),
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(Icons.event_available_rounded, size: 60, color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8)),
              ),
            ),
            const SizedBox(height: 24),
            Text('No events scheduled', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF202124))),
            const SizedBox(height: 8),
            Text('Tap the button below to add one', style: TextStyle(fontSize: 15, color: isDark ? Colors.grey[400] : Colors.grey[600])),
            const SizedBox(height: 100),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      itemCount: dayEvents.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8), borderRadius: BorderRadius.circular(20)),
                  child: Text('${dayEvents.length} event${dayEvents.length > 1 ? 's' : ''}',
                    style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _navigateToWeekView,
                  icon: Icon(Icons.calendar_view_week, color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8)),
                  label: Text('Week View', style: TextStyle(color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8))),
                ),
                TextButton.icon(
                  onPressed: _navigateToMonthView,
                  icon: Icon(Icons.calendar_month, color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8)),
                  label: Text('Month', style: TextStyle(color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8))),
                ),
              ],
            ),
          );
        }
        
        final event = dayEvents[index - 1];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Transform.translate(offset: Offset(50 * (1 - value), 0), child: Opacity(opacity: value, child: child)),
          child: Padding(padding: const EdgeInsets.only(bottom: 12), child: EventCard(event: event, onDelete: () => _deleteEvent(event.id), isDark: isDark)),
        );
      },
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
