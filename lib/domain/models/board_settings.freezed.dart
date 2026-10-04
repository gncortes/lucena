// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'board_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BoardSettings {

 BoardColors get colors; PieceStyle get pieces;/// Letras e números das casas na borda do tabuleiro.
 bool get coordinates;
/// Create a copy of BoardSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BoardSettingsCopyWith<BoardSettings> get copyWith => _$BoardSettingsCopyWithImpl<BoardSettings>(this as BoardSettings, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BoardSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BoardSettings&&(identical(other.colors, _this.colors) || other.colors == _this.colors)&&(identical(other.pieces, _this.pieces) || other.pieces == _this.pieces)&&(identical(other.coordinates, _this.coordinates) || other.coordinates == _this.coordinates));
}


@override
int get hashCode {
  final _this = this as BoardSettings;
  return Object.hash(runtimeType,_this.colors,_this.pieces,_this.coordinates);
}

@override
String toString() {
  final _this = this as BoardSettings;
  return 'BoardSettings(colors: ${_this.colors}, pieces: ${_this.pieces}, coordinates: ${_this.coordinates})';
}


}

/// @nodoc
abstract mixin class $BoardSettingsCopyWith<$Res>  {
  factory $BoardSettingsCopyWith(BoardSettings value, $Res Function(BoardSettings) _then) = _$BoardSettingsCopyWithImpl;
@useResult
$Res call({
 BoardColors colors, PieceStyle pieces, bool coordinates
});




}
/// @nodoc
class _$BoardSettingsCopyWithImpl<$Res>
    implements $BoardSettingsCopyWith<$Res> {
  _$BoardSettingsCopyWithImpl(this._self, this._then);

  final BoardSettings _self;
  final $Res Function(BoardSettings) _then;

/// Create a copy of BoardSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? colors = null,Object? pieces = null,Object? coordinates = null,}) {
  return _then(BoardSettings(
colors: null == colors ? _self.colors : colors // ignore: cast_nullable_to_non_nullable
as BoardColors,pieces: null == pieces ? _self.pieces : pieces // ignore: cast_nullable_to_non_nullable
as PieceStyle,coordinates: null == coordinates ? _self.coordinates : coordinates // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [BoardSettings].
extension BoardSettingsPatterns on BoardSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BoardSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BoardSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BoardSettings value)  $default,){
final _that = this;
switch (_that) {
case _BoardSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BoardSettings value)?  $default,){
final _that = this;
switch (_that) {
case _BoardSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BoardColors colors,  PieceStyle pieces,  bool coordinates)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BoardSettings() when $default != null:
return $default(_that.colors,_that.pieces,_that.coordinates);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BoardColors colors,  PieceStyle pieces,  bool coordinates)  $default,) {final _that = this;
switch (_that) {
case _BoardSettings():
return $default(_that.colors,_that.pieces,_that.coordinates);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BoardColors colors,  PieceStyle pieces,  bool coordinates)?  $default,) {final _that = this;
switch (_that) {
case _BoardSettings() when $default != null:
return $default(_that.colors,_that.pieces,_that.coordinates);case _:
  return null;

}
}

}

/// @nodoc


class _BoardSettings extends BoardSettings {
  const _BoardSettings({this.colors = BoardColors.fallback, this.pieces = PieceStyle.fallback, this.coordinates = true}): super._();
  

@override@JsonKey() final  BoardColors colors;
@override@JsonKey() final  PieceStyle pieces;
/// Letras e números das casas na borda do tabuleiro.
@override@JsonKey() final  bool coordinates;

/// Create a copy of BoardSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BoardSettingsCopyWith<_BoardSettings> get copyWith => __$BoardSettingsCopyWithImpl<_BoardSettings>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BoardSettings&&(identical(other.colors, colors) || other.colors == colors)&&(identical(other.pieces, pieces) || other.pieces == pieces)&&(identical(other.coordinates, coordinates) || other.coordinates == coordinates));
}


@override
int get hashCode {
    return Object.hash(runtimeType,colors,pieces,coordinates);
}

@override
String toString() {
    return 'BoardSettings(colors: $colors, pieces: $pieces, coordinates: $coordinates)';
}


}

/// @nodoc
abstract mixin class _$BoardSettingsCopyWith<$Res> implements $BoardSettingsCopyWith<$Res> {
  factory _$BoardSettingsCopyWith(_BoardSettings value, $Res Function(_BoardSettings) _then) = __$BoardSettingsCopyWithImpl;
@override @useResult
$Res call({
 BoardColors colors, PieceStyle pieces, bool coordinates
});




}
/// @nodoc
class __$BoardSettingsCopyWithImpl<$Res>
    implements _$BoardSettingsCopyWith<$Res> {
  __$BoardSettingsCopyWithImpl(this._self, this._then);

  final _BoardSettings _self;
  final $Res Function(_BoardSettings) _then;

/// Create a copy of BoardSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? colors = null,Object? pieces = null,Object? coordinates = null,}) {
  return _then(_BoardSettings(
colors: null == colors ? _self.colors : colors // ignore: cast_nullable_to_non_nullable
as BoardColors,pieces: null == pieces ? _self.pieces : pieces // ignore: cast_nullable_to_non_nullable
as PieceStyle,coordinates: null == coordinates ? _self.coordinates : coordinates // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
