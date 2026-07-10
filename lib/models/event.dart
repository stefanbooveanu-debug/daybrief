import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'event.freezed.dart';
part 'event.g.dart';

/// Canonical event category. Serialized via `.name` (NOT `.index`) so that
/// renumbering values doesn't break stored data.
enum EventCategory {
  work,
  personal,
  health,
  social,
  shopping,
  other;

  /// Title-case label used by theme maps and settings UI keys.
  String get displayName => switch (this) {
        EventCategory.work => 'Work',
        EventCategory.personal => 'Personal',
        EventCategory.health => 'Health',
        EventCategory.social => 'Social',
        EventCategory.shopping => 'Shopping',
        EventCategory.other => 'Other',
      };

  /// Tolerant parser used by the JsonConverter. Accepts:
  ///   - `null` → `null`
  ///   - the canonical lowercase name (`"work"`)
  ///   - the legacy title-cased form (`"Work"`)
  ///   - any unknown string → `EventCategory.other`
  static EventCategory? parse(Object? raw) {
    if (raw == null) return null;
    if (raw is EventCategory) return raw;
    final s = raw.toString().toLowerCase().trim();
    if (s.isEmpty) return null;
    for (final v in EventCategory.values) {
      if (v.name == s) return v;
    }
    return EventCategory.other;
  }
}

enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
  yearly;

  static RecurrenceType parse(Object? raw) {
    if (raw == null) return RecurrenceType.none;
    if (raw is RecurrenceType) return raw;
    // Legacy: stored as int index.
    if (raw is int) {
      if (raw >= 0 && raw < RecurrenceType.values.length) {
        return RecurrenceType.values[raw];
      }
      return RecurrenceType.none;
    }
    final s = raw.toString().toLowerCase();
    for (final v in RecurrenceType.values) {
      if (v.name == s) return v;
    }
    return RecurrenceType.none;
  }
}

/// Parses every shape we've ever stored a DateTime in:
///   - native `DateTime`
///   - ISO-8601 `String` (current local store format)
///   - milliseconds-since-epoch `int`
///   - Firestore `Timestamp`
DateTime _parseEventDateTime(Object? raw) {
  if (raw is DateTime) return raw;
  if (raw is Timestamp) return raw.toDate();
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
  if (raw is String) return DateTime.parse(raw);
  throw FormatException('Cannot parse dateTime from value of type '
      '${raw.runtimeType}: $raw');
}

class _DateTimeConverter implements JsonConverter<DateTime, Object> {
  const _DateTimeConverter();

  @override
  DateTime fromJson(Object json) => _parseEventDateTime(json);

  @override
  Object toJson(DateTime object) => object.toIso8601String();
}

class _EventCategoryConverter
    implements JsonConverter<EventCategory?, Object?> {
  const _EventCategoryConverter();

  @override
  EventCategory? fromJson(Object? json) => EventCategory.parse(json);

  @override
  Object? toJson(EventCategory? object) => object?.name;
}

class _RecurrenceConverter implements JsonConverter<RecurrenceType, Object?> {
  const _RecurrenceConverter();

  @override
  RecurrenceType fromJson(Object? json) => RecurrenceType.parse(json);

  @override
  Object toJson(RecurrenceType object) => object.name;
}

@freezed
sealed class Event with _$Event {
  const Event._();

  const factory Event({
    required String id,
    required String title,
    @_DateTimeConverter() required DateTime dateTime,
    String? description,
    @_EventCategoryConverter() EventCategory? category,
    @Default(true) bool reminderEnabled,
    @Default(false) bool isCompleted,
    required String userId,
    String? location,
    @_RecurrenceConverter()
    @Default(RecurrenceType.none)
    RecurrenceType recurrenceType,
  }) = _Event;

  /// Throws [FormatException] when required string fields are blank.
  /// Use this factory instead of the default constructor when the values
  /// come from untrusted sources (Firestore, voice parser, etc.).
  factory Event.checked({
    required String id,
    required String title,
    required DateTime dateTime,
    required String userId,
    String? description,
    EventCategory? category,
    bool reminderEnabled = true,
    bool isCompleted = false,
    String? location,
    RecurrenceType recurrenceType = RecurrenceType.none,
  }) {
    if (id.trim().isEmpty) {
      throw const FormatException('Event.id must not be empty');
    }
    if (title.trim().isEmpty) {
      throw const FormatException('Event.title must not be empty');
    }
    if (userId.trim().isEmpty) {
      throw const FormatException('Event.userId must not be empty');
    }
    return Event(
      id: id,
      title: title,
      dateTime: dateTime,
      userId: userId,
      description: description,
      category: category,
      reminderEnabled: reminderEnabled,
      isCompleted: isCompleted,
      location: location,
      recurrenceType: recurrenceType,
    );
  }

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  /// Backwards-compat shim for code that hasn't migrated yet.
  factory Event.fromMap(Map<String, dynamic> map) => Event.fromJson(map);

  Map<String, dynamic> toMap() => toJson();

  DateTime? get reminderTime =>
      reminderEnabled ? dateTime.subtract(const Duration(hours: 1)) : null;
}
