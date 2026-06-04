// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'voice_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VoiceTemplate {
  String get id;
  String get name;
  String get phrase;
  @_CategoryConverter()
  EventCategory? get category;
  String? get defaultTime;
  bool get isCustom;

  /// Create a copy of VoiceTemplate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $VoiceTemplateCopyWith<VoiceTemplate> get copyWith =>
      _$VoiceTemplateCopyWithImpl<VoiceTemplate>(
          this as VoiceTemplate, _$identity);

  /// Serializes this VoiceTemplate to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is VoiceTemplate &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.phrase, phrase) || other.phrase == phrase) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.defaultTime, defaultTime) ||
                other.defaultTime == defaultTime) &&
            (identical(other.isCustom, isCustom) ||
                other.isCustom == isCustom));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, phrase, category, defaultTime, isCustom);

  @override
  String toString() {
    return 'VoiceTemplate(id: $id, name: $name, phrase: $phrase, category: $category, defaultTime: $defaultTime, isCustom: $isCustom)';
  }
}

/// @nodoc
abstract mixin class $VoiceTemplateCopyWith<$Res> {
  factory $VoiceTemplateCopyWith(
          VoiceTemplate value, $Res Function(VoiceTemplate) _then) =
      _$VoiceTemplateCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      String phrase,
      @_CategoryConverter() EventCategory? category,
      String? defaultTime,
      bool isCustom});
}

/// @nodoc
class _$VoiceTemplateCopyWithImpl<$Res>
    implements $VoiceTemplateCopyWith<$Res> {
  _$VoiceTemplateCopyWithImpl(this._self, this._then);

  final VoiceTemplate _self;
  final $Res Function(VoiceTemplate) _then;

  /// Create a copy of VoiceTemplate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? phrase = null,
    Object? category = freezed,
    Object? defaultTime = freezed,
    Object? isCustom = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      phrase: null == phrase
          ? _self.phrase
          : phrase // ignore: cast_nullable_to_non_nullable
              as String,
      category: freezed == category
          ? _self.category
          : category // ignore: cast_nullable_to_non_nullable
              as EventCategory?,
      defaultTime: freezed == defaultTime
          ? _self.defaultTime
          : defaultTime // ignore: cast_nullable_to_non_nullable
              as String?,
      isCustom: null == isCustom
          ? _self.isCustom
          : isCustom // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _VoiceTemplate extends VoiceTemplate {
  const _VoiceTemplate(
      {required this.id,
      required this.name,
      required this.phrase,
      @_CategoryConverter() this.category,
      this.defaultTime,
      this.isCustom = false})
      : super._();
  factory _VoiceTemplate.fromJson(Map<String, dynamic> json) =>
      _$VoiceTemplateFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String phrase;
  @override
  @_CategoryConverter()
  final EventCategory? category;
  @override
  final String? defaultTime;
  @override
  @JsonKey()
  final bool isCustom;

  /// Create a copy of VoiceTemplate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$VoiceTemplateCopyWith<_VoiceTemplate> get copyWith =>
      __$VoiceTemplateCopyWithImpl<_VoiceTemplate>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$VoiceTemplateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _VoiceTemplate &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.phrase, phrase) || other.phrase == phrase) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.defaultTime, defaultTime) ||
                other.defaultTime == defaultTime) &&
            (identical(other.isCustom, isCustom) ||
                other.isCustom == isCustom));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, phrase, category, defaultTime, isCustom);

  @override
  String toString() {
    return 'VoiceTemplate(id: $id, name: $name, phrase: $phrase, category: $category, defaultTime: $defaultTime, isCustom: $isCustom)';
  }
}

/// @nodoc
abstract mixin class _$VoiceTemplateCopyWith<$Res>
    implements $VoiceTemplateCopyWith<$Res> {
  factory _$VoiceTemplateCopyWith(
          _VoiceTemplate value, $Res Function(_VoiceTemplate) _then) =
      __$VoiceTemplateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String phrase,
      @_CategoryConverter() EventCategory? category,
      String? defaultTime,
      bool isCustom});
}

/// @nodoc
class __$VoiceTemplateCopyWithImpl<$Res>
    implements _$VoiceTemplateCopyWith<$Res> {
  __$VoiceTemplateCopyWithImpl(this._self, this._then);

  final _VoiceTemplate _self;
  final $Res Function(_VoiceTemplate) _then;

  /// Create a copy of VoiceTemplate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? phrase = null,
    Object? category = freezed,
    Object? defaultTime = freezed,
    Object? isCustom = null,
  }) {
    return _then(_VoiceTemplate(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      phrase: null == phrase
          ? _self.phrase
          : phrase // ignore: cast_nullable_to_non_nullable
              as String,
      category: freezed == category
          ? _self.category
          : category // ignore: cast_nullable_to_non_nullable
              as EventCategory?,
      defaultTime: freezed == defaultTime
          ? _self.defaultTime
          : defaultTime // ignore: cast_nullable_to_non_nullable
              as String?,
      isCustom: null == isCustom
          ? _self.isCustom
          : isCustom // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
