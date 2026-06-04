import 'package:flutter/material.dart' show TimeOfDay;
import 'package:freezed_annotation/freezed_annotation.dart';

import 'event.dart' show EventCategory;
import 'voice_template_defaults.dart';

part 'voice_template.freezed.dart';
part 'voice_template.g.dart';

class _CategoryConverter implements JsonConverter<EventCategory?, Object?> {
  const _CategoryConverter();

  @override
  EventCategory? fromJson(Object? json) => EventCategory.parse(json);

  @override
  Object? toJson(EventCategory? object) => object?.name;
}

@freezed
sealed class VoiceTemplate with _$VoiceTemplate {
  const VoiceTemplate._();

  const factory VoiceTemplate({
    required String id,
    required String name,
    required String phrase,
    @_CategoryConverter() EventCategory? category,
    String? defaultTime,
    @Default(false) bool isCustom,
  }) = _VoiceTemplate;

  factory VoiceTemplate.fromJson(Map<String, dynamic> json) =>
      _$VoiceTemplateFromJson(json);

  factory VoiceTemplate.fromMap(Map<String, dynamic> map) =>
      VoiceTemplate.fromJson(map);

  Map<String, dynamic> toMap() => toJson();

  /// Parses [defaultTime] (e.g. `"09:00"`) into a [TimeOfDay].
  /// Returns `null` if the string is missing or malformed.
  TimeOfDay? get defaultTimeOfDay {
    final t = defaultTime;
    if (t == null) return null;
    final parts = t.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  /// Backwards-compat: forwards to [voiceTemplateDefaults].
  static List<VoiceTemplate> get defaultTemplates => voiceTemplateDefaults();
}
