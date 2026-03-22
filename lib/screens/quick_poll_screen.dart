import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class QuickPollScreen extends StatefulWidget {
  const QuickPollScreen({super.key});

  @override
  State<QuickPollScreen> createState() => _QuickPollScreenState();
}

class _QuickPollScreenState extends State<QuickPollScreen> {
  final _titleController = TextEditingController();
  final List<Map<String, dynamic>> _options = [
    {'time': DateTime.now().add(const Duration(days: 1)).copyWith(hour: 10, minute: 0), 'votes': 0, 'voters': <String>[]},
    {'time': DateTime.now().add(const Duration(days: 1)).copyWith(hour: 14, minute: 0), 'votes': 0, 'voters': <String>[]},
    {'time': DateTime.now().add(const Duration(days: 1)).copyWith(hour: 18, minute: 0), 'votes': 0, 'voters': <String>[]},
  ];
  final _nameController = TextEditingController();
  
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
        title: Text('Quick Poll', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF202124), fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create a Poll', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF202124))),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Meeting title',
                    prefixIcon: Icon(Icons.title, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF202124)),
                ),
                const SizedBox(height: 16),
                Text('Suggested Times', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.grey[300] : Colors.grey[700])),
                const SizedBox(height: 12),
                ..._options.asMap().entries.map((entry) => _buildTimeOption(entry.value, entry.key, isDark)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_options.any((o) => (o['votes'] as int) > 0)) ...[
            Text('Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF202124))),
            const SizedBox(height: 16),
            ..._options.asMap().entries.map((entry) => _buildResultBar(entry.value, entry.key, isDark)),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTimeOption(Map<String, dynamic> option, int index, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showVoteDialog(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time, color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  DateFormat('EEE, MMM d - h:mm a').format(option['time']),
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF202124)),
                ),
              ),
              Icon(Icons.how_to_vote_outlined, color: isDark ? Colors.grey[400] : Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildResultBar(Map<String, dynamic> option, int index, bool isDark) {
    final votes = option['votes'] as int;
    final total = _options.fold<int>(0, (sum, o) => sum + (o['votes'] as int));
    final percentage = total > 0 ? votes / total : 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('EEE h:mm a').format(option['time']), style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF202124))),
              Text('$votes vote${votes != 1 ? 's' : ''}', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE8E8E8),
              valueColor: AlwaysStoppedAnimation(isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8)),
              minHeight: 12,
            ),
          ),
          if ((option['voters'] as List).isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              (option['voters'] as List).join(', '),
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }
  
  void _showVoteDialog(int index) {
    _nameController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Vote for this time'),
        content: TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Your name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (_nameController.text.trim().isNotEmpty) {
                setState(() {
                  _options[index]['votes'] = (_options[index]['votes'] as int) + 1;
                  (_options[index]['voters'] as List).add(_nameController.text.trim());
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Vote'),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
