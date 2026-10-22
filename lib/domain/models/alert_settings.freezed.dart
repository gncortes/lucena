// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'alert_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AlertSettings {

/// Um final novo de torneio na região (push, tópicos `torneio_*`).
 bool get tournaments;/// O final do dia e os lembretes locais (sequência, lição, semana).
 bool get daily;/// Recursos novos do Lucena (push, tópico [AlertTopics.news]).
 bool get news;/// Uma aula de finais nova (push, tópico [AlertTopics.lessons]).
 bool get lessons;/// A hora dos lembretes locais, em minutos desde a meia-noite (4c: 19h).
 int get reminderMinutes;
/// Create a copy of AlertSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlertSettingsCopyWith<AlertSettings> get copyWith => _$AlertSettingsCopyWithImpl<AlertSettings>(this as AlertSettings, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AlertSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlertSettings&&(identical(other.tournaments, _this.tournaments) || other.tournaments == _this.tournaments)&&(identical(other.daily, _this.daily) || other.daily == _this.daily)&&(identical(other.news, _this.news) || other.news == _this.news)&&(identical(other.lessons, _this.lessons) || other.lessons == _this.lessons)&&(identical(other.reminderMinutes, _this.reminderMinutes) || other.reminderMinutes == _this.reminderMinutes));
}


@override
int get hashCode {
  final _this = this as AlertSettings;
  return Object.hash(runtimeType,_this.tournaments,_this.daily,_this.news,_this.lessons,_this.reminderMinutes);
}

@override
String toString() {
  final _this = this as AlertSettings;
  return 'AlertSettings(tournaments: ${_this.tournaments}, daily: ${_this.daily}, news: ${_this.news}, lessons: ${_this.lessons}, reminderMinutes: ${_this.reminderMinutes})';
}


}

/// @nodoc
abstract mixin class $AlertSettingsCopyWith<$Res>  {
  factory $AlertSettingsCopyWith(AlertSettings value, $Res Function(AlertSettings) _then) = _$AlertSettingsCopyWithImpl;
@useResult
$Res call({
 bool tournaments, bool daily, bool news, bool lessons, int reminderMinutes
});




}
/// @nodoc
class _$AlertSettingsCopyWithImpl<$Res>
    implements $AlertSettingsCopyWith<$Res> {
  _$AlertSettingsCopyWithImpl(this._self, this._then);

  final AlertSettings _self;
  final $Res Function(AlertSettings) _then;

/// Create a copy of AlertSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tournaments = null,Object? daily = null,Object? news = null,Object? lessons = null,Object? reminderMinutes = null,}) {
  return _then(AlertSettings(
tournaments: null == tournaments ? _self.tournaments : tournaments // ignore: cast_nullable_to_non_nullable
as bool,daily: null == daily ? _self.daily : daily // ignore: cast_nullable_to_non_nullable
as bool,news: null == news ? _self.news : news // ignore: cast_nullable_to_non_nullable
as bool,lessons: null == lessons ? _self.lessons : lessons // ignore: cast_nullable_to_non_nullable
as bool,reminderMinutes: null == reminderMinutes ? _self.reminderMinutes : reminderMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AlertSettings].
extension AlertSettingsPatterns on AlertSettings {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AlertSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AlertSettings() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AlertSettings value)  $default,){
final _that = this;
switch (_that) {
case _AlertSettings():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AlertSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AlertSettings() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool tournaments,  bool daily,  bool news,  bool lessons,  int reminderMinutes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AlertSettings() when $default != null:
return $default(_that.tournaments,_that.daily,_that.news,_that.lessons,_that.reminderMinutes);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool tournaments,  bool daily,  bool news,  bool lessons,  int reminderMinutes)  $default,) {final _that = this;
switch (_that) {
case _AlertSettings():
return $default(_that.tournaments,_that.daily,_that.news,_that.lessons,_that.reminderMinutes);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool tournaments,  bool daily,  bool news,  bool lessons,  int reminderMinutes)?  $default,) {final _that = this;
switch (_that) {
case _AlertSettings() when $default != null:
return $default(_that.tournaments,_that.daily,_that.news,_that.lessons,_that.reminderMinutes);case _:
  return null;

}
}

}

/// @nodoc


class _AlertSettings extends AlertSettings {
  const _AlertSettings({this.tournaments = true, this.daily = true, this.news = false, this.lessons = true, this.reminderMinutes = AlertSettings.defaultReminder}): super._();
  

/// Um final novo de torneio na região (push, tópicos `torneio_*`).
@override@JsonKey() final  bool tournaments;
/// O final do dia e os lembretes locais (sequência, lição, semana).
@override@JsonKey() final  bool daily;
/// Recursos novos do Lucena (push, tópico [AlertTopics.news]).
@override@JsonKey() final  bool news;
/// Uma aula de finais nova (push, tópico [AlertTopics.lessons]).
@override@JsonKey() final  bool lessons;
/// A hora dos lembretes locais, em minutos desde a meia-noite (4c: 19h).
@override@JsonKey() final  int reminderMinutes;

/// Create a copy of AlertSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AlertSettingsCopyWith<_AlertSettings> get copyWith => __$AlertSettingsCopyWithImpl<_AlertSettings>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AlertSettings&&(identical(other.tournaments, tournaments) || other.tournaments == tournaments)&&(identical(other.daily, daily) || other.daily == daily)&&(identical(other.news, news) || other.news == news)&&(identical(other.lessons, lessons) || other.lessons == lessons)&&(identical(other.reminderMinutes, reminderMinutes) || other.reminderMinutes == reminderMinutes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,tournaments,daily,news,lessons,reminderMinutes);
}

@override
String toString() {
    return 'AlertSettings(tournaments: $tournaments, daily: $daily, news: $news, lessons: $lessons, reminderMinutes: $reminderMinutes)';
}


}

/// @nodoc
abstract mixin class _$AlertSettingsCopyWith<$Res> implements $AlertSettingsCopyWith<$Res> {
  factory _$AlertSettingsCopyWith(_AlertSettings value, $Res Function(_AlertSettings) _then) = __$AlertSettingsCopyWithImpl;
@override @useResult
$Res call({
 bool tournaments, bool daily, bool news, bool lessons, int reminderMinutes
});




}
/// @nodoc
class __$AlertSettingsCopyWithImpl<$Res>
    implements _$AlertSettingsCopyWith<$Res> {
  __$AlertSettingsCopyWithImpl(this._self, this._then);

  final _AlertSettings _self;
  final $Res Function(_AlertSettings) _then;

/// Create a copy of AlertSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tournaments = null,Object? daily = null,Object? news = null,Object? lessons = null,Object? reminderMinutes = null,}) {
  return _then(_AlertSettings(
tournaments: null == tournaments ? _self.tournaments : tournaments // ignore: cast_nullable_to_non_nullable
as bool,daily: null == daily ? _self.daily : daily // ignore: cast_nullable_to_non_nullable
as bool,news: null == news ? _self.news : news // ignore: cast_nullable_to_non_nullable
as bool,lessons: null == lessons ? _self.lessons : lessons // ignore: cast_nullable_to_non_nullable
as bool,reminderMinutes: null == reminderMinutes ? _self.reminderMinutes : reminderMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
