import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../services/claude_service.dart';
import '../theme/app_theme.dart';
import 'location_autocomplete_field.dart';

class AddEventSheet extends StatefulWidget {
  final DateTime? initialDate;

  const AddEventSheet({super.key, this.initialDate});

  @override
  State<AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<AddEventSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _aiInputController = TextEditingController();
  final _titleFocus = FocusNode();

  late TimeOfDay _selectedTime;
  late DateTime _selectedDate;
  bool _aiLoading = false;
  EventCategory _selectedCategory = EventCategory.other;
  bool _reminderEnabled = true;
  bool _showDetails = false;

  static const List<EventCategory> _categories = [
    EventCategory.work,
    EventCategory.personal,
    EventCategory.health,
    EventCategory.social,
    EventCategory.shopping,
    EventCategory.other,
  ];

  static const List<({String label, String hint, int hour, IconData icon})>
      _timePresets = [
    (label: 'Morning', hint: '9:00', hour: 9, icon: Icons.wb_sunny_outlined),
    (
      label: 'Afternoon',
      hint: '2:00',
      hour: 14,
      icon: Icons.wb_twilight_outlined
    ),
    (
      label: 'Evening',
      hint: '6:00',
      hour: 18,
      icon: Icons.nights_stay_outlined
    ),
    (label: 'Night', hint: '9:00', hour: 21, icon: Icons.bedtime_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _selectedTime = TimeOfDay.now();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _aiInputController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  Future<void> _parseWithAI() async {
    final text = _aiInputController.text.trim();
    if (text.isEmpty) return;

    setState(() => _aiLoading = true);

    final authProvider = context.read<AuthProvider>();
    final event = await ClaudeService.parseEventFromText(
      text,
      authProvider.userId ?? '',
    );

    if (!mounted) return;
    setState(() => _aiLoading = false);

    if (event == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not parse. Try: "Meeting tomorrow at 3pm"'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _titleController.text = event.title;
      if (event.description != null) {
        _descriptionController.text = event.description!;
        _showDetails = true;
      }
      if (event.category != null) {
        _selectedCategory = event.category!;
      }
      _selectedDate = event.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(event.dateTime);
      _aiInputController.clear();
    });

    await HapticFeedback.lightImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filled from “${event.title}”'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _addEvent() async {
    if (!_formKey.currentState!.validate()) {
      _titleFocus.requestFocus();
      return;
    }

    final eventProvider = context.read<EventProvider>();
    final authProvider = context.read<AuthProvider>();

    final eventDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final locationText = _locationController.text.trim();
    final descriptionText = _descriptionController.text.trim();
    final event = Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      dateTime: eventDateTime,
      description: descriptionText.isEmpty ? null : descriptionText,
      category: _selectedCategory,
      location: locationText.isEmpty ? null : locationText,
      reminderEnabled: _reminderEnabled,
      userId: authProvider.userId ?? '',
    );

    await eventProvider.addEvent(event);

    if (!mounted) return;
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added “${event.title}”'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final categoryColor = AppColors.colorForCategory(_selectedCategory);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outline.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Flexible(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                  shrinkWrap: true,
                  children: [
                    _Header(
                      dateLabel:
                          DateFormat('EEEE, MMM d').format(_selectedDate),
                      onClose: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 18),
                    if (ClaudeService.isSupportedOnPlatform) ...[
                      _AiComposer(
                        controller: _aiInputController,
                        loading: _aiLoading,
                        onSubmit: _parseWithAI,
                      ),
                      const SizedBox(height: 22),
                    ],
                    TextFormField(
                      controller: _titleController,
                      focusNode: _titleFocus,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        height: 1.15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'What’s happening?',
                        hintStyle: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                          color: scheme.onSurface.withValues(alpha: 0.28),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        errorStyle: TextStyle(color: scheme.error),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Give it a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'CATEGORY',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _CategoryPicker(
                      categories: _categories,
                      selected: _selectedCategory,
                      onSelected: (c) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCategory = c);
                      },
                    ),
                    const SizedBox(height: 22),
                    _WhenCard(
                      dateLabel: DateFormat('EEE, MMM d').format(_selectedDate),
                      timeLabel: _selectedTime.format(context),
                      accent: categoryColor,
                      onPickDate: _selectDate,
                      onPickTime: _selectTime,
                      presets: _timePresets,
                      selectedHour: _selectedTime.hour,
                      selectedMinute: _selectedTime.minute,
                      onPreset: (hour) {
                        HapticFeedback.selectionClick();
                        setState(
                          () =>
                              _selectedTime = TimeOfDay(hour: hour, minute: 0),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _ReminderTile(
                      enabled: _reminderEnabled,
                      accent: categoryColor,
                      onChanged: (v) => setState(() => _reminderEnabled = v),
                    ),
                    const SizedBox(height: 8),
                    _DetailsToggle(
                      expanded: _showDetails,
                      onToggle: () =>
                          setState(() => _showDetails = !_showDetails),
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 2,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: 'Notes',
                                hintText: 'Anything to remember…',
                                prefixIcon: Icon(Icons.notes_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            LocationAutocompleteField(
                              controller: _locationController,
                            ),
                          ],
                        ),
                      ),
                      crossFadeState: _showDetails
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 220),
                      sizeCurve: Curves.easeOutCubic,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                child: FilledButton(
                  onPressed: _addEvent,
                  style: FilledButton.styleFrom(
                    backgroundColor: categoryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Add to calendar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.dateLabel, required this.onClose});

  final String dateLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New event',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onClose,
          style: IconButton.styleFrom(
            backgroundColor: scheme.surfaceContainerHighest,
            foregroundColor: scheme.onSurface.withValues(alpha: 0.7),
          ),
          icon: const Icon(Icons.close_rounded, size: 20),
          tooltip: 'Close',
        ),
      ],
    );
  }
}

class _AiComposer extends StatelessWidget {
  const _AiComposer({
    required this.controller,
    required this.loading,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ink = isDark ? const Color(0xFF1A1410) : const Color(0xFF2C2118);
    final glow = isDark ? const Color(0xFFE8C39A) : const Color(0xFFD4A574);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: ink,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: glow.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: glow.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.auto_awesome, size: 15, color: glow),
              ),
              const SizedBox(width: 8),
              Text(
                'Describe it',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'AI fills the form',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.42),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: glow,
                  decoration: InputDecoration(
                    hintText: 'Lunch with Sam Friday at noon',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onSubmitted: (_) => onSubmit(),
                  textInputAction: TextInputAction.send,
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: glow,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: loading ? null : onSubmit,
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Center(
                      child: loading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: ink,
                              ),
                            )
                          : Icon(
                              Icons.arrow_upward_rounded,
                              color: ink,
                              size: 22,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<EventCategory> categories;
  final EventCategory selected;
  final ValueChanged<EventCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selected == category;
          final color = AppColors.colorForCategory(category);
          final scheme = Theme.of(context).colorScheme;

          return Semantics(
            button: true,
            selected: isSelected,
            label: category.displayName,
            child: InkWell(
              onTap: () => onSelected(category),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.14)
                      : scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? color.withValues(alpha: 0.55)
                        : scheme.outline.withValues(alpha: 0.25),
                    width: isSelected ? 1.4 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isSelected ? color : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        AppColors.iconForCategory(category),
                        size: 18,
                        color: isSelected
                            ? Colors.white
                            : scheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      category.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? color
                            : scheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WhenCard extends StatelessWidget {
  const _WhenCard({
    required this.dateLabel,
    required this.timeLabel,
    required this.accent,
    required this.onPickDate,
    required this.onPickTime,
    required this.presets,
    required this.selectedHour,
    required this.selectedMinute,
    required this.onPreset,
  });

  final String dateLabel;
  final String timeLabel;
  final Color accent;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final List<({String label, String hint, int hour, IconData icon})> presets;
  final int selectedHour;
  final int selectedMinute;
  final ValueChanged<int> onPreset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _WhenTile(
                  label: 'Date',
                  value: dateLabel,
                  icon: Icons.calendar_today_rounded,
                  accent: accent,
                  onTap: onPickDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WhenTile(
                  label: 'Time',
                  value: timeLabel,
                  icon: Icons.schedule_rounded,
                  accent: accent,
                  onTap: onPickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < presets.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _TimePresetButton(
                    label: presets[i].label,
                    icon: presets[i].icon,
                    selected:
                        selectedHour == presets[i].hour && selectedMinute == 0,
                    accent: accent,
                    onTap: () => onPreset(presets[i].hour),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WhenTile extends StatelessWidget {
  const _WhenTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
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
}

class _TimePresetButton extends StatelessWidget {
  const _TimePresetButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? accent : scheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? Colors.white
                    : scheme.onSurface.withValues(alpha: 0.55),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.enabled,
    required this.accent,
    required this.onChanged,
  });

  final bool enabled;
  final Color accent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
        child: Row(
          children: [
            Icon(
              enabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_outlined,
              size: 20,
              color:
                  enabled ? accent : scheme.onSurface.withValues(alpha: 0.45),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reminder',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '1 hour before',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: enabled,
              activeColor: accent,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsToggle extends StatelessWidget {
  const _DetailsToggle({required this.expanded, required this.onToggle});

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TextButton(
      onPressed: onToggle,
      style: TextButton.styleFrom(
        foregroundColor: scheme.onSurface.withValues(alpha: 0.65),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            expanded ? 'Hide notes & location' : 'Add notes & location',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          AnimatedRotation(
            turns: expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.expand_more_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}
