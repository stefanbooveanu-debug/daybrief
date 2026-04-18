import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';
import '../models/event.dart';

class TimeReportScreen extends StatelessWidget {
  final List<Event>? events;
  
  const TimeReportScreen({super.key, this.events});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final eventProvider = context.watch<EventProvider>();
    final eventList = eventProvider.events;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEvents = eventList.where((e) => e.dateTime.isAfter(weekStart)).toList();
    
    final categoryCount = <String, int>{};
    for (final e in weekEvents) {
      final cat = e.category ?? 'Other';
      categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
    }
    
    final sorted = categoryCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final colors = {
      'Work': const Color(0xFF1A73E8),
      'Personal': const Color(0xFF34A853),
      'Health': const Color(0xFFEA4335),
      'Social': const Color(0xFF9334E6),
      'Shopping': const Color(0xFFFBBC04),
      'Other': const Color(0xFF5F6368),
    };
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF5F6368)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Time Report', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF202124), fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSummaryCard(weekEvents.length, sorted.isNotEmpty ? sorted.first.key : 'None', isDark),
          const SizedBox(height: 24),
          Text('This Week by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF202124))),
          const SizedBox(height: 16),
          if (sorted.isEmpty)
            Center(child: Text('No events this week', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])))
          else
            ...sorted.map((entry) => _buildCategoryRow(entry.key, entry.value, weekEvents.length, colors[entry.key] ?? colors['Other']!, isDark)),
          const SizedBox(height: 24),
          Text('Daily Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF202124))),
          const SizedBox(height: 16),
          _buildDailyChart(weekEvents, isDark),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard(int totalEvents, String topCategory, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF8AB4F8), const Color(0xFF1A73E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF1A73E8).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Summary', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text('$totalEvents', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
          Text('events scheduled', style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 16),
          if (topCategory != 'None') ...[
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            Text('Top category: $topCategory', style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ],
      ),
    );
  }
  
  Widget _buildCategoryRow(String category, int count, int total, Color color, bool isDark) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(category, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF202124))),
            Text('$count events ($percentage%)', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: percentage / 100, backgroundColor: color.withOpacity(0.2), valueColor: AlwaysStoppedAnimation(color), minHeight: 8),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDailyChart(List<Event> weekEvents, bool isDark) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final dayDate = weekStart.add(Duration(days: index));
        final dayEvents = weekEvents.where((e) => e.dateTime.day == dayDate.day && e.dateTime.month == dayDate.month).length;
        final isToday = dayDate.day == now.day && dayDate.month == now.month;
        final maxHeight = 100.0;
        final barHeight = dayEvents > 0 ? (dayEvents / 5 * maxHeight).clamp(20.0, maxHeight) : 10.0;
        
        return Column(
          children: [
            Text('${dayEvents}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF202124))),
            const SizedBox(height: 8),
            Container(
              width: 30,
              height: barHeight,
              decoration: BoxDecoration(
                color: isToday ? const Color(0xFF1A73E8) : const Color(0xFF8AB4F8).withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Text(days[index], style: TextStyle(fontSize: 12, color: isToday ? const Color(0xFF1A73E8) : (isDark ? Colors.grey[400] : Colors.grey[600]), fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
          ],
        );
      }),
    );
  }
}
