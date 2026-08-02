import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';

class TimeReportScreen extends StatelessWidget {
  const TimeReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final eventProvider = context.watch<EventProvider>();
    final eventList = eventProvider.events;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEvents =
        eventList.where((e) => e.dateTime.isAfter(weekStart)).toList();

    final categoryCount = <EventCategory, int>{};
    for (final e in weekEvents) {
      final cat = e.category ?? EventCategory.other;
      categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
    }

    final sorted = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final categoryColors = Theme.of(context).extension<CategoryColors>();
    Color colorFor(EventCategory category) =>
        categoryColors?.colorForCategory(category) ??
        AppColors.getCategoryColor(category);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : const Color(0xFF5F6368)),
          onPressed: () => context.pop(),
        ),
        title: Text('Time Report',
            style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF202124),
                fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSummaryCard(
            weekEvents.length,
            sorted.isNotEmpty ? sorted.first.key.displayName : 'None',
            isDark,
          ),
          const SizedBox(height: 24),
          Text('This Week by Category',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF202124))),
          const SizedBox(height: 16),
          if (sorted.isEmpty)
            Center(
                child: Text('No events this week',
                    style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600])))
          else
            ...sorted.map((entry) => _buildCategoryRow(
                  entry.key.displayName,
                  entry.value,
                  weekEvents.length,
                  colorFor(entry.key),
                  isDark,
                )),
          const SizedBox(height: 24),
          Text('Daily Breakdown',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF202124))),
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
        gradient: const LinearGradient(
          colors: [Color(0xFF8AB4F8), Color(0xFF1A73E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A73E8).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Summary',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text('$totalEvents',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold)),
          Text('events this week',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
          const SizedBox(height: 12),
          Text('Most active: $topCategory',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
    String category,
    int count,
    int total,
    Color color,
    bool isDark,
  ) {
    final pct = total > 0 ? (count / total * 100).round() : 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(category,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF202124))),
          ),
          Text('$count ($pct%)',
              style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildDailyChart(List<Event> events, bool isDark) {
    final days = List.generate(7, (i) {
      final d = DateTime.now()
          .subtract(Duration(days: DateTime.now().weekday - 1 - i));
      return DateTime(d.year, d.month, d.day);
    });
    final counts = days.map((day) {
      return events
          .where((e) =>
              e.dateTime.year == day.year &&
              e.dateTime.month == day.month &&
              e.dateTime.day == day.day)
          .length;
    }).toList();
    final maxCount =
        counts.isEmpty ? 1 : counts.reduce((a, b) => a > b ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final height = maxCount > 0 ? (counts[i] / maxCount * 80) : 0.0;
        return Column(
          children: [
            Container(
              width: 24,
              height: height.clamp(4.0, 80.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1A73E8),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ],
        );
      }),
    );
  }
}
