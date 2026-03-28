import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/voice_template.dart';

class VoiceTemplateProvider with ChangeNotifier {
  List<VoiceTemplate> _templates = [];
  bool _isLoading = false;

  List<VoiceTemplate> get templates => _templates;
  List<VoiceTemplate> get customTemplates => _templates.where((t) => t.isCustom).toList();
  bool get isLoading => _isLoading;

  VoiceTemplateProvider() {
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTemplates = prefs.getString('voiceTemplates');
      
      if (savedTemplates != null) {
        final List<dynamic> decoded = jsonDecode(savedTemplates);
        _templates = decoded.map((e) => VoiceTemplate.fromMap(e)).toList();
      } else {
        _templates = VoiceTemplate.defaultTemplates;
      }
    } catch (e) {
      _templates = VoiceTemplate.defaultTemplates;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_templates.map((e) => e.toMap()).toList());
      await prefs.setString('voiceTemplates', encoded);
    } catch (e) {
      debugPrint('Error saving templates: $e');
    }
  }

  Future<void> addTemplate(VoiceTemplate template) async {
    final newTemplate = template.copyWith(isCustom: true);
    _templates.add(newTemplate);
    await _saveTemplates();
    notifyListeners();
  }

  Future<void> updateTemplate(VoiceTemplate template) async {
    final index = _templates.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      _templates[index] = template;
      await _saveTemplates();
      notifyListeners();
    }
  }

  Future<void> deleteTemplate(String id) async {
    _templates.removeWhere((t) => t.id == id);
    await _saveTemplates();
    notifyListeners();
  }

  VoiceTemplate? matchTemplate(String phrase) {
    final lowerPhrase = phrase.toLowerCase();
    for (final template in _templates) {
      if (lowerPhrase.contains(template.phrase.toLowerCase())) {
        return template;
      }
    }
    return null;
  }

  Future<void> resetToDefaults() async {
    _templates = VoiceTemplate.defaultTemplates;
    await _saveTemplates();
    notifyListeners();
  }
}
