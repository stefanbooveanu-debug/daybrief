import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';

class FamilyCalendarScreen extends StatefulWidget {
  final Function(Event) onAddEvent;
  
  const FamilyCalendarScreen({super.key, required this.onAddEvent});

  @override
  State<FamilyCalendarScreen> createState() => _FamilyCalendarScreenState();
}

class _FamilyCalendarScreenState extends State<FamilyCalendarScreen> {
  final List<Map<String, dynamic>> _familyMembers = [
    {'name': 'Mom', 'avatar': '👩', 'color': const Color(0xFFE91E63)},
    {'name': 'Dad', 'avatar': '👨', 'color': const Color(0xFF2196F3)},
    {'name': 'Sister', 'avatar': '👧', 'color': const Color(0xFF9C27B0)},
  ];
  
  List<Event> _familyEvents = [
    Event(id: '1', title: 'Family Dinner', dateTime: DateTime.now().add(const Duration(days: 2, hours: 19)), description: 'Grandma coming over', category: 'Personal', userId: 'mom'),
    Event(id: '2', title: 'Movie Night', dateTime: DateTime.now().add(const Duration(days: 5, hours: 20)), description: 'New Marvel movie', category: 'Social', userId: 'sister'),
    Event(id: '3', title: 'Golf with Dad', dateTime: DateTime.now().add(const Duration(days: 7, hours: 9)), description: 'Sunday morning golf', category: 'Personal', userId: 'dad'),
  ];
  
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
        title: Text('Family Calendar', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF202124), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_outlined, color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8)),
            onPressed: _showAddMemberDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildFamilyHeader(isDark),
          const SizedBox(height: 24),
          Text('Upcoming Family Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF202124))),
          const SizedBox(height: 16),
          ..._familyEvents.map((e) => _buildFamilyEventCard(e, isDark)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFamilyEvent,
        backgroundColor: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
        icon: const Icon(Icons.add),
        label: const Text('Add Family Event'),
      ),
    );
  }
  
  Widget _buildFamilyHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFE91E63).withOpacity(0.8), const Color(0xFF2196F3).withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Family Members', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: _familyMembers.map((member) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: member['color'], width: 3),
                    ),
                    child: Center(child: Text(member['avatar'], style: const TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(height: 4),
                  Text(member['name'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFamilyEventCard(Event event, bool isDark) {
    final member = _familyMembers.firstWhere(
      (m) => m['name'].toString().toLowerCase() == _getMemberName(event.userId).toLowerCase(),
      orElse: () => _familyMembers.first,
    );
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: member['color'].withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: member['color'].withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(member['avatar'], style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(event.title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF202124))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: member['color'].withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(member['name'], style: TextStyle(fontSize: 10, color: member['color'], fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(DateFormat('EEE, MMM d - h:mm a').format(event.dateTime), style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                if (event.description != null) ...[
                  const SizedBox(height: 4),
                  Text(event.description!, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey[500])),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getMemberName(String userId) {
    final member = _familyMembers.where((m) => m['name'].toString().toLowerCase() == userId.toLowerCase()).firstOrNull;
    return member?['name'] ?? userId;
  }
  
  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Family Member'),
        content: const Text('Invite family members to share events'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Send Invite')),
        ],
      ),
    );
  }
  
  void _showAddFamilyEvent() {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add Family Event', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF202124))),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'Event title',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                            if (date != null) setModalState(() => selectedDate = date);
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(DateFormat('MMM d').format(selectedDate)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final time = await showTimePicker(context: context, initialTime: selectedTime);
                            if (time != null) setModalState(() => selectedTime = time);
                          },
                          icon: const Icon(Icons.access_time),
                          label: Text(selectedTime.format(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (titleController.text.trim().isNotEmpty) {
                          final event = Event(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            title: titleController.text.trim(),
                            dateTime: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute),
                            category: 'Personal',
                            userId: 'me',
                          );
                          setState(() => _familyEvents.add(event));
                          Navigator.pop(context);
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Add Event'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
