import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../models/event.dart';
import '../models/family.dart';
import '../providers/auth_provider.dart';
import '../providers/family_provider.dart';
import '../utils/async_value.dart';

class FamilyCalendarScreen extends StatefulWidget {
  const FamilyCalendarScreen({super.key});

  @override
  State<FamilyCalendarScreen> createState() => _FamilyCalendarScreenState();
}

class _FamilyCalendarScreenState extends State<FamilyCalendarScreen> {
  static const _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final family = context.read<FamilyProvider>();
      if (auth.isAuthenticated && !auth.isDemoMode) {
        family.start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final familyProvider = context.watch<FamilyProvider>();

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
          'Family Calendar',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF202124),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (familyProvider.family != null)
            IconButton(
              icon: Icon(
                Icons.person_add_outlined,
                color:
                    isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
              ),
              onPressed: _showInviteDialog,
            ),
        ],
      ),
      body: _buildBody(auth, familyProvider, isDark),
      floatingActionButton: familyProvider.family == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddFamilyEvent,
              backgroundColor:
                  isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
              icon: const Icon(Icons.add),
              label: const Text('Add Family Event'),
            ),
    );
  }

  Widget _buildBody(
    AuthProvider auth,
    FamilyProvider familyProvider,
    bool isDark,
  ) {
    if (!auth.isAuthenticated || auth.isDemoMode) {
      return _centeredMessage(
        isDark,
        'Sign in with a real account to use Family Calendar.',
      );
    }

    return switch (familyProvider.state) {
      AsyncLoading() || AsyncIdle() => const Center(
          child: CircularProgressIndicator(),
        ),
      AsyncError(:final error) => _centeredMessage(isDark, error.toString()),
      AsyncData(:final value) => value == null
          ? _buildOnboarding(isDark)
          : _buildFamilyContent(familyProvider, isDark),
    };
  }

  Widget _centeredMessage(bool isDark, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildOnboarding(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Create or join a family calendar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF202124),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Share events with people you live with.',
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _showCreateFamilyDialog,
          child: const Text('Create Family'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _showJoinFamilyDialog,
          child: const Text('Join with Invite Code'),
        ),
      ],
    );
  }

  Widget _buildFamilyContent(FamilyProvider provider, bool isDark) {
    final family = provider.family!;
    final members = provider.members;
    final events = provider.events;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildFamilyHeader(family, members, isDark),
        const SizedBox(height: 24),
        Text(
          'Upcoming Family Events',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF202124),
          ),
        ),
        const SizedBox(height: 16),
        if (events.isEmpty)
          Text(
            'No family events yet. Tap + to add one.',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          )
        else
          ...events.map((e) => _buildFamilyEventCard(e, provider, isDark)),
      ],
    );
  }

  Widget _buildFamilyHeader(
    FamilyInfo family,
    List<FamilyMember> members,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE91E63).withValues(alpha: 0.8),
            const Color(0xFF2196F3).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            family.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Invite code: ${family.inviteCode}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: family.inviteCode),
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invite code copied')),
                  );
                },
                icon: const Icon(Icons.copy, color: Colors.white, size: 18),
              ),
              IconButton(
                onPressed: () {
                  Share.share(
                    'Join my DayBrief family with code ${family.inviteCode}',
                  );
                },
                icon: const Icon(Icons.share, color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Family Members',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          if (members.isEmpty)
            const Text(
              'Loading members…',
              style: TextStyle(color: Colors.white70),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: members
                    .map(
                      (member) => Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: member.color,
                                  width: 3,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  member.avatar,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              member.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFamilyEventCard(
    Event event,
    FamilyProvider provider,
    bool isDark,
  ) {
    final member = provider.memberFor(event.userId);
    final color = member?.color ?? const Color(0xFF1A73E8);
    final avatar = member?.avatar ?? '👤';
    final name = member?.displayName ?? event.userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(avatar, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : const Color(0xFF202124),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEE, MMM d - h:mm a').format(event.dateTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                if (event.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => provider.removeFamilyEvent(event.id),
            icon: Icon(Icons.delete_outline, color: Colors.red[300]),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateFamilyDialog() async {
    final controller = TextEditingController(text: 'My Family');
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Family'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Family name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;

    try {
      await context.read<FamilyProvider>().createFamily(name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Family created')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create family: $e')),
      );
    }
  }

  Future<void> _showJoinFamilyDialog() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Join Family'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Invite code'),
          textCapitalization: TextCapitalization.characters,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Join'),
          ),
        ],
      ),
    );
    if (code == null || code.isEmpty || !mounted) return;

    try {
      await context.read<FamilyProvider>().joinFamily(code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined family')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not join: $e')),
      );
    }
  }

  Future<void> _showInviteDialog() async {
    final family = context.read<FamilyProvider>().family;
    if (family == null) return;

    final emailController = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Invite Family Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invite code: ${family.inviteCode}'),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'family@example.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, emailController.text.trim()),
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
    if (email == null || email.isEmpty || !mounted) return;

    try {
      await context.read<FamilyProvider>().inviteMember(email);
      if (!mounted) return;
      await Share.share(
        'Join my DayBrief family "${family.name}" with code ${family.inviteCode}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite saved — share the code')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invite failed: $e')),
      );
    }
  }

  Future<void> _showAddFamilyEvent() async {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    final auth = context.read<AuthProvider>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setModalState) {
          final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Family Event',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF202124),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'Event title',
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF2D2D2D)
                          : const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: sheetContext,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setModalState(() => selectedDate = date);
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(DateFormat('MMM d').format(selectedDate)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: sheetContext,
                              initialTime: selectedTime,
                            );
                            if (time != null) {
                              setModalState(() => selectedTime = time);
                            }
                          },
                          icon: const Icon(Icons.access_time),
                          label: Text(selectedTime.format(sheetContext)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        if (title.isEmpty) return;
                        final event = Event(
                          id: _uuid.v4(),
                          title: title,
                          dateTime: DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          ),
                          category: EventCategory.personal,
                          userId: auth.userId ?? 'unknown',
                        );
                        try {
                          await context
                              .read<FamilyProvider>()
                              .addFamilyEvent(event);
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Add failed: $e')),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF8AB4F8)
                            : const Color(0xFF1A73E8),
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
