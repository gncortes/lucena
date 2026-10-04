// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppSettings {

/// Código do idioma escolhido (`es`, `pt_PT`...). Nulo segue o sistema.
 String? get languageCode;/// Tema claro, escuro ou o do aparelho.
 AppThemeMode get themeMode;/// Aparência e comportamento do tabuleiro.
 BoardSettings get board;/// Onde o relógio aparece e como ele avisa.
 ClockSettings get clock;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.languageCode, _this.languageCode) || other.languageCode == _this.languageCode)&&(identical(other.themeMode, _this.themeMode) || other.themeMode == _this.themeMode)&&(identical(other.board, _this.board) || other.board == _this.board)&&(identical(other.clock, _this.clock) || other.clock == _this.clock));
}


@override
int get hashCode {
  final _this = this as AppSettings;
  return Object.hash(runtimeType,_this.languageCode,_this.themeMode,_this.board,_this.clock);
}

@override
String toString() {
  final _this = this as AppSettings;
  return 'AppSettings(languageCode: ${_this.languageCode}, themeMode: ${_this.themeMode}, board: ${_this.board}, clock: ${_this.clock})';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 String? languageCode, AppThemeMode themeMode, BoardSettings board, ClockSettings clock
});


$BoardSettingsCopyWith<$Res> get board;$ClockSettingsCopyWith<$Res> get clock;

}
/// @nodoc
class _$AppSettingsCopyWithImpl<$Res>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? languageCode = freezed,Object? themeMode = null,Object? board = null,Object? clock = null,}) {
  return _then(AppSettings(
languageCode: freezed == languageCode ? _self.languageCode : languageCode // ignore: cast_nullable_to_non_nullable
as String?,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as AppThemeMode,board: null == board ? _self.board : board // ignore: cast_nullable_to_non_nullable
as BoardSettings,clock: null == clock ? _self.clock : clock // ignore: cast_nullable_to_non_nullable
as ClockSettings,
  ));
}
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoardSettingsCopyWith<$Res> get board {
  
  return $BoardSettingsCopyWith<$Res>(_self.board, (value) {
    return _then(_self.copyWith(board: value));
  });
}/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClockSettingsCopyWith<$Res> get clock {
  
  return $ClockSettingsCopyWith<$Res>(_self.clock, (value) {
    return _then(_self.copyWith(clock: value));
  });
}
}


/// Adds pattern-matching-related methods to [AppSettings].
extension AppSettingsPatterns on AppSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSettings value)  $default,){
final _that = this;
switch (_that) {
case _AppSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? languageCode,  AppThemeMode themeMode,  BoardSettings board,  ClockSettings clock)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.languageCode,_that.themeMode,_that.board,_that.clock);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? languageCode,  AppThemeMode themeMode,  BoardSettings board,  ClockSettings clock)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.languageCode,_that.themeMode,_that.board,_that.clock);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? languageCode,  AppThemeMode themeMode,  BoardSettings board,  ClockSettings clock)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.languageCode,_that.themeMode,_that.board,_that.clock);case _:
  return null;

}
}

}

/// @nodoc


class _AppSettings implements AppSettings {
  const _AppSettings({this.languageCode, this.themeMode = AppThemeMode.system, this.board = const BoardSettings(), this.clock = const ClockSettings()});
  

/// Código do idioma escolhido (`es`, `pt_PT`...). Nulo segue o sistema.
@override final  String? languageCode;
/// Tema claro, escuro ou o do aparelho.
@override@JsonKey() final  AppThemeMode themeMode;
/// Aparência e comportamento do tabuleiro.
@override@JsonKey() final  BoardSettings board;
/// Onde o relógio aparece e como ele avisa.
@override@JsonKey() final  ClockSettings clock;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsCopyWith<_AppSettings> get copyWith => __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.languageCode, languageCode) || other.languageCode == languageCode)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.board, board) || other.board == board)&&(identical(other.clock, clock) || other.clock == clock));
}


@override
int get hashCode {
    return Object.hash(runtimeType,languageCode,themeMode,board,clock);
}

@override
String toString() {
    return 'AppSettings(languageCode: $languageCode, themeMode: $themeMode, board: $board, clock: $clock)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 String? languageCode, AppThemeMode themeMode, BoardSettings board, ClockSettings clock
});


@override $BoardSettingsCopyWith<$Res> get board;@override $ClockSettingsCopyWith<$Res> get clock;

}
/// @nodoc
class __$AppSettingsCopyWithImpl<$Res>
    implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? languageCode = freezed,Object? themeMode = null,Object? board = null,Object? clock = null,}) {
  return _then(_AppSettings(
languageCode: freezed == languageCode ? _self.languageCode : languageCode // ignore: cast_nullable_to_non_nullable
as String?,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as AppThemeMode,board: null == board ? _self.board : board // ignore: cast_nullable_to_non_nullable
as BoardSettings,clock: null == clock ? _self.clock : clock // ignore: cast_nullable_to_non_nullable
as ClockSettings,
  ));
}

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoardSettingsCopyWith<$Res> get board {
  
  return $BoardSettingsCopyWith<$Res>(_self.board, (value) {
    return _then(_self.copyWith(board: value));
  });
}/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClockSettingsCopyWith<$Res> get clock {
  
  return $ClockSettingsCopyWith<$Res>(_self.clock, (value) {
    return _then(_self.copyWith(clock: value));
  });
}
}

// dart format on
