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
 bool get coordinates; MoveMethod get moveMethod;/// Com uma peça escolhida, marca as casas para onde ela pode ir.
 bool get showLegalMoves;/// Pinta as casas de origem e de destino do último lance.
 bool get highlightLastMove;/// A peça desliza até a casa em vez de pular.
 bool get animation;/// Lance feito antes, na vez do adversário, e jogado assim que ele responde.
 bool get premoves; MoveNotation get notation;
/// Create a copy of BoardSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BoardSettingsCopyWith<BoardSettings> get copyWith => _$BoardSettingsCopyWithImpl<BoardSettings>(this as BoardSettings, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BoardSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BoardSettings&&(identical(other.colors, _this.colors) || other.colors == _this.colors)&&(identical(other.pieces, _this.pieces) || other.pieces == _this.pieces)&&(identical(other.coordinates, _this.coordinates) || other.coordinates == _this.coordinates)&&(identical(other.moveMethod, _this.moveMethod) || other.moveMethod == _this.moveMethod)&&(identical(other.showLegalMoves, _this.showLegalMoves) || other.showLegalMoves == _this.showLegalMoves)&&(identical(other.highlightLastMove, _this.highlightLastMove) || other.highlightLastMove == _this.highlightLastMove)&&(identical(other.animation, _this.animation) || other.animation == _this.animation)&&(identical(other.premoves, _this.premoves) || other.premoves == _this.premoves)&&(identical(other.notation, _this.notation) || other.notation == _this.notation));
}


@override
int get hashCode {
  final _this = this as BoardSettings;
  return Object.hash(runtimeType,_this.colors,_this.pieces,_this.coordinates,_this.moveMethod,_this.showLegalMoves,_this.highlightLastMove,_this.animation,_this.premoves,_this.notation);
}

@override
String toString() {
  final _this = this as BoardSettings;
  return 'BoardSettings(colors: ${_this.colors}, pieces: ${_this.pieces}, coordinates: ${_this.coordinates}, moveMethod: ${_this.moveMethod}, showLegalMoves: ${_this.showLegalMoves}, highlightLastMove: ${_this.highlightLastMove}, animation: ${_this.animation}, premoves: ${_this.premoves}, notation: ${_this.notation})';
}


}

/// @nodoc
abstract mixin class $BoardSettingsCopyWith<$Res>  {
  factory $BoardSettingsCopyWith(BoardSettings value, $Res Function(BoardSettings) _then) = _$BoardSettingsCopyWithImpl;
@useResult
$Res call({
 BoardColors colors, PieceStyle pieces, bool coordinates, MoveMethod moveMethod, bool showLegalMoves, bool highlightLastMove, bool animation, bool premoves, MoveNotation notation
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
@pragma('vm:prefer-inline') @override $Res call({Object? colors = null,Object? pieces = null,Object? coordinates = null,Object? moveMethod = null,Object? showLegalMoves = null,Object? highlightLastMove = null,Object? animation = null,Object? premoves = null,Object? notation = null,}) {
  return _then(BoardSettings(
colors: null == colors ? _self.colors : colors // ignore: cast_nullable_to_non_nullable
as BoardColors,pieces: null == pieces ? _self.pieces : pieces // ignore: cast_nullable_to_non_nullable
as PieceStyle,coordinates: null == coordinates ? _self.coordinates : coordinates // ignore: cast_nullable_to_non_nullable
as bool,moveMethod: null == moveMethod ? _self.moveMethod : moveMethod // ignore: cast_nullable_to_non_nullable
as MoveMethod,showLegalMoves: null == showLegalMoves ? _self.showLegalMoves : showLegalMoves // ignore: cast_nullable_to_non_nullable
as bool,highlightLastMove: null == highlightLastMove ? _self.highlightLastMove : highlightLastMove // ignore: cast_nullable_to_non_nullable
as bool,animation: null == animation ? _self.animation : animation // ignore: cast_nullable_to_non_nullable
as bool,premoves: null == premoves ? _self.premoves : premoves // ignore: cast_nullable_to_non_nullable
as bool,notation: null == notation ? _self.notation : notation // ignore: cast_nullable_to_non_nullable
as MoveNotation,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BoardColors colors,  PieceStyle pieces,  bool coordinates,  MoveMethod moveMethod,  bool showLegalMoves,  bool highlightLastMove,  bool animation,  bool premoves,  MoveNotation notation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BoardSettings() when $default != null:
return $default(_that.colors,_that.pieces,_that.coordinates,_that.moveMethod,_that.showLegalMoves,_that.highlightLastMove,_that.animation,_that.premoves,_that.notation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BoardColors colors,  PieceStyle pieces,  bool coordinates,  MoveMethod moveMethod,  bool showLegalMoves,  bool highlightLastMove,  bool animation,  bool premoves,  MoveNotation notation)  $default,) {final _that = this;
switch (_that) {
case _BoardSettings():
return $default(_that.colors,_that.pieces,_that.coordinates,_that.moveMethod,_that.showLegalMoves,_that.highlightLastMove,_that.animation,_that.premoves,_that.notation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BoardColors colors,  PieceStyle pieces,  bool coordinates,  MoveMethod moveMethod,  bool showLegalMoves,  bool highlightLastMove,  bool animation,  bool premoves,  MoveNotation notation)?  $default,) {final _that = this;
switch (_that) {
case _BoardSettings() when $default != null:
return $default(_that.colors,_that.pieces,_that.coordinates,_that.moveMethod,_that.showLegalMoves,_that.highlightLastMove,_that.animation,_that.premoves,_that.notation);case _:
  return null;

}
}

}

/// @nodoc


class _BoardSettings extends BoardSettings {
  const _BoardSettings({this.colors = BoardColors.fallback, this.pieces = PieceStyle.fallback, this.coordinates = true, this.moveMethod = MoveMethod.fallback, this.showLegalMoves = true, this.highlightLastMove = true, this.animation = true, this.premoves = true, this.notation = MoveNotation.fallback}): super._();
  

@override@JsonKey() final  BoardColors colors;
@override@JsonKey() final  PieceStyle pieces;
/// Letras e números das casas na borda do tabuleiro.
@override@JsonKey() final  bool coordinates;
@override@JsonKey() final  MoveMethod moveMethod;
/// Com uma peça escolhida, marca as casas para onde ela pode ir.
@override@JsonKey() final  bool showLegalMoves;
/// Pinta as casas de origem e de destino do último lance.
@override@JsonKey() final  bool highlightLastMove;
/// A peça desliza até a casa em vez de pular.
@override@JsonKey() final  bool animation;
/// Lance feito antes, na vez do adversário, e jogado assim que ele responde.
@override@JsonKey() final  bool premoves;
@override@JsonKey() final  MoveNotation notation;

/// Create a copy of BoardSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BoardSettingsCopyWith<_BoardSettings> get copyWith => __$BoardSettingsCopyWithImpl<_BoardSettings>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BoardSettings&&(identical(other.colors, colors) || other.colors == colors)&&(identical(other.pieces, pieces) || other.pieces == pieces)&&(identical(other.coordinates, coordinates) || other.coordinates == coordinates)&&(identical(other.moveMethod, moveMethod) || other.moveMethod == moveMethod)&&(identical(other.showLegalMoves, showLegalMoves) || other.showLegalMoves == showLegalMoves)&&(identical(other.highlightLastMove, highlightLastMove) || other.highlightLastMove == highlightLastMove)&&(identical(other.animation, animation) || other.animation == animation)&&(identical(other.premoves, premoves) || other.premoves == premoves)&&(identical(other.notation, notation) || other.notation == notation));
}


@override
int get hashCode {
    return Object.hash(runtimeType,colors,pieces,coordinates,moveMethod,showLegalMoves,highlightLastMove,animation,premoves,notation);
}

@override
String toString() {
    return 'BoardSettings(colors: $colors, pieces: $pieces, coordinates: $coordinates, moveMethod: $moveMethod, showLegalMoves: $showLegalMoves, highlightLastMove: $highlightLastMove, animation: $animation, premoves: $premoves, notation: $notation)';
}


}

/// @nodoc
abstract mixin class _$BoardSettingsCopyWith<$Res> implements $BoardSettingsCopyWith<$Res> {
  factory _$BoardSettingsCopyWith(_BoardSettings value, $Res Function(_BoardSettings) _then) = __$BoardSettingsCopyWithImpl;
@override @useResult
$Res call({
 BoardColors colors, PieceStyle pieces, bool coordinates, MoveMethod moveMethod, bool showLegalMoves, bool highlightLastMove, bool animation, bool premoves, MoveNotation notation
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
@override @pragma('vm:prefer-inline') $Res call({Object? colors = null,Object? pieces = null,Object? coordinates = null,Object? moveMethod = null,Object? showLegalMoves = null,Object? highlightLastMove = null,Object? animation = null,Object? premoves = null,Object? notation = null,}) {
  return _then(_BoardSettings(
colors: null == colors ? _self.colors : colors // ignore: cast_nullable_to_non_nullable
as BoardColors,pieces: null == pieces ? _self.pieces : pieces // ignore: cast_nullable_to_non_nullable
as PieceStyle,coordinates: null == coordinates ? _self.coordinates : coordinates // ignore: cast_nullable_to_non_nullable
as bool,moveMethod: null == moveMethod ? _self.moveMethod : moveMethod // ignore: cast_nullable_to_non_nullable
as MoveMethod,showLegalMoves: null == showLegalMoves ? _self.showLegalMoves : showLegalMoves // ignore: cast_nullable_to_non_nullable
as bool,highlightLastMove: null == highlightLastMove ? _self.highlightLastMove : highlightLastMove // ignore: cast_nullable_to_non_nullable
as bool,animation: null == animation ? _self.animation : animation // ignore: cast_nullable_to_non_nullable
as bool,premoves: null == premoves ? _self.premoves : premoves // ignore: cast_nullable_to_non_nullable
as bool,notation: null == notation ? _self.notation : notation // ignore: cast_nullable_to_non_nullable
as MoveNotation,
  ));
}


}

// dart format on
