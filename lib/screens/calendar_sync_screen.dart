import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
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
                const SizedBox(height: 12),
                Text(
                  'Connect your Google Calendar to sync events automatically. Requires Google account.',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _connectGoogleCalendar,
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    label: Text(_isLoading
                        ? 'Connecting...'
                        : 'Connect Google Calendar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_statusMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _statusMessage!,
                    style: TextStyle(
                      color: _statusMessage!.contains('Error')
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: isDark ? Colors.grey[400] : Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ICS is a universal calendar format supported by Google Calendar, Apple Calendar, Outlook, and more.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
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

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Calendar',
        fileName: 'daybrief_calendar.ics',
        type: FileType.custom,
        allowedExtensions: ['ics'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(icsContent);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Calendar exported successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
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
        allowedExtensions: ['ics'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();

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
              content: Text('Imported ${importedEvents.length} events!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No events found in file'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
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
      final signedIn = await _calendarService.signIn();

      if (!mounted) return;

      if (signedIn && _calendarService.isConnected) {
        setState(() => _statusMessage = 'Connected! Syncing events...');

        int syncedCount = 0;
        final events = context.read<EventProvider>().events;
        for (final event in events) {
          final success = await _calendarService.syncEvent(event);
          if (success) syncedCount++;
        }

        if (!mounted) return;
        setState(() => _statusMessage = 'Synced $syncedCount events!');
      } else {
        setState(() => _statusMessage = 'Connection cancelled');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = 'Error: $e');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }
}
