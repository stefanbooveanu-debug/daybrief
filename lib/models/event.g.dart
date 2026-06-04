// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Event _$EventFromJson(Map<String, dynamic> json) => _Event(
      id: json['id'] as String,
      title: json['title'] as String,
      dateTime: const _DateTimeConverter().fromJson(json['dateTime'] as Object),
      description: json['description'] as String?,
      category: const _EventCategoryConverter().fromJson(json['category']),
      reminderEnabled: json['reminderEnabled'] as bool? ?? true,
      isCompleted: json['isCompleted'] as bool? ?? false,
      userId: json['userId'] as String,
      location: json['location'] as String?,
      recurrenceType: json['recurrenceType'] == null
          ? RecurrenceType.none
          : const _RecurrenceConverter().fromJson(json['recurrenceType']),
    );

Map<String, dynamic> _$EventToJson(_Event instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'dateTime': const _DateTimeConverter().toJson(instance.dateTime),
      'description': instance.description,
      'category': const _EventCategoryConverter().toJson(instance.category),
      'reminderEnabled': instance.reminderEnabled,
      'isCompleted': instance.isCompleted,
      'userId': instance.userId,
      'location': instance.location,
      'recurrenceType':
          const _RecurrenceConverter().toJson(instance.recurrenceType),
    };
