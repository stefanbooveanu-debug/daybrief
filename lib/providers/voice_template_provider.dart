import 'package:flutter/foundation.dart';

import '../models/voice_template.dart';
import '../repositories/voice_template_repository.dart';
import '../utils/async_value.dart';

class VoiceTemplateProvider with ChangeNotifier {
  VoiceTemplateProvider(this._repository) {
    _loadTemplates();
  }

  final VoiceTemplateRepository _repository;

  List<VoiceTemplate> _templates = [];
  AsyncValue<List<VoiceTemplate>> _state = const AsyncLoading();

  List<VoiceTemplate> get templates => List.unmodifiable(_templates);
  List<VoiceTemplate> get customTemplates =>
      List.unmodifiable(_templates.where((t) => t.isCustom));
  AsyncValue<List<VoiceTemplate>> get state => _state;
  bool get isLoading => _state is AsyncLoading<List<VoiceTemplate>>;

  Future<void> _loadTemplates() async {
    _state = const AsyncLoading();
    notifyListeners();

    try {
      _templates = await _repository.loadTemplates();
      _state = AsyncData(List.unmodifiable(_templates));
    } catch (e, st) {
      _templates = VoiceTemplate.defaultTemplates;
      _state = AsyncError<List<VoiceTemplate>>(e, st);
    }

    notifyListeners();
  }

  Future<void> addTemplate(VoiceTemplate template) async {
    final newTemplate = template.copyWith(isCustom: true);
    _templates = [..._templates, newTemplate];
    await _repository.saveTemplates(_templates);
    _state = AsyncData(List.unmodifiable(_templates));
    notifyListeners();
  }

  Future<void> updateTemplate(VoiceTemplate template) async {
    final index = _templates.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      _templates = [..._templates]..[index] = template;
      await _repository.saveTemplates(_templates);
      _state = AsyncData(List.unmodifiable(_templates));
      notifyListeners();
    }
  }

  Future<void> deleteTemplate(String id) async {
    _templates = _templates.where((t) => t.id != id).toList();
    await _repository.saveTemplates(_templates);
    _state = AsyncData(List.unmodifiable(_templates));
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
    await _repository.saveTemplates(_templates);
    _state = AsyncData(List.unmodifiable(_templates));
    notifyListeners();
  }
}
