import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../services/share_calendar_service.dart';
import '../theme/app_theme.dart';

class ShareCalendarScreen extends StatefulWidget {
  const ShareCalendarScreen({super.key});

  @override
  State<ShareCalendarScreen> createState() => _ShareCalendarScreenState();
}

class _ShareCalendarScreenState extends State<ShareCalendarScreen> {
  String? _shareCode;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_generateShareCode());
    });
  }

  Future<void> _generateShareCode() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.isDemoMode) {
      setState(() {
        _error = 'Sign in with a real account to share your calendar.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = context.read<ShareCalendarService>();
      final previous = _shareCode;
      if (previous != null && previous.isNotEmpty) {
        try {
          await service.revokeShareCode(previous);
        } catch (_) {
          // Best-effort revoke of previous code.
        }
      }
      final code = await service.createShareCode();
      if (!mounted) return;
      setState(() {
        _shareCode = code;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _shareLink() async {
    final code = _shareCode;
    if (code == null || code.isEmpty) return;
    await Share.share(
      'View my DayBrief calendar with code $code (open /shared/$code)',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final events = context.watch<EventProvider>().events;

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
          'Share Calendar',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF202124),
            fontWeight: FontWeight.bold,
          ),
        ),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.share_rounded,
                  size: 48,
                  color: isDark
                      ? const Color(0xFF8AB4F8)
                      : const Color(0xFF1A73E8),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your Share Code',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF202124),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share this code so others can view your upcoming events',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  CircularProgressIndicator(
                    color: isDark
                        ? const Color(0xFF8AB4F8)
                        : const Color(0xFF1A73E8),
                  )
                else if (_error != null)
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red[300]),
                  )
                else if (_shareCode != null)
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? const Color(0xFF8AB4F8)
                                  : const Color(0xFF1A73E8))
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF8AB4F8)
                                : const Color(0xFF1A73E8),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          _shareCode!,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: isDark
                                ? const Color(0xFF8AB4F8)
                                : const Color(0xFF1A73E8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await Clipboard.setData(
                                ClipboardData(text: _shareCode!),
                              );
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Code copied')),
                              );
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy'),
                          ),
                          TextButton.icon(
                            onPressed: _shareLink,
                            icon: const Icon(Icons.ios_share),
                            label: const Text('Share'),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                context.push('/shared/${_shareCode!}'),
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text('Preview'),
                          ),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _generateShareCode,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Generate New Code'),
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF8AB4F8)
                        : const Color(0xFF1A73E8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Upcoming Events',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF202124),
            ),
          ),
          const SizedBox(height: 16),
          if (events.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  'No events to share',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            ...events.take(5).map((e) => _buildEventTile(e, isDark)),
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
                Text(
                  event.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF202124),
                  ),
                ),
                Text(
                  DateFormat('MMM d, h:mm a').format(event.dateTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(EventCategory? category) {
    return Theme.of(context).extension<CategoryColors>()?.colorForCategory(
              category,
            ) ??
        AppColors.colorForCategory(category);
  }
}
