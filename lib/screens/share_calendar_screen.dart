import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';

class ShareCalendarScreen extends StatefulWidget {
  final List<Event>? events;
  
  const ShareCalendarScreen({super.key, this.events});

  @override
  State<ShareCalendarScreen> createState() => _ShareCalendarScreenState();
}

class _ShareCalendarScreenState extends State<ShareCalendarScreen> {
  String _shareCode = '';
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _generateShareCode();
  }
  
  void _generateShareCode() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      final code = DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase();
      setState(() {
        _shareCode = code;
        _isLoading = false;
      });
    });
  }
  
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
        title: Text('Share Calendar', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF202124), fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                    ? [const Color(0xFF2D2D2D), const Color(0xFF1E1E1E)]
                    : [Colors.white, const Color(0xFFF8F9FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              children: [
                Icon(Icons.share_rounded, size: 48, color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8)),
                const SizedBox(height: 16),
                Text('Your Share Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF202124))),
                const SizedBox(height: 8),
                Text('Share this code with others to let them view your calendar', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
                const SizedBox(height: 24),
                if (_isLoading)
                  CircularProgressIndicator(color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8))
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: (isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8)).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8), width: 2),
                    ),
                    child: Text(_shareCode, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 4, color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8))),
                  ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _generateShareCode,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Generate New Code'),
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('Upcoming Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF202124))),
          const SizedBox(height: 16),
          if ((widget.events ?? []).isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: Text('No events to share', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]))),
            )
          else
            ...(widget.events ?? []).take(5).map((e) => _buildEventTile(e, isDark)),
        ],
      ),
    );
  }
  
  Widget _buildEventTile(Event event, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: _getCategoryColor(event.category),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF202124))),
                Text(DateFormat('MMM d, h:mm a').format(event.dateTime), style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'Work': return const Color(0xFF1A73E8);
      case 'Personal': return const Color(0xFF34A853);
      case 'Health': return const Color(0xFFEA4335);
      case 'Social': return const Color(0xFF9334E6);
      case 'Shopping': return const Color(0xFFFBBC04);
      default: return const Color(0xFF5F6368);
    }
  }
}
