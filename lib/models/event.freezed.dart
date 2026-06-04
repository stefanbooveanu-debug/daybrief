// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Event {
  String get id;
  String get title;
  @_DateTimeConverter()
  DateTime get dateTime;
  String? get description;
  @_EventCategoryConverter()
  EventCategory? get category;
  bool get reminderEnabled;
  bool get isCompleted;
  String get userId;
  String? get location;
  @_RecurrenceConverter()
  RecurrenceType get recurrenceType;

  /// Create a copy of Event
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EventCopyWith<Event> get copyWith =>
      _$EventCopyWithImpl<Event>(this as Event, _$identity);

  /// Serializes this Event to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Event &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.dateTime, dateTime) ||
                other.dateTime == dateTime) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.reminderEnabled, reminderEnabled) ||
                other.reminderEnabled == reminderEnabled) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.recurrenceType, recurrenceType) ||
                other.recurrenceType == recurrenceType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, title, dateTime, description,
      category, reminderEnabled, isCompleted, userId, location, recurrenceType);

  @override
  String toString() {
    return 'Event(id: $id, title: $title, dateTime: $dateTime, description: $description, category: $category, reminderEnabled: $reminderEnabled, isCompleted: $isCompleted, userId: $userId, location: $location, recurrenceType: $recurrenceType)';
  }
}

/// @nodoc
abstract mixin class $EventCopyWith<$Res> {
  factory $EventCopyWith(Event value, $Res Function(Event) _then) =
      _$EventCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String title,
      @_DateTimeConverter() DateTime dateTime,
      String? description,
      @_EventCategoryConverter() EventCategory? category,
      bool reminderEnabled,
      bool isCompleted,
      String userId,
      String? location,
      @_RecurrenceConverter() RecurrenceType recurrenceType});
}

/// @nodoc
class _$EventCopyWithImpl<$Res> implements $EventCopyWith<$Res> {
  _$EventCopyWithImpl(this._self, this._then);

  final Event _self;
  final $Res Function(Event) _then;

  /// Create a copy of Event
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? dateTime = null,
    Object? description = freezed,
    Object? category = freezed,
    Object? reminderEnabled = null,
    Object? isCompleted = null,
    Object? userId = null,
    Object? location = freezed,
    Object? recurrenceType = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      dateTime: null == dateTime
          ? _self.dateTime
          : dateTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _self.category
          : category // ignore: cast_nullable_to_non_nullable
              as EventCategory?,
      reminderEnabled: null == reminderEnabled
          ? _self.reminderEnabled
          : reminderEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isCompleted: null == isCompleted
          ? _self.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      location: freezed == location
          ? _self.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
      recurrenceType: null == recurrenceType
          ? _self.recurrenceType
          : recurrenceType // ignore: cast_nullable_to_non_nullable
              as RecurrenceType,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _Event extends Event {
  const _Event(
      {required this.id,
      required this.title,
      @_DateTimeConverter() required this.dateTime,
      this.description,
      @_EventCategoryConverter() this.category,
      this.reminderEnabled = true,
      this.isCompleted = false,
      required this.userId,
      this.location,
      @_RecurrenceConverter() this.recurrenceType = RecurrenceType.none})
      : super._();
  factory _Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  @_DateTimeConverter()
  final DateTime dateTime;
  @override
  final String? description;
  @override
  @_EventCategoryConverter()
  final EventCategory? category;
  @override
  @JsonKey()
  final bool reminderEnabled;
  @override
  @JsonKey()
  final bool isCompleted;
  @override
  final String userId;
  @override
  final String? location;
  @override
  @JsonKey()
  @_RecurrenceConverter()
  final RecurrenceType recurrenceType;

  /// Create a copy of Event
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$EventCopyWith<_Event> get copyWith =>
      __$EventCopyWithImpl<_Event>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$EventToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Event &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.dateTime, dateTime) ||
                other.dateTime == dateTime) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.reminderEnabled, reminderEnabled) ||
                other.reminderEnabled == reminderEnabled) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.recurrenceType, recurrenceType) ||
                other.recurrenceType == recurrenceType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, title, dateTime, description,
      category, reminderEnabled, isCompleted, userId, location, recurrenceType);

  @override
  String toString() {
    return 'Event(id: $id, title: $title, dateTime: $dateTime, description: $description, category: $category, reminderEnabled: $reminderEnabled, isCompleted: $isCompleted, userId: $userId, location: $location, recurrenceType: $recurrenceType)';
  }
}

/// @nodoc
abstract mixin class _$EventCopyWith<$Res> implements $EventCopyWith<$Res> {
  factory _$EventCopyWith(_Event value, $Res Function(_Event) _then) =
      __$EventCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      @_DateTimeConverter() DateTime dateTime,
      String? description,
      @_EventCategoryConverter() EventCategory? category,
      bool reminderEnabled,
      bool isCompleted,
      String userId,
      String? location,
      @_RecurrenceConverter() RecurrenceType recurrenceType});
}

/// @nodoc
class __$EventCopyWithImpl<$Res> implements _$EventCopyWith<$Res> {
  __$EventCopyWithImpl(this._self, this._then);

  final _Event _self;
  final $Res Function(_Event) _then;

  /// Create a copy of Event
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? dateTime = null,
    Object? description = freezed,
    Object? category = freezed,
    Object? reminderEnabled = null,
    Object? isCompleted = null,
    Object? userId = null,
    Object? location = freezed,
    Object? recurrenceType = null,
  }) {
    return _then(_Event(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      dateTime: null == dateTime
          ? _self.dateTime
          : dateTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _self.category
          : category // ignore: cast_nullable_to_non_nullable
              as EventCategory?,
      reminderEnabled: null == reminderEnabled
          ? _self.reminderEnabled
          : reminderEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isCompleted: null == isCompleted
          ? _self.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      location: freezed == location
          ? _self.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
      recurrenceType: null == recurrenceType
          ? _self.recurrenceType
          : recurrenceType // ignore: cast_nullable_to_non_nullable
              as RecurrenceType,
    ));
  }
}

// dart format on
