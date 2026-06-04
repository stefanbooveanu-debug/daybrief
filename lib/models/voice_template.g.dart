// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VoiceTemplate _$VoiceTemplateFromJson(Map<String, dynamic> json) =>
    _VoiceTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      phrase: json['phrase'] as String,
      category: const _CategoryConverter().fromJson(json['category']),
      defaultTime: json['defaultTime'] as String?,
      isCustom: json['isCustom'] as bool? ?? false,
    );

Map<String, dynamic> _$VoiceTemplateToJson(_VoiceTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phrase': instance.phrase,
      'category': const _CategoryConverter().toJson(instance.category),
      'defaultTime': instance.defaultTime,
      'isCustom': instance.isCustom,
    };
