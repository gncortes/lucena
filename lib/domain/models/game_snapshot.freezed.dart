// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GameSnapshot {

/// A posição em que a partida começou (FEN).
 String get startFen;/// Os lances jogados, em UCI (`e2e4`, `a7a8n`).
 List<String> get moves;/// O lado que aparece embaixo no tabuleiro.
 Side get orientation;/// O lado que o jogador move. Nulo: ele move os dois.
 Side? get playerSide;/// O relógio, em instantes. Nulo: partida sem relógio.
 ClockState? get clock;/// Se a tela da partida estava aberta quando isto foi gravado. Falso
/// quando o jogador saiu da partida por conta própria.
 bool get onScreen;
/// Create a copy of GameSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameSnapshotCopyWith<GameSnapshot> get copyWith => _$GameSnapshotCopyWithImpl<GameSnapshot>(this as GameSnapshot, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GameSnapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameSnapshot&&(identical(other.startFen, _this.startFen) || other.startFen == _this.startFen)&&const DeepCollectionEquality().equals(other.moves, _this.moves)&&(identical(other.orientation, _this.orientation) || other.orientation == _this.orientation)&&(identical(other.playerSide, _this.playerSide) || other.playerSide == _this.playerSide)&&(identical(other.clock, _this.clock) || other.clock == _this.clock)&&(identical(other.onScreen, _this.onScreen) || other.onScreen == _this.onScreen));
}


@override
int get hashCode {
  final _this = this as GameSnapshot;
  return Object.hash(runtimeType,_this.startFen,const DeepCollectionEquality().hash(_this.moves),_this.orientation,_this.playerSide,_this.clock,_this.onScreen);
}

@override
String toString() {
  final _this = this as GameSnapshot;
  return 'GameSnapshot(startFen: ${_this.startFen}, moves: ${_this.moves}, orientation: ${_this.orientation}, playerSide: ${_this.playerSide}, clock: ${_this.clock}, onScreen: ${_this.onScreen})';
}


}

/// @nodoc
abstract mixin class $GameSnapshotCopyWith<$Res>  {
  factory $GameSnapshotCopyWith(GameSnapshot value, $Res Function(GameSnapshot) _then) = _$GameSnapshotCopyWithImpl;
@useResult
$Res call({
 String startFen, List<String> moves, Side orientation, Side? playerSide, ClockState? clock, bool onScreen
});


$ClockStateCopyWith<$Res>? get clock;

}
/// @nodoc
class _$GameSnapshotCopyWithImpl<$Res>
    implements $GameSnapshotCopyWith<$Res> {
  _$GameSnapshotCopyWithImpl(this._self, this._then);

  final GameSnapshot _self;
  final $Res Function(GameSnapshot) _then;

/// Create a copy of GameSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startFen = null,Object? moves = null,Object? orientation = null,Object? playerSide = freezed,Object? clock = freezed,Object? onScreen = null,}) {
  return _then(GameSnapshot(
startFen: null == startFen ? _self.startFen : startFen // ignore: cast_nullable_to_non_nullable
as String,moves: null == moves ? _self.moves : moves // ignore: cast_nullable_to_non_nullable
as List<String>,orientation: null == orientation ? _self.orientation : orientation // ignore: cast_nullable_to_non_nullable
as Side,playerSide: freezed == playerSide ? _self.playerSide : playerSide // ignore: cast_nullable_to_non_nullable
as Side?,clock: freezed == clock ? _self.clock : clock // ignore: cast_nullable_to_non_nullable
as ClockState?,onScreen: null == onScreen ? _self.onScreen : onScreen // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of GameSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClockStateCopyWith<$Res>? get clock {
    if (_self.clock == null) {
    return null;
  }

  return $ClockStateCopyWith<$Res>(_self.clock!, (value) {
    return _then(_self.copyWith(clock: value));
  });
}
}


/// Adds pattern-matching-related methods to [GameSnapshot].
extension GameSnapshotPatterns on GameSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _GameSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _GameSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String startFen,  List<String> moves,  Side orientation,  Side? playerSide,  ClockState? clock,  bool onScreen)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameSnapshot() when $default != null:
return $default(_that.startFen,_that.moves,_that.orientation,_that.playerSide,_that.clock,_that.onScreen);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String startFen,  List<String> moves,  Side orientation,  Side? playerSide,  ClockState? clock,  bool onScreen)  $default,) {final _that = this;
switch (_that) {
case _GameSnapshot():
return $default(_that.startFen,_that.moves,_that.orientation,_that.playerSide,_that.clock,_that.onScreen);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String startFen,  List<String> moves,  Side orientation,  Side? playerSide,  ClockState? clock,  bool onScreen)?  $default,) {final _that = this;
switch (_that) {
case _GameSnapshot() when $default != null:
return $default(_that.startFen,_that.moves,_that.orientation,_that.playerSide,_that.clock,_that.onScreen);case _:
  return null;

}
}

}

/// @nodoc


class _GameSnapshot implements GameSnapshot {
  const _GameSnapshot({required this.startFen,  List<String> moves = const <String>[], this.orientation = Side.white, this.playerSide, this.clock, this.onScreen = true}): _moves = moves;
  

/// A posição em que a partida começou (FEN).
@override final  String startFen;
/// Os lances jogados, em UCI (`e2e4`, `a7a8n`).
 final  List<String> _moves;
/// Os lances jogados, em UCI (`e2e4`, `a7a8n`).
@override@JsonKey() List<String> get moves {
  if (_moves is EqualUnmodifiableListView) return _moves;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_moves);
}

/// O lado que aparece embaixo no tabuleiro.
@override@JsonKey() final  Side orientation;
/// O lado que o jogador move. Nulo: ele move os dois.
@override final  Side? playerSide;
/// O relógio, em instantes. Nulo: partida sem relógio.
@override final  ClockState? clock;
/// Se a tela da partida estava aberta quando isto foi gravado. Falso
/// quando o jogador saiu da partida por conta própria.
@override@JsonKey() final  bool onScreen;

/// Create a copy of GameSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameSnapshotCopyWith<_GameSnapshot> get copyWith => __$GameSnapshotCopyWithImpl<_GameSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameSnapshot&&(identical(other.startFen, startFen) || other.startFen == startFen)&&const DeepCollectionEquality().equals(other.moves, _moves)&&(identical(other.orientation, orientation) || other.orientation == orientation)&&(identical(other.playerSide, playerSide) || other.playerSide == playerSide)&&(identical(other.clock, clock) || other.clock == clock)&&(identical(other.onScreen, onScreen) || other.onScreen == onScreen));
}


@override
int get hashCode {
    return Object.hash(runtimeType,startFen,const DeepCollectionEquality().hash(_moves),orientation,playerSide,clock,onScreen);
}

@override
String toString() {
    return 'GameSnapshot(startFen: $startFen, moves: $moves, orientation: $orientation, playerSide: $playerSide, clock: $clock, onScreen: $onScreen)';
}


}

/// @nodoc
abstract mixin class _$GameSnapshotCopyWith<$Res> implements $GameSnapshotCopyWith<$Res> {
  factory _$GameSnapshotCopyWith(_GameSnapshot value, $Res Function(_GameSnapshot) _then) = __$GameSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String startFen, List<String> moves, Side orientation, Side? playerSide, ClockState? clock, bool onScreen
});


@override $ClockStateCopyWith<$Res>? get clock;

}
/// @nodoc
class __$GameSnapshotCopyWithImpl<$Res>
    implements _$GameSnapshotCopyWith<$Res> {
  __$GameSnapshotCopyWithImpl(this._self, this._then);

  final _GameSnapshot _self;
  final $Res Function(_GameSnapshot) _then;

/// Create a copy of GameSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startFen = null,Object? moves = null,Object? orientation = null,Object? playerSide = freezed,Object? clock = freezed,Object? onScreen = null,}) {
  return _then(_GameSnapshot(
startFen: null == startFen ? _self.startFen : startFen // ignore: cast_nullable_to_non_nullable
as String,moves: null == moves ? _self._moves : moves // ignore: cast_nullable_to_non_nullable
as List<String>,orientation: null == orientation ? _self.orientation : orientation // ignore: cast_nullable_to_non_nullable
as Side,playerSide: freezed == playerSide ? _self.playerSide : playerSide // ignore: cast_nullable_to_non_nullable
as Side?,clock: freezed == clock ? _self.clock : clock // ignore: cast_nullable_to_non_nullable
as ClockState?,onScreen: null == onScreen ? _self.onScreen : onScreen // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of GameSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClockStateCopyWith<$Res>? get clock {
    if (_self.clock == null) {
    return null;
  }

  return $ClockStateCopyWith<$Res>(_self.clock!, (value) {
    return _then(_self.copyWith(clock: value));
  });
}
}

// dart format on
