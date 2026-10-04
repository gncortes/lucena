// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'custom_position_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CustomPositionState {

/// O FEN como está no campo de texto.
 String get fen;/// O desenho das peças do último FEN que deu para ler, que o editor mostra
/// enquanto o texto está incompleto.
 String get board; Side get turn; PositionGoal get goal;/// A posição pronta para jogar, quando não há problema.
 Position? get position; PositionProblem? get problem;/// Falso até o rascunho ser lido.
 bool get ready;
/// Create a copy of CustomPositionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomPositionStateCopyWith<CustomPositionState> get copyWith => _$CustomPositionStateCopyWithImpl<CustomPositionState>(this as CustomPositionState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CustomPositionState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomPositionState&&(identical(other.fen, _this.fen) || other.fen == _this.fen)&&(identical(other.board, _this.board) || other.board == _this.board)&&(identical(other.turn, _this.turn) || other.turn == _this.turn)&&(identical(other.goal, _this.goal) || other.goal == _this.goal)&&(identical(other.position, _this.position) || other.position == _this.position)&&(identical(other.problem, _this.problem) || other.problem == _this.problem)&&(identical(other.ready, _this.ready) || other.ready == _this.ready));
}


@override
int get hashCode {
  final _this = this as CustomPositionState;
  return Object.hash(runtimeType,_this.fen,_this.board,_this.turn,_this.goal,_this.position,_this.problem,_this.ready);
}

@override
String toString() {
  final _this = this as CustomPositionState;
  return 'CustomPositionState(fen: ${_this.fen}, board: ${_this.board}, turn: ${_this.turn}, goal: ${_this.goal}, position: ${_this.position}, problem: ${_this.problem}, ready: ${_this.ready})';
}


}

/// @nodoc
abstract mixin class $CustomPositionStateCopyWith<$Res>  {
  factory $CustomPositionStateCopyWith(CustomPositionState value, $Res Function(CustomPositionState) _then) = _$CustomPositionStateCopyWithImpl;
@useResult
$Res call({
 String fen, String board, Side turn, PositionGoal goal, Position? position, PositionProblem? problem, bool ready
});




}
/// @nodoc
class _$CustomPositionStateCopyWithImpl<$Res>
    implements $CustomPositionStateCopyWith<$Res> {
  _$CustomPositionStateCopyWithImpl(this._self, this._then);

  final CustomPositionState _self;
  final $Res Function(CustomPositionState) _then;

/// Create a copy of CustomPositionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fen = null,Object? board = null,Object? turn = null,Object? goal = null,Object? position = freezed,Object? problem = freezed,Object? ready = null,}) {
  return _then(CustomPositionState(
fen: null == fen ? _self.fen : fen // ignore: cast_nullable_to_non_nullable
as String,board: null == board ? _self.board : board // ignore: cast_nullable_to_non_nullable
as String,turn: null == turn ? _self.turn : turn // ignore: cast_nullable_to_non_nullable
as Side,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as PositionGoal,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Position?,problem: freezed == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as PositionProblem?,ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomPositionState].
extension CustomPositionStatePatterns on CustomPositionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomPositionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomPositionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomPositionState value)  $default,){
final _that = this;
switch (_that) {
case _CustomPositionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomPositionState value)?  $default,){
final _that = this;
switch (_that) {
case _CustomPositionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fen,  String board,  Side turn,  PositionGoal goal,  Position? position,  PositionProblem? problem,  bool ready)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomPositionState() when $default != null:
return $default(_that.fen,_that.board,_that.turn,_that.goal,_that.position,_that.problem,_that.ready);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fen,  String board,  Side turn,  PositionGoal goal,  Position? position,  PositionProblem? problem,  bool ready)  $default,) {final _that = this;
switch (_that) {
case _CustomPositionState():
return $default(_that.fen,_that.board,_that.turn,_that.goal,_that.position,_that.problem,_that.ready);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fen,  String board,  Side turn,  PositionGoal goal,  Position? position,  PositionProblem? problem,  bool ready)?  $default,) {final _that = this;
switch (_that) {
case _CustomPositionState() when $default != null:
return $default(_that.fen,_that.board,_that.turn,_that.goal,_that.position,_that.problem,_that.ready);case _:
  return null;

}
}

}

/// @nodoc


class _CustomPositionState implements CustomPositionState {
  const _CustomPositionState({this.fen = CustomPositionCubit.startFen, this.board = CustomPositionCubit.startBoard, this.turn = Side.white, this.goal = PositionGoal.win, this.position, this.problem, this.ready = false});
  

/// O FEN como está no campo de texto.
@override@JsonKey() final  String fen;
/// O desenho das peças do último FEN que deu para ler, que o editor mostra
/// enquanto o texto está incompleto.
@override@JsonKey() final  String board;
@override@JsonKey() final  Side turn;
@override@JsonKey() final  PositionGoal goal;
/// A posição pronta para jogar, quando não há problema.
@override final  Position? position;
@override final  PositionProblem? problem;
/// Falso até o rascunho ser lido.
@override@JsonKey() final  bool ready;

/// Create a copy of CustomPositionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomPositionStateCopyWith<_CustomPositionState> get copyWith => __$CustomPositionStateCopyWithImpl<_CustomPositionState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomPositionState&&(identical(other.fen, fen) || other.fen == fen)&&(identical(other.board, board) || other.board == board)&&(identical(other.turn, turn) || other.turn == turn)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.position, position) || other.position == position)&&(identical(other.problem, problem) || other.problem == problem)&&(identical(other.ready, ready) || other.ready == ready));
}


@override
int get hashCode {
    return Object.hash(runtimeType,fen,board,turn,goal,position,problem,ready);
}

@override
String toString() {
    return 'CustomPositionState(fen: $fen, board: $board, turn: $turn, goal: $goal, position: $position, problem: $problem, ready: $ready)';
}


}

/// @nodoc
abstract mixin class _$CustomPositionStateCopyWith<$Res> implements $CustomPositionStateCopyWith<$Res> {
  factory _$CustomPositionStateCopyWith(_CustomPositionState value, $Res Function(_CustomPositionState) _then) = __$CustomPositionStateCopyWithImpl;
@override @useResult
$Res call({
 String fen, String board, Side turn, PositionGoal goal, Position? position, PositionProblem? problem, bool ready
});




}
/// @nodoc
class __$CustomPositionStateCopyWithImpl<$Res>
    implements _$CustomPositionStateCopyWith<$Res> {
  __$CustomPositionStateCopyWithImpl(this._self, this._then);

  final _CustomPositionState _self;
  final $Res Function(_CustomPositionState) _then;

/// Create a copy of CustomPositionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fen = null,Object? board = null,Object? turn = null,Object? goal = null,Object? position = freezed,Object? problem = freezed,Object? ready = null,}) {
  return _then(_CustomPositionState(
fen: null == fen ? _self.fen : fen // ignore: cast_nullable_to_non_nullable
as String,board: null == board ? _self.board : board // ignore: cast_nullable_to_non_nullable
as String,turn: null == turn ? _self.turn : turn // ignore: cast_nullable_to_non_nullable
as Side,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as PositionGoal,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Position?,problem: freezed == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as PositionProblem?,ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
