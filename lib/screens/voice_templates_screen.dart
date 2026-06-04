import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/voice_template.dart';
import '../providers/voice_template_provider.dart';
import '../theme/app_theme.dart';

class VoiceTemplatesScreen extends StatefulWidget {
  const VoiceTemplatesScreen({super.key});

  @override
  State<VoiceTemplatesScreen> createState() => _VoiceTemplatesScreenState();
}

class _VoiceTemplatesScreenState extends State<VoiceTemplatesScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Voice Templates',
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF202124)),
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF202124),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<VoiceTemplateProvider>().resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Templates reset to defaults')),
              );
            },
            tooltip: 'Reset to defaults',
          ),
        ],
      ),
      body: Consumer<VoiceTemplateProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildInfoCard(isDark),
              const SizedBox(height: 16),
              _buildSectionTitle('Default Templates', isDark),
              const SizedBox(height: 8),
              ...provider.templates.where((t) => !t.isCustom).map(
                (template) => _buildTemplateCard(template, isDark),
              ),
              if (provider.customTemplates.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Custom Templates', isDark),
                const SizedBox(height: 8),
                ...provider.customTemplates.map(
                  (template) => _buildTemplateCard(template, isDark, canDelete: true),
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTemplateDialog(context),
        backgroundColor: const Color(0xFF1A73E8),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Template', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: const Color(0xFF1A73E8)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Say "Hey DayBrief" followed by a template phrase to quickly create events. Example: "Hey DayBrief, meeting"',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF202124),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : const Color(0xFF202124),
      ),
    );
  }

  Widget _buildTemplateCard(VoiceTemplate template, bool isDark, {bool canDelete = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(template.category).withOpacity(0.2),
          child: Icon(
            _getCategoryIcon(template.category),
            color: _getCategoryColor(template.category),
            size: 20,
          ),
        ),
        title: Text(
          template.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF202124),
          ),
        ),
        subtitle: Text(
          'Say: "${template.phrase}"${template.defaultTime != null ? ' • ${template.defaultTime}' : ''}',
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: canDelete
            ? IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                onPressed: () => _deleteTemplate(template.id),
              )
            : null,
      ),
    );
  }

  Color _getCategoryColor(EventCategory? category) {
    return Theme.of(context).extension<CategoryColors>()?.colorForCategory(
              category,
            ) ??
        AppColors.colorForCategory(category);
  }

  IconData _getCategoryIcon(EventCategory? category) {
    return AppColors.iconForCategory(category);
  }

  void _deleteTemplate(String id) {
    context.read<VoiceTemplateProvider>().deleteTemplate(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template deleted')),
    );
  }

  void _showAddTemplateDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phraseController = TextEditingController();
    EventCategory selectedCategory = EventCategory.work;
    String? defaultTime = '09:00';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Voice Template'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Template Name',
                    hintText: 'e.g., Quick Meeting',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phraseController,
                  decoration: const InputDecoration(
                    labelText: 'Voice Phrase',
                    hintText: 'e.g., meeting',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<EventCategory>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: EventCategory.values
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.displayName),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedCategory = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  value: defaultTime,
                  decoration: const InputDecoration(labelText: 'Default Time'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('No default')),
                    ...['06:00', '07:00', '08:00', '09:00', '10:00', '11:00',
                    '12:00', '13:00', '14:00', '15:00', '16:00', '17:00',
                    '18:00', '19:00', '20:00', '21:00'].map(
                      (t) => DropdownMenuItem<String?>(value: t, child: Text(t)),
                    ),
                  ],
                  onChanged: (v) => setDialogState(() => defaultTime = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && phraseController.text.isNotEmpty) {
                  final template = VoiceTemplate(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    phrase: phraseController.text,
                    category: selectedCategory,
                    defaultTime: defaultTime,
                    isCustom: true,
                  );
                  context.read<VoiceTemplateProvider>().addTemplate(template);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Template added')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
