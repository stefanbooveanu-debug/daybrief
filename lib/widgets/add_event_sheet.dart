import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';
import '../providers/auth_provider.dart';
import '../services/claude_service.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';

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
  late TimeOfDay _selectedTime;
  late DateTime _selectedDate;
  bool _aiLoading = false;
  EventCategory _selectedCategory = EventCategory.other;
  bool _reminderEnabled = true;

  static const List<EventCategory> _categories = [
    EventCategory.work,
    EventCategory.personal,
    EventCategory.health,
    EventCategory.social,
    EventCategory.shopping,
    EventCategory.other,
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
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Auto-fill the form with parsed data
    setState(() {
      _titleController.text = event.title;
      if (event.description != null) {
        _descriptionController.text = event.description!;
      }
      if (event.category != null) {
        _selectedCategory = event.category!;
      }
      _selectedDate = event.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(event.dateTime);
      _aiInputController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✨ AI parsed: "${event.title}"'),
        backgroundColor: const Color(0xFF9334E6),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A73E8),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A73E8),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _quickTimeChip(String label, int hour) {
    final time = TimeOfDay(hour: hour, minute: 0);
    final isSelected = _selectedTime.hour == hour && _selectedTime.minute == 0;
    return ActionChip(
      label: Text(label),
      avatar: Icon(
        Icons.schedule,
        size: 16,
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      backgroundColor: isSelected
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface,
      ),
      onPressed: () => setState(() => _selectedTime = time),
    );
  }

  Future<void> _addEvent() async {
    if (!_formKey.currentState!.validate()) return;

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

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${event.title}"'),
          backgroundColor: const Color(0xFF1A73E8),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2A1A0A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF202124);
    final subtextColor = isDark ? Colors.grey[400]! : const Color(0xFF5F6368);
    final fieldBg = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'New Event',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: subtextColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (ClaudeService.isSupportedOnPlatform)
                Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9334E6), Color(0xFF1A73E8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'AI Quick Add',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _aiInputController,
                              cursorColor: Colors.white,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                              decoration: const InputDecoration(
                                hintText: '"Meeting tomorrow at 3pm"',
                                hintStyle: TextStyle(color: Colors.white70, fontSize: 13),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                              onSubmitted: (_) => _parseWithAI(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: _aiLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send, color: Colors.white, size: 20),
                          onPressed: _aiLoading ? null : _parseWithAI,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (ClaudeService.isSupportedOnPlatform) const SizedBox(height: 16),
              Text(
                'Category',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: subtextColor,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final name = category.displayName;
                    final isSelected = _selectedCategory == category;
                    final color = AppColors.colorForCategory(category);
                    return ChoiceChip(
                      label: Text(name),
                      avatar: Icon(
                        AppColors.iconForCategory(category),
                        size: 16,
                        color: isSelected ? Colors.white : color,
                      ),
                      selected: isSelected,
                      selectedColor: color,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : textColor,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Event title',
                  hintText: 'e.g., Barber shop',
                  prefixIcon: const Icon(Icons.event, color: Color(0xFF5F6368)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: fieldBg,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an event title';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date',
                          prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF5F6368)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: fieldBg,
                        ),
                        child: Text(
                          DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectTime,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Time',
                    prefixIcon: const Icon(Icons.access_time, color: Color(0xFF5F6368)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: fieldBg,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedTime.format(context),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Color(0xFF5F6368)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _quickTimeChip('Morning', 9),
                  _quickTimeChip('Afternoon', 14),
                  _quickTimeChip('Evening', 18),
                  _quickTimeChip('Night', 21),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Add notes...',
                  prefixIcon: const Icon(Icons.notes, color: Color(0xFF5F6368)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: fieldBg,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location (optional)',
                  hintText: 'Where is it?',
                  prefixIcon: const Icon(
                    Icons.place_outlined,
                    color: Color(0xFF5F6368),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: fieldBg,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _reminderEnabled,
                onChanged: (v) => setState(() => _reminderEnabled = v),
                title: Text(
                  'Reminder',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                subtitle: Text(
                  'Notify me 1 hour before',
                  style: TextStyle(fontSize: 12, color: subtextColor),
                ),
                secondary: Icon(
                  Icons.notifications_active_outlined,
                  color: subtextColor,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _addEvent,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
