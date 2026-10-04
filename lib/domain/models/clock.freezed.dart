// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'clock.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TimeControl {

 Duration get initial; Duration get increment;
/// Create a copy of TimeControl
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimeControlCopyWith<TimeControl> get copyWith => _$TimeControlCopyWithImpl<TimeControl>(this as TimeControl, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TimeControl;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeControl&&(identical(other.initial, _this.initial) || other.initial == _this.initial)&&(identical(other.increment, _this.increment) || other.increment == _this.increment));
}


@override
int get hashCode {
  final _this = this as TimeControl;
  return Object.hash(runtimeType,_this.initial,_this.increment);
}

@override
String toString() {
  final _this = this as TimeControl;
  return 'TimeControl(initial: ${_this.initial}, increment: ${_this.increment})';
}


}

/// @nodoc
abstract mixin class $TimeControlCopyWith<$Res>  {
  factory $TimeControlCopyWith(TimeControl value, $Res Function(TimeControl) _then) = _$TimeControlCopyWithImpl;
@useResult
$Res call({
 Duration initial, Duration increment
});




}
/// @nodoc
class _$TimeControlCopyWithImpl<$Res>
    implements $TimeControlCopyWith<$Res> {
  _$TimeControlCopyWithImpl(this._self, this._then);

  final TimeControl _self;
  final $Res Function(TimeControl) _then;

/// Create a copy of TimeControl
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? initial = null,Object? increment = null,}) {
  return _then(TimeControl(
initial: null == initial ? _self.initial : initial // ignore: cast_nullable_to_non_nullable
as Duration,increment: null == increment ? _self.increment : increment // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}

}


/// Adds pattern-matching-related methods to [TimeControl].
extension TimeControlPatterns on TimeControl {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TimeControl value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TimeControl() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TimeControl value)  $default,){
final _that = this;
switch (_that) {
case _TimeControl():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TimeControl value)?  $default,){
final _that = this;
switch (_that) {
case _TimeControl() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Duration initial,  Duration increment)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TimeControl() when $default != null:
return $default(_that.initial,_that.increment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Duration initial,  Duration increment)  $default,) {final _that = this;
switch (_that) {
case _TimeControl():
return $default(_that.initial,_that.increment);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Duration initial,  Duration increment)?  $default,) {final _that = this;
switch (_that) {
case _TimeControl() when $default != null:
return $default(_that.initial,_that.increment);case _:
  return null;

}
}

}

/// @nodoc


class _TimeControl extends TimeControl {
  const _TimeControl({required this.initial, this.increment = Duration.zero}): super._();
  

@override final  Duration initial;
@override@JsonKey() final  Duration increment;

/// Create a copy of TimeControl
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TimeControlCopyWith<_TimeControl> get copyWith => __$TimeControlCopyWithImpl<_TimeControl>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TimeControl&&(identical(other.initial, initial) || other.initial == initial)&&(identical(other.increment, increment) || other.increment == increment));
}


@override
int get hashCode {
    return Object.hash(runtimeType,initial,increment);
}

@override
String toString() {
    return 'TimeControl(initial: $initial, increment: $increment)';
}


}

/// @nodoc
abstract mixin class _$TimeControlCopyWith<$Res> implements $TimeControlCopyWith<$Res> {
  factory _$TimeControlCopyWith(_TimeControl value, $Res Function(_TimeControl) _then) = __$TimeControlCopyWithImpl;
@override @useResult
$Res call({
 Duration initial, Duration increment
});




}
/// @nodoc
class __$TimeControlCopyWithImpl<$Res>
    implements _$TimeControlCopyWith<$Res> {
  __$TimeControlCopyWithImpl(this._self, this._then);

  final _TimeControl _self;
  final $Res Function(_TimeControl) _then;

/// Create a copy of TimeControl
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? initial = null,Object? increment = null,}) {
  return _then(_TimeControl(
initial: null == initial ? _self.initial : initial // ignore: cast_nullable_to_non_nullable
as Duration,increment: null == increment ? _self.increment : increment // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

/// @nodoc
mixin _$ClockConfig {

 TimeControl get white; TimeControl get black;
/// Create a copy of ClockConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClockConfigCopyWith<ClockConfig> get copyWith => _$ClockConfigCopyWithImpl<ClockConfig>(this as ClockConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ClockConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClockConfig&&(identical(other.white, _this.white) || other.white == _this.white)&&(identical(other.black, _this.black) || other.black == _this.black));
}


@override
int get hashCode {
  final _this = this as ClockConfig;
  return Object.hash(runtimeType,_this.white,_this.black);
}

@override
String toString() {
  final _this = this as ClockConfig;
  return 'ClockConfig(white: ${_this.white}, black: ${_this.black})';
}


}

/// @nodoc
abstract mixin class $ClockConfigCopyWith<$Res>  {
  factory $ClockConfigCopyWith(ClockConfig value, $Res Function(ClockConfig) _then) = _$ClockConfigCopyWithImpl;
@useResult
$Res call({
 TimeControl white, TimeControl black
});


$TimeControlCopyWith<$Res> get white;$TimeControlCopyWith<$Res> get black;

}
/// @nodoc
class _$ClockConfigCopyWithImpl<$Res>
    implements $ClockConfigCopyWith<$Res> {
  _$ClockConfigCopyWithImpl(this._self, this._then);

  final ClockConfig _self;
  final $Res Function(ClockConfig) _then;

/// Create a copy of ClockConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? white = null,Object? black = null,}) {
  return _then(ClockConfig(
white: null == white ? _self.white : white // ignore: cast_nullable_to_non_nullable
as TimeControl,black: null == black ? _self.black : black // ignore: cast_nullable_to_non_nullable
as TimeControl,
  ));
}
/// Create a copy of ClockConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeControlCopyWith<$Res> get white {
  
  return $TimeControlCopyWith<$Res>(_self.white, (value) {
    return _then(_self.copyWith(white: value));
  });
}/// Create a copy of ClockConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeControlCopyWith<$Res> get black {
  
  return $TimeControlCopyWith<$Res>(_self.black, (value) {
    return _then(_self.copyWith(black: value));
  });
}
}


/// Adds pattern-matching-related methods to [ClockConfig].
extension ClockConfigPatterns on ClockConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClockConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClockConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClockConfig value)  $default,){
final _that = this;
switch (_that) {
case _ClockConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClockConfig value)?  $default,){
final _that = this;
switch (_that) {
case _ClockConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TimeControl white,  TimeControl black)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClockConfig() when $default != null:
return $default(_that.white,_that.black);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TimeControl white,  TimeControl black)  $default,) {final _that = this;
switch (_that) {
case _ClockConfig():
return $default(_that.white,_that.black);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TimeControl white,  TimeControl black)?  $default,) {final _that = this;
switch (_that) {
case _ClockConfig() when $default != null:
return $default(_that.white,_that.black);case _:
  return null;

}
}

}

/// @nodoc


class _ClockConfig extends ClockConfig {
  const _ClockConfig({required this.white, required this.black}): super._();
  

@override final  TimeControl white;
@override final  TimeControl black;

/// Create a copy of ClockConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClockConfigCopyWith<_ClockConfig> get copyWith => __$ClockConfigCopyWithImpl<_ClockConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClockConfig&&(identical(other.white, white) || other.white == white)&&(identical(other.black, black) || other.black == black));
}


@override
int get hashCode {
    return Object.hash(runtimeType,white,black);
}

@override
String toString() {
    return 'ClockConfig(white: $white, black: $black)';
}


}

/// @nodoc
abstract mixin class _$ClockConfigCopyWith<$Res> implements $ClockConfigCopyWith<$Res> {
  factory _$ClockConfigCopyWith(_ClockConfig value, $Res Function(_ClockConfig) _then) = __$ClockConfigCopyWithImpl;
@override @useResult
$Res call({
 TimeControl white, TimeControl black
});


@override $TimeControlCopyWith<$Res> get white;@override $TimeControlCopyWith<$Res> get black;

}
/// @nodoc
class __$ClockConfigCopyWithImpl<$Res>
    implements _$ClockConfigCopyWith<$Res> {
  __$ClockConfigCopyWithImpl(this._self, this._then);

  final _ClockConfig _self;
  final $Res Function(_ClockConfig) _then;

/// Create a copy of ClockConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? white = null,Object? black = null,}) {
  return _then(_ClockConfig(
white: null == white ? _self.white : white // ignore: cast_nullable_to_non_nullable
as TimeControl,black: null == black ? _self.black : black // ignore: cast_nullable_to_non_nullable
as TimeControl,
  ));
}

/// Create a copy of ClockConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeControlCopyWith<$Res> get white {
  
  return $TimeControlCopyWith<$Res>(_self.white, (value) {
    return _then(_self.copyWith(white: value));
  });
}/// Create a copy of ClockConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeControlCopyWith<$Res> get black {
  
  return $TimeControlCopyWith<$Res>(_self.black, (value) {
    return _then(_self.copyWith(black: value));
  });
}
}

/// @nodoc
mixin _$ClockState {

 ClockConfig get config;/// Quanto as brancas tinham no começo da vez atual (ou ao parar).
 Duration get white;/// Quanto as pretas tinham no começo da vez atual (ou ao parar).
 Duration get black;/// De quem é o relógio que está correndo. Nulo: relógio parado.
 Side? get running;/// Quando a vez de [running] começou.
 DateTime? get turnStartedAt;
/// Create a copy of ClockState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClockStateCopyWith<ClockState> get copyWith => _$ClockStateCopyWithImpl<ClockState>(this as ClockState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ClockState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClockState&&(identical(other.config, _this.config) || other.config == _this.config)&&(identical(other.white, _this.white) || other.white == _this.white)&&(identical(other.black, _this.black) || other.black == _this.black)&&(identical(other.running, _this.running) || other.running == _this.running)&&(identical(other.turnStartedAt, _this.turnStartedAt) || other.turnStartedAt == _this.turnStartedAt));
}


@override
int get hashCode {
  final _this = this as ClockState;
  return Object.hash(runtimeType,_this.config,_this.white,_this.black,_this.running,_this.turnStartedAt);
}

@override
String toString() {
  final _this = this as ClockState;
  return 'ClockState(config: ${_this.config}, white: ${_this.white}, black: ${_this.black}, running: ${_this.running}, turnStartedAt: ${_this.turnStartedAt})';
}


}

/// @nodoc
abstract mixin class $ClockStateCopyWith<$Res>  {
  factory $ClockStateCopyWith(ClockState value, $Res Function(ClockState) _then) = _$ClockStateCopyWithImpl;
@useResult
$Res call({
 ClockConfig config, Duration white, Duration black, Side? running, DateTime? turnStartedAt
});


$ClockConfigCopyWith<$Res> get config;

}
/// @nodoc
class _$ClockStateCopyWithImpl<$Res>
    implements $ClockStateCopyWith<$Res> {
  _$ClockStateCopyWithImpl(this._self, this._then);

  final ClockState _self;
  final $Res Function(ClockState) _then;

/// Create a copy of ClockState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? config = null,Object? white = null,Object? black = null,Object? running = freezed,Object? turnStartedAt = freezed,}) {
  return _then(ClockState(
config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as ClockConfig,white: null == white ? _self.white : white // ignore: cast_nullable_to_non_nullable
as Duration,black: null == black ? _self.black : black // ignore: cast_nullable_to_non_nullable
as Duration,running: freezed == running ? _self.running : running // ignore: cast_nullable_to_non_nullable
as Side?,turnStartedAt: freezed == turnStartedAt ? _self.turnStartedAt : turnStartedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of ClockState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClockConfigCopyWith<$Res> get config {
  
  return $ClockConfigCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}
}


/// Adds pattern-matching-related methods to [ClockState].
extension ClockStatePatterns on ClockState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClockState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClockState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClockState value)  $default,){
final _that = this;
switch (_that) {
case _ClockState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClockState value)?  $default,){
final _that = this;
switch (_that) {
case _ClockState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ClockConfig config,  Duration white,  Duration black,  Side? running,  DateTime? turnStartedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClockState() when $default != null:
return $default(_that.config,_that.white,_that.black,_that.running,_that.turnStartedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ClockConfig config,  Duration white,  Duration black,  Side? running,  DateTime? turnStartedAt)  $default,) {final _that = this;
switch (_that) {
case _ClockState():
return $default(_that.config,_that.white,_that.black,_that.running,_that.turnStartedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ClockConfig config,  Duration white,  Duration black,  Side? running,  DateTime? turnStartedAt)?  $default,) {final _that = this;
switch (_that) {
case _ClockState() when $default != null:
return $default(_that.config,_that.white,_that.black,_that.running,_that.turnStartedAt);case _:
  return null;

}
}

}

/// @nodoc


class _ClockState extends ClockState {
  const _ClockState({required this.config, required this.white, required this.black, this.running, this.turnStartedAt}): super._();
  

@override final  ClockConfig config;
/// Quanto as brancas tinham no começo da vez atual (ou ao parar).
@override final  Duration white;
/// Quanto as pretas tinham no começo da vez atual (ou ao parar).
@override final  Duration black;
/// De quem é o relógio que está correndo. Nulo: relógio parado.
@override final  Side? running;
/// Quando a vez de [running] começou.
@override final  DateTime? turnStartedAt;

/// Create a copy of ClockState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClockStateCopyWith<_ClockState> get copyWith => __$ClockStateCopyWithImpl<_ClockState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClockState&&(identical(other.config, config) || other.config == config)&&(identical(other.white, white) || other.white == white)&&(identical(other.black, black) || other.black == black)&&(identical(other.running, running) || other.running == running)&&(identical(other.turnStartedAt, turnStartedAt) || other.turnStartedAt == turnStartedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,config,white,black,running,turnStartedAt);
}

@override
String toString() {
    return 'ClockState(config: $config, white: $white, black: $black, running: $running, turnStartedAt: $turnStartedAt)';
}


}

/// @nodoc
abstract mixin class _$ClockStateCopyWith<$Res> implements $ClockStateCopyWith<$Res> {
  factory _$ClockStateCopyWith(_ClockState value, $Res Function(_ClockState) _then) = __$ClockStateCopyWithImpl;
@override @useResult
$Res call({
 ClockConfig config, Duration white, Duration black, Side? running, DateTime? turnStartedAt
});


@override $ClockConfigCopyWith<$Res> get config;

}
/// @nodoc
class __$ClockStateCopyWithImpl<$Res>
    implements _$ClockStateCopyWith<$Res> {
  __$ClockStateCopyWithImpl(this._self, this._then);

  final _ClockState _self;
  final $Res Function(_ClockState) _then;

/// Create a copy of ClockState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? config = null,Object? white = null,Object? black = null,Object? running = freezed,Object? turnStartedAt = freezed,}) {
  return _then(_ClockState(
config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as ClockConfig,white: null == white ? _self.white : white // ignore: cast_nullable_to_non_nullable
as Duration,black: null == black ? _self.black : black // ignore: cast_nullable_to_non_nullable
as Duration,running: freezed == running ? _self.running : running // ignore: cast_nullable_to_non_nullable
as Side?,turnStartedAt: freezed == turnStartedAt ? _self.turnStartedAt : turnStartedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of ClockState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClockConfigCopyWith<$Res> get config {
  
  return $ClockConfigCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}
}

// dart format on
