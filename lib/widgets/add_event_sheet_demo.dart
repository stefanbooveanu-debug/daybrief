import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';

class AddEventSheetDemo extends StatefulWidget {
  final Function(Event)? onEventAdded;
  final Map<String, Color>? categoryColors;

  const AddEventSheetDemo({super.key, this.onEventAdded, this.categoryColors});

  @override
  State<AddEventSheetDemo> createState() => _AddEventSheetDemoState();
}

class _AddEventSheetDemoState extends State<AddEventSheetDemo> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  late TimeOfDay _selectedTime;
  late DateTime _selectedDate;
  String _selectedCategory = 'Other';
  bool _reminderEnabled = true;
  late AnimationController _animController;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  List<Map<String, dynamic>> get _categories {
    final colors = widget.categoryColors ?? {};
    return [
      {'name': 'Work', 'icon': Icons.work_outline, 'color': colors['Work'] ?? const Color(0xFF1A73E8)},
      {'name': 'Personal', 'icon': Icons.person_outline, 'color': colors['Personal'] ?? const Color(0xFF34A853)},
      {'name': 'Health', 'icon': Icons.favorite_outline, 'color': colors['Health'] ?? const Color(0xFFEA4335)},
      {'name': 'Social', 'icon': Icons.people_outline, 'color': colors['Social'] ?? const Color(0xFF9334E6)},
      {'name': 'Shopping', 'icon': Icons.shopping_cart_outlined, 'color': colors['Shopping'] ?? const Color(0xFFFBBC04)},
      {'name': 'Other', 'icon': Icons.more_horiz, 'color': const Color(0xFF5F6368)},
    ];
  }

  @override
  void initState() {
    super.initState();
    _selectedTime = TimeOfDay.now();
    _selectedDate = DateTime.now();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime,
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF1A73E8))), child: child!));
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(context: context, initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF1A73E8))), child: child!));
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _addEvent() {
    if (!_formKey.currentState!.validate()) return;
    final event = Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      dateTime: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      category: _selectedCategory,
      reminderEnabled: _reminderEnabled,
      userId: 'demo-user',
    );
    widget.onEventAdded?.call(event);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          Text('Added "${event.title}"'),
        ]),
        backgroundColor: const Color(0xFF34A853),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 200 * _slideAnim.value),
          child: Opacity(opacity: _fadeAnim.value, child: child),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
                  decoration: BoxDecoration(color: isDark ? Colors.grey[700] : Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('New Event', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF202124))),
                    IconButton(icon: Icon(Icons.close, color: isDark ? Colors.white70 : const Color(0xFF5F6368)), onPressed: () => Navigator.pop(context)),
                  ]),
                  const SizedBox(height: 24),
                  TextFormField(controller: _titleController,
                    decoration: InputDecoration(hintText: 'What\'s happening?', prefixIcon: const Icon(Icons.edit_outlined, color: Color(0xFF1A73E8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true, fillColor: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF8F9FA)),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null, textCapitalization: TextCapitalization.sentences, autofocus: true),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _buildFieldCard(Icons.calendar_today_outlined, DateFormat('EEE, MMM d').format(_selectedDate), _selectDate, isDark)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildFieldCard(Icons.access_time_outlined, _selectedTime.format(context), _selectTime, isDark)),
                  ]),
                  const SizedBox(height: 16),
                  Text('Quick Times', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey[400] : const Color(0xFF5F6368), fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    ActionChip(label: const Text('Morning'), avatar: Icon(Icons.schedule, size: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      onPressed: () => setState(() => _selectedTime = const TimeOfDay(hour: 9, minute: 0)),
                      backgroundColor: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF1F3F4)),
                    ActionChip(label: const Text('Afternoon'), avatar: Icon(Icons.schedule, size: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      onPressed: () => setState(() => _selectedTime = const TimeOfDay(hour: 14, minute: 0)),
                      backgroundColor: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF1F3F4)),
                    ActionChip(label: const Text('Evening'), avatar: Icon(Icons.schedule, size: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      onPressed: () => setState(() => _selectedTime = const TimeOfDay(hour: 18, minute: 0)),
                      backgroundColor: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF1F3F4)),
                    ActionChip(label: const Text('Night'), avatar: Icon(Icons.schedule, size: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      onPressed: () => setState(() => _selectedTime = const TimeOfDay(hour: 21, minute: 0)),
                      backgroundColor: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF1F3F4)),
                  ]),
                  const SizedBox(height: 24),
                  Text('Category', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey[400] : const Color(0xFF5F6368), fontSize: 14)),
                  const SizedBox(height: 12),
                  SizedBox(height: 90, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _categories.length, itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat['name'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat['name'] as String),
                      child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 80, margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? (cat['color'] as Color).withOpacity(0.1) : (isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF8F9FA)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? cat['color'] as Color : Colors.transparent, width: 2)),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(cat['icon'] as IconData, color: isSelected ? cat['color'] as Color : (isDark ? Colors.white70 : const Color(0xFF5F6368))),
                          const SizedBox(height: 8),
                          Text(cat['name'] as String, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? cat['color'] as Color : (isDark ? Colors.white70 : const Color(0xFF5F6368)))),
                        ])),
                    );
                  })),
                  const SizedBox(height: 24),
                  TextFormField(controller: _locationController,
                    decoration: InputDecoration(hintText: 'Location (optional)', prefixIcon: Icon(Icons.location_on_outlined, color: isDark ? Colors.grey[400] : const Color(0xFF5F6368)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true, fillColor: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF8F9FA))),
                  const SizedBox(height: 16),
                  TextFormField(controller: _descriptionController,
                    decoration: InputDecoration(hintText: 'Notes (optional)', prefixIcon: Icon(Icons.notes_outlined, color: isDark ? Colors.grey[400] : const Color(0xFF5F6368)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true, fillColor: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF8F9FA)), maxLines: 2),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_active_outlined, color: (widget.categoryColors ?? {})['Work'] ?? const Color(0xFF1A73E8)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Smart Reminder', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF202124))),
                              Text('Get notified 1 hour before', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                            ],
                          ),
                        ),
                        Switch(
                          value: _reminderEnabled,
                          onChanged: (v) => setState(() => _reminderEnabled = v),
                          activeColor: (widget.categoryColors ?? {})['Work'] ?? const Color(0xFF1A73E8),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _addEvent,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8), 
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Create Event', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                ])),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldCard(IconData icon, String label, VoidCallback onTap, bool isDark) {
    return Material(color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
        child: Container(padding: const EdgeInsets.all(16), child: Row(children: [
          Icon(icon, color: const Color(0xFF1A73E8)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF202124)))),
          Icon(Icons.chevron_right, color: isDark ? Colors.grey[600] : Colors.grey[400]),
        ]))));
  }
}
