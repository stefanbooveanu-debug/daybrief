import 'package:flutter/material.dart';
import 'time_report_screen.dart';
import 'share_calendar_screen.dart';
import 'quick_poll_screen.dart';
import 'family_calendar_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool)? onThemeChanged;
  final Function(Map<String, Color>)? onColorsChanged;
  final Map<String, Color> categoryColors;
  final bool isDarkMode;
  
  const SettingsScreen({
    super.key,
    this.onThemeChanged,
    this.onColorsChanged,
    required this.categoryColors,
    required this.isDarkMode,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _dailySummary = true;
  bool _voiceAssistant = true;
  bool _soundEffects = true;
  bool _hapticFeedback = true;
  bool _smartSnooze = true;
  bool _conflictDetection = true;
  TimeOfDay _morningBriefing = const TimeOfDay(hour: 7, minute: 0);
  
  late Map<String, Color> _categoryColors;

  @override
  void initState() {
    super.initState();
    _categoryColors = Map.from(widget.categoryColors);
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF5F6368)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF202124),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSection(
            'Appearance',
            [
              _buildSwitchTile(
                'Dark Mode',
                'Save battery & easy on eyes',
                Icons.dark_mode_outlined,
                isDark,
                (value) {
                  setState(() {
                    widget.onThemeChanged?.call(value);
                  });
                  widget.onThemeChanged?.call(value);
                },
                isDark: isDark,
              ),
            ],
            isDark: isDark,
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Notifications',
            [
              _buildSwitchTile(
                'Event Reminders',
                'Get notified before events',
                Icons.notifications_outlined,
                _notifications,
                (value) => setState(() => _notifications = value),
                isDark: isDark,
              ),
              _buildSwitchTile(
                'Daily Summary',
                'Morning schedule summary',
                Icons.summarize_outlined,
                _dailySummary,
                (value) => setState(() => _dailySummary = value),
                isDark: isDark,
              ),
              _buildSwitchTile(
                'Smart Snooze',
                'Snooze to next free slot',
                Icons.snooze_outlined,
                _smartSnooze,
                (value) => setState(() => _smartSnooze = value),
                isDark: isDark,
              ),
              _buildSwitchTile(
                'Conflict Detection',
                'Warn when events overlap',
                Icons.warning_amber_outlined,
                _conflictDetection,
                (value) => setState(() => _conflictDetection = value),
                isDark: isDark,
              ),
              _buildTimeTile('Morning Briefing', '${_morningBriefing.hour}:${_morningBriefing.minute.toString().padLeft(2, '0')}', Icons.alarm_outlined, isDark),
            ],
            isDark: isDark,
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Analytics',
            [
              _buildNavTile('Time Report', 'Weekly time analysis', Icons.pie_chart_outline, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const TimeReportScreen(events: [])));
              }, isDark),
              _buildSwitchTile(
                'Smart Shortcuts',
                'Learn your patterns',
                Icons.auto_awesome_outlined,
                true,
                (value) {},
                isDark: isDark,
              ),
            ],
            isDark: isDark,
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Collaboration',
            [
              _buildNavTile('Share Calendar', 'Let others view your schedule', Icons.share_outlined, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => ShareCalendarScreen(events: [])));
              }, isDark),
              _buildNavTile('Quick Poll', 'Find the best meeting time', Icons.how_to_vote_outlined, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const QuickPollScreen()));
              }, isDark),
              _buildNavTile('Family Calendar', 'Shared family events', Icons.family_restroom_outlined, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => FamilyCalendarScreen(onAddEvent: (e) {})));
              }, isDark),
            ],
            isDark: isDark,
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Voice Assistant',
            [
              _buildSwitchTile(
                'Voice Commands',
                'Say "Hey DayBrief" to activate',
                Icons.mic_outlined,
                _voiceAssistant,
                (value) => setState(() => _voiceAssistant = value),
                isDark: isDark,
              ),
              _buildSwitchTile(
                'Sound Effects',
                'Play sounds for actions',
                Icons.volume_up_outlined,
                _soundEffects,
                (value) => setState(() => _soundEffects = value),
                isDark: isDark,
              ),
              _buildSwitchTile(
                'Haptic Feedback',
                'Vibrate on interactions',
                Icons.vibration,
                _hapticFeedback,
                (value) => setState(() => _hapticFeedback = value),
                isDark: isDark,
              ),
            ],
            isDark: isDark,
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Category Colors',
            [
              _buildColorTile('Work', _categoryColors['Work']!, Icons.work_outline, isDark),
              _buildColorTile('Personal', _categoryColors['Personal']!, Icons.person_outline, isDark),
              _buildColorTile('Health', _categoryColors['Health']!, Icons.favorite_outline, isDark),
              _buildColorTile('Social', _categoryColors['Social']!, Icons.people_outline, isDark),
              _buildColorTile('Shopping', _categoryColors['Shopping']!, Icons.shopping_cart_outlined, isDark),
            ],
            isDark: isDark,
          ),
          const SizedBox(height: 24),
          _buildSection(
            'About',
            [
              _buildInfoTile('Version', '1.0.0', isDark),
              _buildInfoTile('Developer', 'DayBrief Team', isDark),
            ],
            isDark: isDark,
          ),
          const SizedBox(height: 48),
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF8AB4F8).withOpacity(0.2) : const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: 40,
                    color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'DayBrief',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF202124),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your daily schedule assistant',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, {required bool isDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark ? null : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildNavTile(String title, String subtitle, IconData icon, VoidCallback onTap, bool isDark) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8), size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF202124))),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600])),
      trailing: Icon(Icons.chevron_right, color: isDark ? Colors.grey[600] : Colors.grey[400]),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged, {
    required bool isDark,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8), size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF202124),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, bool isDark) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF202124),
        ),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildTimeTile(String title, String value, IconData icon, bool isDark) {
    return ListTile(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: _morningBriefing,
        );
        if (time != null) {
          setState(() => _morningBriefing = time);
        }
      },
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8), size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF202124),
        ),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildColorTile(String name, Color color, IconData icon, bool isDark) {
    return ListTile(
      onTap: () => _showColorPicker(name, color),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF202124),
        ),
      ),
      trailing: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 2),
        ),
      ),
    );
  }

  void _showColorPicker(String category, Color currentColor) {
    final colors = [
      const Color(0xFF1A73E8),
      const Color(0xFF34A853),
      const Color(0xFFEA4335),
      const Color(0xFF9334E6),
      const Color(0xFFFBBC04),
      const Color(0xFFFF6D00),
      const Color(0xFF00ACC1),
      const Color(0xFFE91E63),
      const Color(0xFF607D8B),
      const Color(0xFF795548),
    ];
    
    Color selectedColor = currentColor;
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            title: Text('Choose color for $category'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: colors.map((c) => GestureDetector(
                    onTap: () {
                      setDialogState(() => selectedColor = c);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: c == selectedColor 
                            ? Border.all(color: Colors.white, width: 3) 
                            : Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                        boxShadow: c == selectedColor 
                            ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8)] 
                            : null,
                      ),
                      child: c == selectedColor ? const Icon(Icons.check, color: Colors.white, size: 24) : null,
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF1F3F4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Selected',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF202124),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Cancel', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ),
              FilledButton(
                onPressed: () {
                  setState(() => _categoryColors[category] = selectedColor);
                  widget.onColorsChanged?.call(Map.from(_categoryColors));
                  Navigator.pop(dialogContext);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
                ),
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }
}
