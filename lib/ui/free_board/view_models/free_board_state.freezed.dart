// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'free_board_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FreeBoardState {

/// A posição em que o tabuleiro abriu; "nova partida" volta para ela.
 Position get start;/// A posição atual.
 Position get position;/// Os lances jogados, em notação algébrica (`e4`, `Nf3`, `O-O`).
 List<String> get moves;/// O último lance, para o tabuleiro destacar.
 Move? get lastMove;/// O lado que aparece embaixo no tabuleiro.
 Side get orientation;/// O lado que o jogador move. Nulo: ele move os dois.
 Side? get playerSide;
/// Create a copy of FreeBoardState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FreeBoardStateCopyWith<FreeBoardState> get copyWith => _$FreeBoardStateCopyWithImpl<FreeBoardState>(this as FreeBoardState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FreeBoardState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FreeBoardState&&(identical(other.start, _this.start) || other.start == _this.start)&&(identical(other.position, _this.position) || other.position == _this.position)&&const DeepCollectionEquality().equals(other.moves, _this.moves)&&(identical(other.lastMove, _this.lastMove) || other.lastMove == _this.lastMove)&&(identical(other.orientation, _this.orientation) || other.orientation == _this.orientation)&&(identical(other.playerSide, _this.playerSide) || other.playerSide == _this.playerSide));
}


@override
int get hashCode {
  final _this = this as FreeBoardState;
  return Object.hash(runtimeType,_this.start,_this.position,const DeepCollectionEquality().hash(_this.moves),_this.lastMove,_this.orientation,_this.playerSide);
}

@override
String toString() {
  final _this = this as FreeBoardState;
  return 'FreeBoardState(start: ${_this.start}, position: ${_this.position}, moves: ${_this.moves}, lastMove: ${_this.lastMove}, orientation: ${_this.orientation}, playerSide: ${_this.playerSide})';
}


}

/// @nodoc
abstract mixin class $FreeBoardStateCopyWith<$Res>  {
  factory $FreeBoardStateCopyWith(FreeBoardState value, $Res Function(FreeBoardState) _then) = _$FreeBoardStateCopyWithImpl;
@useResult
$Res call({
 Position start, Position position, List<String> moves, Move? lastMove, Side orientation, Side? playerSide
});




}
/// @nodoc
class _$FreeBoardStateCopyWithImpl<$Res>
    implements $FreeBoardStateCopyWith<$Res> {
  _$FreeBoardStateCopyWithImpl(this._self, this._then);

  final FreeBoardState _self;
  final $Res Function(FreeBoardState) _then;

/// Create a copy of FreeBoardState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? start = null,Object? position = null,Object? moves = null,Object? lastMove = freezed,Object? orientation = null,Object? playerSide = freezed,}) {
  return _then(FreeBoardState(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as Position,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Position,moves: null == moves ? _self.moves : moves // ignore: cast_nullable_to_non_nullable
as List<String>,lastMove: freezed == lastMove ? _self.lastMove : lastMove // ignore: cast_nullable_to_non_nullable
as Move?,orientation: null == orientation ? _self.orientation : orientation // ignore: cast_nullable_to_non_nullable
as Side,playerSide: freezed == playerSide ? _self.playerSide : playerSide // ignore: cast_nullable_to_non_nullable
as Side?,
  ));
}

}


/// Adds pattern-matching-related methods to [FreeBoardState].
extension FreeBoardStatePatterns on FreeBoardState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FreeBoardState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FreeBoardState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FreeBoardState value)  $default,){
final _that = this;
switch (_that) {
case _FreeBoardState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FreeBoardState value)?  $default,){
final _that = this;
switch (_that) {
case _FreeBoardState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Position start,  Position position,  List<String> moves,  Move? lastMove,  Side orientation,  Side? playerSide)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FreeBoardState() when $default != null:
return $default(_that.start,_that.position,_that.moves,_that.lastMove,_that.orientation,_that.playerSide);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Position start,  Position position,  List<String> moves,  Move? lastMove,  Side orientation,  Side? playerSide)  $default,) {final _that = this;
switch (_that) {
case _FreeBoardState():
return $default(_that.start,_that.position,_that.moves,_that.lastMove,_that.orientation,_that.playerSide);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Position start,  Position position,  List<String> moves,  Move? lastMove,  Side orientation,  Side? playerSide)?  $default,) {final _that = this;
switch (_that) {
case _FreeBoardState() when $default != null:
return $default(_that.start,_that.position,_that.moves,_that.lastMove,_that.orientation,_that.playerSide);case _:
  return null;

}
}

}

/// @nodoc


class _FreeBoardState extends FreeBoardState {
  const _FreeBoardState({required this.start, required this.position,  List<String> moves = const <String>[], this.lastMove, this.orientation = Side.white, this.playerSide}): _moves = moves,super._();
  

/// A posição em que o tabuleiro abriu; "nova partida" volta para ela.
@override final  Position start;
/// A posição atual.
@override final  Position position;
/// Os lances jogados, em notação algébrica (`e4`, `Nf3`, `O-O`).
 final  List<String> _moves;
/// Os lances jogados, em notação algébrica (`e4`, `Nf3`, `O-O`).
@override@JsonKey() List<String> get moves {
  if (_moves is EqualUnmodifiableListView) return _moves;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_moves);
}

/// O último lance, para o tabuleiro destacar.
@override final  Move? lastMove;
/// O lado que aparece embaixo no tabuleiro.
@override@JsonKey() final  Side orientation;
/// O lado que o jogador move. Nulo: ele move os dois.
@override final  Side? playerSide;

/// Create a copy of FreeBoardState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FreeBoardStateCopyWith<_FreeBoardState> get copyWith => __$FreeBoardStateCopyWithImpl<_FreeBoardState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FreeBoardState&&(identical(other.start, start) || other.start == start)&&(identical(other.position, position) || other.position == position)&&const DeepCollectionEquality().equals(other.moves, _moves)&&(identical(other.lastMove, lastMove) || other.lastMove == lastMove)&&(identical(other.orientation, orientation) || other.orientation == orientation)&&(identical(other.playerSide, playerSide) || other.playerSide == playerSide));
}


@override
int get hashCode {
    return Object.hash(runtimeType,start,position,const DeepCollectionEquality().hash(_moves),lastMove,orientation,playerSide);
}

@override
String toString() {
    return 'FreeBoardState(start: $start, position: $position, moves: $moves, lastMove: $lastMove, orientation: $orientation, playerSide: $playerSide)';
}


}

/// @nodoc
abstract mixin class _$FreeBoardStateCopyWith<$Res> implements $FreeBoardStateCopyWith<$Res> {
  factory _$FreeBoardStateCopyWith(_FreeBoardState value, $Res Function(_FreeBoardState) _then) = __$FreeBoardStateCopyWithImpl;
@override @useResult
$Res call({
 Position start, Position position, List<String> moves, Move? lastMove, Side orientation, Side? playerSide
});




}
/// @nodoc
class __$FreeBoardStateCopyWithImpl<$Res>
    implements _$FreeBoardStateCopyWith<$Res> {
  __$FreeBoardStateCopyWithImpl(this._self, this._then);

  final _FreeBoardState _self;
  final $Res Function(_FreeBoardState) _then;

/// Create a copy of FreeBoardState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? start = null,Object? position = null,Object? moves = null,Object? lastMove = freezed,Object? orientation = null,Object? playerSide = freezed,}) {
  return _then(_FreeBoardState(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as Position,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Position,moves: null == moves ? _self._moves : moves // ignore: cast_nullable_to_non_nullable
as List<String>,lastMove: freezed == lastMove ? _self.lastMove : lastMove // ignore: cast_nullable_to_non_nullable
as Move?,orientation: null == orientation ? _self.orientation : orientation // ignore: cast_nullable_to_non_nullable
as Side,playerSide: freezed == playerSide ? _self.playerSide : playerSide // ignore: cast_nullable_to_non_nullable
as Side?,
  ));
}


}

// dart format on
