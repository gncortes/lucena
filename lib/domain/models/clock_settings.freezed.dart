// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'clock_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ClockSettings {

 ClockPosition get position;/// Vibra uma vez quando o tempo de quem joga fica abaixo de 10 s.
 bool get lowTimeVibration;/// O último ritmo escolhido para um speedrun.
 TimeControl get speedrunTime;/// O último ritmo escolhido para um desafio da Jornada. Nulo: sem relógio.
 TimeControl? get journeyTime;
/// Create a copy of ClockSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClockSettingsCopyWith<ClockSettings> get copyWith => _$ClockSettingsCopyWithImpl<ClockSettings>(this as ClockSettings, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ClockSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClockSettings&&(identical(other.position, _this.position) || other.position == _this.position)&&(identical(other.lowTimeVibration, _this.lowTimeVibration) || other.lowTimeVibration == _this.lowTimeVibration)&&(identical(other.speedrunTime, _this.speedrunTime) || other.speedrunTime == _this.speedrunTime)&&(identical(other.journeyTime, _this.journeyTime) || other.journeyTime == _this.journeyTime));
}


@override
int get hashCode {
  final _this = this as ClockSettings;
  return Object.hash(runtimeType,_this.position,_this.lowTimeVibration,_this.speedrunTime,_this.journeyTime);
}

@override
String toString() {
  final _this = this as ClockSettings;
  return 'ClockSettings(position: ${_this.position}, lowTimeVibration: ${_this.lowTimeVibration}, speedrunTime: ${_this.speedrunTime}, journeyTime: ${_this.journeyTime})';
}


}

/// @nodoc
abstract mixin class $ClockSettingsCopyWith<$Res>  {
  factory $ClockSettingsCopyWith(ClockSettings value, $Res Function(ClockSettings) _then) = _$ClockSettingsCopyWithImpl;
@useResult
$Res call({
 ClockPosition position, bool lowTimeVibration, TimeControl speedrunTime, TimeControl? journeyTime
});


$TimeControlCopyWith<$Res> get speedrunTime;$TimeControlCopyWith<$Res>? get journeyTime;

}
/// @nodoc
class _$ClockSettingsCopyWithImpl<$Res>
    implements $ClockSettingsCopyWith<$Res> {
  _$ClockSettingsCopyWithImpl(this._self, this._then);

  final ClockSettings _self;
  final $Res Function(ClockSettings) _then;

/// Create a copy of ClockSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? position = null,Object? lowTimeVibration = null,Object? speedrunTime = null,Object? journeyTime = freezed,}) {
  return _then(ClockSettings(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as ClockPosition,lowTimeVibration: null == lowTimeVibration ? _self.lowTimeVibration : lowTimeVibration // ignore: cast_nullable_to_non_nullable
as bool,speedrunTime: null == speedrunTime ? _self.speedrunTime : speedrunTime // ignore: cast_nullable_to_non_nullable
as TimeControl,journeyTime: freezed == journeyTime ? _self.journeyTime : journeyTime // ignore: cast_nullable_to_non_nullable
as TimeControl?,
  ));
}
/// Create a copy of ClockSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeControlCopyWith<$Res> get speedrunTime {
  
  return $TimeControlCopyWith<$Res>(_self.speedrunTime, (value) {
    return _then(_self.copyWith(speedrunTime: value));
  });
}/// Create a copy of ClockSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeControlCopyWith<$Res>? get journeyTime {
    if (_self.journeyTime == null) {
    return null;
  }

  return $TimeControlCopyWith<$Res>(_self.journeyTime!, (value) {
    return _then(_self.copyWith(journeyTime: value));
  });
}
}


/// Adds pattern-matching-related methods to [ClockSettings].
extension ClockSettingsPatterns on ClockSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClockSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClockSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClockSettings value)  $default,){
final _that = this;
switch (_that) {
case _ClockSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClockSettings value)?  $default,){
final _that = this;
switch (_that) {
case _ClockSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ClockPosition position,  bool lowTimeVibration,  TimeControl speedrunTime,  TimeControl? journeyTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClockSettings() when $default != null:
return $default(_that.position,_that.lowTimeVibration,_that.speedrunTime,_that.journeyTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ClockPosition position,  bool lowTimeVibration,  TimeControl speedrunTime,  TimeControl? journeyTime)  $default,) {final _that = this;
switch (_that) {
case _ClockSettings():
return $default(_that.position,_that.lowTimeVibration,_that.speedrunTime,_that.journeyTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ClockPosition position,  bool lowTimeVibration,  TimeControl speedrunTime,  TimeControl? journeyTime)?  $default,) {final _that = this;
switch (_that) {
case _ClockSettings() when $default != null:
return $default(_that.position,_that.lowTimeVibration,_that.speedrunTime,_that.journeyTime);case _:
  return null;

}
}

}

/// @nodoc


class _ClockSettings implements ClockSettings {
  const _ClockSettings({this.position = ClockPosition.fallback, this.lowTimeVibration = true, this.speedrunTime = SpeedrunPaces.standard, this.journeyTime});
  

@override@JsonKey() final  ClockPosition position;
/// Vibra uma vez quando o tempo de quem joga fica abaixo de 10 s.
@override@JsonKey() final  bool lowTimeVibration;
/// O último ritmo escolhido para um speedrun.
@override@JsonKey() final  TimeControl speedrunTime;
/// O último ritmo escolhido para um desafio da Jornada. Nulo: sem relógio.
@override final  TimeControl? journeyTime;

/// Create a copy of ClockSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClockSettingsCopyWith<_ClockSettings> get copyWith => __$ClockSettingsCopyWithImpl<_ClockSettings>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClockSettings&&(identical(other.position, position) || other.position == position)&&(identical(other.lowTimeVibration, lowTimeVibration) || other.lowTimeVibration == lowTimeVibration)&&(identical(other.speedrunTime, speedrunTime) || other.speedrunTime == speedrunTime)&&(identical(other.journeyTime, journeyTime) || other.journeyTime == journeyTime));
}


@override
int get hashCode {
    return Object.hash(runtimeType,position,lowTimeVibration,speedrunTime,journeyTime);
}

@override
String toString() {
    return 'ClockSettings(position: $position, lowTimeVibration: $lowTimeVibration, speedrunTime: $speedrunTime, journeyTime: $journeyTime)';
}


}

/// @nodoc
abstract mixin class _$ClockSettingsCopyWith<$Res> implements $ClockSettingsCopyWith<$Res> {
  factory _$ClockSettingsCopyWith(_ClockSettings value, $Res Function(_ClockSettings) _then) = __$ClockSettingsCopyWithImpl;
@override @useResult
$Res call({
 ClockPosition position, bool lowTimeVibration, TimeControl speedrunTime, TimeControl? journeyTime
});


@override $TimeControlCopyWith<$Res> get speedrunTime;@override $TimeControlCopyWith<$Res>? get journeyTime;

}
/// @nodoc
class __$ClockSettingsCopyWithImpl<$Res>
    implements _$ClockSettingsCopyWith<$Res> {
  __$ClockSettingsCopyWithImpl(this._self, this._then);

  final _ClockSettings _self;
  final $Res Function(_ClockSettings) _then;

/// Create a copy of ClockSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? position = null,Object? lowTimeVibration = null,Object? speedrunTime = null,Object? journeyTime = freezed,}) {
  return _then(_ClockSettings(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as ClockPosition,lowTimeVibration: null == lowTimeVibration ? _self.lowTimeVibration : lowTimeVibration // ignore: cast_nullable_to_non_nullable
as bool,speedrunTime: null == speedrunTime ? _self.speedrunTime : speedrunTime // ignore: cast_nullable_to_non_nullable
as TimeControl,journeyTime: freezed == journeyTime ? _self.journeyTime : journeyTime // ignore: cast_nullable_to_non_nullable
as TimeControl?,
  ));
}

/// Create a copy of ClockSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeControlCopyWith<$Res> get speedrunTime {
  
  return $TimeControlCopyWith<$Res>(_self.speedrunTime, (value) {
    return _then(_self.copyWith(speedrunTime: value));
  });
}/// Create a copy of ClockSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeControlCopyWith<$Res>? get journeyTime {
    if (_self.journeyTime == null) {
    return null;
  }

  return $TimeControlCopyWith<$Res>(_self.journeyTime!, (value) {
    return _then(_self.copyWith(journeyTime: value));
  });
}
}

// dart format on
