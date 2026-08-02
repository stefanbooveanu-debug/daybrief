import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app/app_scope.dart';
import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Map<EventCategory, Color> _categoryColors;
  bool _categoryColorsHydrated = false;

  @override
  void initState() {
    super.initState();
    _categoryColors = Map<EventCategory, Color>.from(
      AppColors.defaultCategoryColors,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_categoryColorsHydrated) {
      final fromScope = AppScope.of(context).categoryColors;
      _categoryColors = Map<EventCategory, Color>.from(fromScope);
      _categoryColorsHydrated = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppScope.of(context).isDarkMode;
    final settings = context.watch<SettingsProvider>();
    final accent = isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8);
    final scaffoldBg =
        isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF202124);
    final subColor = isDark ? const Color(0xFFB0B0B0) : const Color(0xFF5F6368);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: cardBg,
        foregroundColor: titleColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: titleColor),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            clipBehavior: Clip.none,
            children: [
              _buildSection(
                'Appearance',
                [
                  _buildSwitchTile(
                    'Dark Mode',
                    'Save battery & easy on eyes',
                    Icons.dark_mode_outlined,
                    isDark,
                    (value) => AppScope.of(context).onThemeChanged(value),
                    isDark: isDark,
                  ),
                  _buildNavTile(
                    'Language',
                    settings.localeCode == 'ro' ? 'Română' : 'English',
                    Icons.language_outlined,
                    () => _showLanguagePicker(settings),
                    isDark,
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
                    settings.notifications,
                    settings.setNotifications,
                    isDark: isDark,
                  ),
                  _buildSwitchTile(
                    'Daily Summary',
                    'Morning schedule summary',
                    Icons.summarize_outlined,
                    settings.dailySummary,
                    settings.setDailySummary,
                    isDark: isDark,
                  ),
                  _buildSwitchTile(
                    'Smart Snooze',
                    'Snooze to next free slot',
                    Icons.snooze_outlined,
                    settings.smartSnooze,
                    settings.setSmartSnooze,
                    isDark: isDark,
                  ),
                  _buildSwitchTile(
                    'Conflict Detection',
                    'Warn when events overlap',
                    Icons.warning_amber_outlined,
                    settings.conflictDetection,
                    settings.setConflictDetection,
                    isDark: isDark,
                  ),
                  _buildTimeTile(
                    'Morning Briefing',
                    settings.morningBriefing.label,
                    Icons.alarm_outlined,
                    isDark,
                    settings,
                  ),
                ],
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Calendar & Sync',
                [
                  _buildNavTile(
                    'Sync',
                    'Import, export, and Google Calendar',
                    Icons.sync_outlined,
                    () => context.push('/calendar-sync'),
                    isDark,
                  ),
                ],
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Analytics',
                [
                  _buildNavTile('Time Report', 'Weekly time analysis',
                      Icons.pie_chart_outline, () {
                    context.push('/time-report');
                  }, isDark),
                ],
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Collaboration',
                [
                  _buildNavTile(
                      'Share Calendar',
                      'Let others view your schedule',
                      Icons.share_outlined, () {
                    context.push('/share');
                  }, isDark),
                  _buildNavTile('Quick Poll', 'Find the best meeting time',
                      Icons.how_to_vote_outlined, () {
                    context.push('/poll');
                  }, isDark),
                  _buildNavTile('Family Calendar', 'Shared family events',
                      Icons.family_restroom_outlined, () {
                    context.push('/family');
                  }, isDark),
                  _buildNavTile('Driving Mode', 'Voice-only safe mode',
                      Icons.directions_car_outlined, () {
                    context.push('/driving');
                  }, isDark),
                ],
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Voice Assistant',
                [
                  _buildNavTile(
                    'Voice Templates',
                    'Quick phrases for common events',
                    Icons.record_voice_over_outlined,
                    () => context.push('/voice-templates'),
                    isDark,
                  ),
                  _buildSwitchTile(
                    'Voice Commands',
                    'Say "Hey DayBrief" to activate',
                    Icons.mic_outlined,
                    settings.voiceAssistant,
                    settings.setVoiceAssistant,
                    isDark: isDark,
                  ),
                  _buildSwitchTile(
                    'Sound Effects',
                    'Play sounds for actions',
                    Icons.volume_up_outlined,
                    settings.soundEffects,
                    settings.setSoundEffects,
                    isDark: isDark,
                  ),
                  _buildSwitchTile(
                    'Haptic Feedback',
                    'Vibrate on interactions',
                    Icons.vibration,
                    settings.hapticFeedback,
                    settings.setHapticFeedback,
                    isDark: isDark,
                  ),
                ],
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Account',
                [
                  _buildNavTile(
                    'Sign Out',
                    'Return to the login screen',
                    Icons.logout,
                    () async {
                      await context.read<AuthProvider>().signOut();
                      if (context.mounted) context.go('/auth');
                    },
                    isDark,
                  ),
                ],
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Category Colors',
                [
                  for (final category in EventCategory.values)
                    if (category != EventCategory.other)
                      _buildColorTile(
                        category,
                        _categoryColors[category]!,
                        AppColors.getCategoryIcon(category),
                        isDark,
                      ),
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
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        size: 40,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'DayBrief',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your daily schedule assistant',
                      style: TextStyle(color: subColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children,
      {required bool isDark}) {
    final accent = isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 10),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: accent,
            ),
          ),
        ),
        Material(
          color: cardBg,
          elevation: isDark ? 0 : 1,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildNavTile(String title, String subtitle, IconData icon,
      VoidCallback onTap, bool isDark) {
    final accent = isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8);
    final titleColor = isDark ? Colors.white : const Color(0xFF202124);
    final subColor = isDark ? const Color(0xFFB0B0B0) : const Color(0xFF5F6368);
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: accent, size: 22),
      ),
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.w600, color: titleColor)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: subColor)),
      trailing: Icon(Icons.chevron_right, color: subColor),
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
    final accent = isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8);
    final titleColor = isDark ? Colors.white : const Color(0xFF202124);
    final subColor = isDark ? const Color(0xFFB0B0B0) : const Color(0xFF5F6368);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: accent, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: titleColor),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: subColor),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: accent,
        activeColor: Colors.white,
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

  Future<void> _showLanguagePicker(SettingsProvider settings) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Language'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'en'),
            child: const Text('English'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'ro'),
            child: const Text('Română'),
          ),
        ],
      ),
    );
    if (selected != null) {
      await settings.setLocaleCode(selected);
    }
  }

  Widget _buildTimeTile(
    String title,
    String value,
    IconData icon,
    bool isDark,
    SettingsProvider settings,
  ) {
    return ListTile(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: settings.morningBriefing.hour,
            minute: settings.morningBriefing.minute,
          ),
        );
        if (time != null) {
          await settings.setMorningBriefing(
            TimeOfDayMinutes(hour: time.hour, minute: time.minute),
          );
        }
      },
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8))
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
            size: 22),
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

  Widget _buildColorTile(
    EventCategory category,
    Color color,
    IconData icon,
    bool isDark,
  ) {
    return ListTile(
      onTap: () => _showColorPicker(category, color),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        category.displayName,
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

  void _showColorPicker(EventCategory category, Color currentColor) {
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
            title: Text('Choose color for ${category.displayName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: colors
                      .map((c) => GestureDetector(
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
                                    : Border.all(
                                        color:
                                            Colors.grey.withValues(alpha: 0.3)),
                                boxShadow: c == selectedColor
                                    ? [
                                        BoxShadow(
                                            color: c.withValues(alpha: 0.5),
                                            blurRadius: 8)
                                      ]
                                    : null,
                              ),
                              child: c == selectedColor
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 24)
                                  : null,
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2D2D2D)
                        : const Color(0xFFF1F3F4),
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
                          color:
                              isDark ? Colors.white : const Color(0xFF202124),
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
                child: Text('Cancel',
                    style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ),
              FilledButton(
                onPressed: () {
                  setState(() => _categoryColors[category] = selectedColor);
                  AppScope.of(context)
                      .onCategoryColorsChanged(Map.from(_categoryColors));
                  Navigator.pop(dialogContext);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF8AB4F8)
                      : const Color(0xFF1A73E8),
                ),
                child: const Text('Save',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }
}
