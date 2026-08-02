import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/event_provider.dart';
import '../services/google_calendar_service.dart';

class CalendarSyncScreen extends StatefulWidget {
  const CalendarSyncScreen({super.key});

  @override
  State<CalendarSyncScreen> createState() => _CalendarSyncScreenState();
}

class _CalendarSyncScreenState extends State<CalendarSyncScreen> {
  final GoogleCalendarService _calendarService = GoogleCalendarService();
  bool _isLoading = false;
  String? _statusMessage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          'Calendar Sync',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF202124),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSyncOption(
            icon: Icons.upload_file,
            title: 'Export to ICS',
            subtitle: 'Save your events to a file',
            color: const Color(0xFF1A73E8),
            onTap: _exportToIcs,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildSyncOption(
            icon: Icons.download,
            title: 'Import from ICS',
            subtitle: 'Load events from a file',
            color: const Color(0xFF34A853),
            onTap: _importFromIcs,
            isDark: isDark,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.link,
                        color: isDark
                            ? const Color(0xFF8AB4F8)
                            : const Color(0xFF1A73E8)),
                    const SizedBox(width: 12),
                    Text(
                      'Google Calendar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF202124),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  kIsWeb
                      ? 'Connect works best on mobile/desktop builds. On web, use Export ICS for demos.'
                      : 'Push DayBrief events to your Google Calendar',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _connectGoogleCalendar,
                    icon: const Icon(Icons.cloud_sync_outlined),
                    label:
                        Text(kIsWeb ? 'Try Google Connect' : 'Connect & sync'),
                  ),
                ),
                if (_statusMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _statusMessage!,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF8AB4F8)
                          : const Color(0xFF1A73E8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_isLoading) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Widget _buildSyncOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF202124),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: isDark ? Colors.grey[600] : Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportToIcs() async {
    setState(() => _isLoading = true);

    try {
      final events = context.read<EventProvider>().events;
      final icsContent = _calendarService.generateIcsFile(events);
      final bytes = Uint8List.fromList(utf8.encode(icsContent));

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Calendar',
        fileName: 'daybrief_calendar.ics',
        type: FileType.custom,
        allowedExtensions: const ['ics'],
        bytes: bytes,
      );

      if (!mounted) return;
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calendar exported'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _importFromIcs() async {
    setState(() => _isLoading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['ics'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        throw Exception('Could not read file bytes on this platform');
      }

      final content = utf8.decode(bytes);
      final importedEvents = _calendarService.parseIcsEvents(content);

      if (!mounted) return;

      if (importedEvents.isNotEmpty) {
        final eventProvider = context.read<EventProvider>();
        for (final event in importedEvents) {
          await eventProvider.addEvent(event);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported ${importedEvents.length} events'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No events found in file'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _connectGoogleCalendar() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      if (kIsWeb) {
        setState(() {
          _statusMessage =
              'Google Connect on web needs OAuth web client setup. Use Export ICS for the demo.';
        });
        return;
      }

      final signedIn = await _calendarService.signIn();

      if (!mounted) return;

      if (signedIn && _calendarService.isConnected) {
        setState(() => _statusMessage = 'Connected! Syncing events...');

        var syncedCount = 0;
        final events = context.read<EventProvider>().events;
        for (final event in events) {
          final success = await _calendarService.syncEvent(event);
          if (success) syncedCount++;
        }

        if (!mounted) return;
        setState(() => _statusMessage = 'Synced $syncedCount events');
      } else {
        setState(() => _statusMessage = 'Connection cancelled');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
