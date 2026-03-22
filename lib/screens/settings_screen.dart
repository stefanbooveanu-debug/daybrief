import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool)? onThemeChanged;
  
  const SettingsScreen({super.key, this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _voiceAssistant = true;
  bool _soundEffects = true;
  bool _hapticFeedback = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
                  widget.onThemeChanged?.call(value);
                  Navigator.pop(context);
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
                _notifications,
                (value) => setState(() => _notifications = value),
                isDark: isDark,
              ),
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
              _buildColorTile('Work', const Color(0xFF1A73E8), Icons.work_outline, isDark),
              _buildColorTile('Personal', const Color(0xFF34A853), Icons.person_outline, isDark),
              _buildColorTile('Health', const Color(0xFFEA4335), Icons.favorite_outline, isDark),
              _buildColorTile('Social', const Color(0xFF9334E6), Icons.people_outline, isDark),
              _buildColorTile('Shopping', const Color(0xFFFBBC04), Icons.shopping_cart_outlined, isDark),
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

  Widget _buildColorTile(String name, Color color, IconData icon, bool isDark) {
    return ListTile(
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
        ),
      ),
    );
  }
}
