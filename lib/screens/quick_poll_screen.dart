import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/auth_provider.dart';
import '../providers/poll_provider.dart';
import '../repositories/poll_repository.dart';
import '../utils/async_value.dart';

class QuickPollScreen extends StatefulWidget {
  const QuickPollScreen({super.key, this.pollId});

  final String? pollId;

  @override
  State<QuickPollScreen> createState() => _QuickPollScreenState();
}

class _QuickPollScreenState extends State<QuickPollScreen> {
  final _titleController = TextEditingController();
  final _nameController = TextEditingController();
  late List<DateTime> _optionTimes;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    final base = DateTime.now().add(const Duration(days: 1));
    _optionTimes = [
      DateTime(base.year, base.month, base.day, 10),
      DateTime(base.year, base.month, base.day, 14),
      DateTime(base.year, base.month, base.day, 18),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pollId = widget.pollId;
      if (pollId != null && pollId.isNotEmpty) {
        context.read<PollProvider>().watchPoll(pollId);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createPoll() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.isDemoMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in with a real account to create a poll'),
        ),
      );
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a meeting title')),
      );
      return;
    }

    setState(() => _creating = true);
    try {
      final pollId = await context.read<PollProvider>().createPoll(
            title: title,
            options: _optionTimes,
          );
      if (!mounted) return;
      context.go('/poll/$pollId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create poll: $e')),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _sharePoll(PollWithResults poll) async {
    await Share.share(
      'Vote on "${poll.title}" in DayBrief: /poll/${poll.id}'
      '${poll.shareCode != null ? ' (code ${poll.shareCode})' : ''}',
    );
  }

  Future<void> _showVoteDialog(PollOptionResult option) async {
    _nameController.clear();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
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
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, _nameController.text.trim()),
            child: const Text('Vote'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;

    try {
      await context.read<PollProvider>().castVote(
            optionId: option.id,
            voterName: name,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vote failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pollProvider = context.watch<PollProvider>();
    final hasPollId = widget.pollId != null && widget.pollId!.isNotEmpty;

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
        title: Text(
          'Quick Poll',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF202124),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (pollProvider.poll != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _sharePoll(pollProvider.poll!),
              tooltip: 'Share poll',
            ),
        ],
      ),
      body: hasPollId
          ? _buildPollBody(pollProvider, isDark)
          : _buildCreateBody(isDark),
    );
  }

  Widget _buildCreateBody(bool isDark) {
    return ListView(
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
              Text(
                'Create a Poll',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF202124),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Meeting title',
                  prefixIcon: Icon(
                    Icons.title,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF2D2D2D)
                      : const Color(0xFFF8F9FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF202124),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Suggested Times',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              ..._optionTimes.map(
                (time) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2D2D2D)
                        : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: isDark
                            ? const Color(0xFF8AB4F8)
                            : const Color(0xFF1A73E8),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          DateFormat('EEE, MMM d - h:mm a').format(time),
                          style: TextStyle(
                            color:
                                isDark ? Colors.white : const Color(0xFF202124),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _creating ? null : _createPoll,
                  child: Text(_creating ? 'Creating…' : 'Create Poll'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPollBody(PollProvider provider, bool isDark) {
    return switch (provider.state) {
      AsyncLoading() || AsyncIdle() => const Center(
          child: CircularProgressIndicator(),
        ),
      AsyncError(:final error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
      AsyncData(:final value) => value == null
          ? const Center(child: Text('Poll not found'))
          : ListView(
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
                      Text(
                        value.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : const Color(0xFF202124),
                        ),
                      ),
                      if (value.shareCode != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Share code: ${value.shareCode}',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Vote for a time',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...value.options.map(
                        (option) => _buildTimeOption(option, isDark),
                      ),
                    ],
                  ),
                ),
                if (value.options.any((o) => o.voteCount > 0)) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Results',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF202124),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...value.options.map(
                    (option) => _buildResultBar(option, value, isDark),
                  ),
                ],
              ],
            ),
    };
  }

  Widget _buildTimeOption(PollOptionResult option, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showVoteDialog(option),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                color:
                    isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  DateFormat('EEE, MMM d - h:mm a').format(option.time),
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF202124),
                  ),
                ),
              ),
              Icon(
                Icons.how_to_vote_outlined,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultBar(
    PollOptionResult option,
    PollWithResults poll,
    bool isDark,
  ) {
    final total = poll.options.fold<int>(0, (sum, o) => sum + o.voteCount);
    final percentage = total > 0 ? option.voteCount / total : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEE h:mm a').format(option.time),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF202124),
                ),
              ),
              Text(
                '${option.voteCount} vote${option.voteCount != 1 ? 's' : ''}',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor:
                  isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE8E8E8),
              valueColor: AlwaysStoppedAnimation(
                isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
              ),
              minHeight: 12,
            ),
          ),
          if (option.voters.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              option.voters.join(', '),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
