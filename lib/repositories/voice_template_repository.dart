import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/voice_template.dart';

class VoiceTemplateRepository {
  VoiceTemplateRepository({SharedPreferences? prefs}) : _prefs = prefs;

  static const _storageKey = 'voiceTemplates';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _preferences() async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<List<VoiceTemplate>> loadTemplates() async {
    final prefs = await _preferences();
    final savedTemplates = prefs.getString(_storageKey);
    if (savedTemplates == null) {
      return VoiceTemplate.defaultTemplates;
    }
    try {
      final decoded = jsonDecode(savedTemplates) as List<dynamic>;
      return decoded.map((e) => VoiceTemplate.fromMap(e)).toList();
    } catch (_) {
      return VoiceTemplate.defaultTemplates;
    }
  }

  Future<void> saveTemplates(List<VoiceTemplate> templates) async {
    final prefs = await _preferences();
    final encoded = jsonEncode(templates.map((e) => e.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
