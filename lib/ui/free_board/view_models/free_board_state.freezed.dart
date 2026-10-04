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
 Position get position;/// Falso enquanto a partida em andamento ainda está sendo lida do aparelho.
 bool get ready;/// Os lances jogados, em notação algébrica (`e4`, `Nf3`, `O-O`).
 List<String> get moves;/// Os mesmos lances em UCI (`e2e4`, `g1f3`), como são gravados.
 List<String> get ucis;/// O último lance, para o tabuleiro destacar.
 Move? get lastMove;/// O lado que aparece embaixo no tabuleiro.
 Side get orientation;/// O lado que o jogador move. Nulo: ele move os dois.
 Side? get playerSide;/// O relógio da partida. Nulo: partida sem relógio.
 ClockState? get clock;/// Quanto falta para cada lado, já arredondado como aparece na tela. Só
/// valem com [clock].
 Duration get whiteTime; Duration get blackTime;/// O fim por tempo, quando a bandeira de um lado cai.
 GameEnd? get timeEnd;
/// Create a copy of FreeBoardState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FreeBoardStateCopyWith<FreeBoardState> get copyWith => _$FreeBoardStateCopyWithImpl<FreeBoardState>(this as FreeBoardState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FreeBoardState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FreeBoardState&&(identical(other.start, _this.start) || other.start == _this.start)&&(identical(other.position, _this.position) || other.position == _this.position)&&(identical(other.ready, _this.ready) || other.ready == _this.ready)&&const DeepCollectionEquality().equals(other.moves, _this.moves)&&const DeepCollectionEquality().equals(other.ucis, _this.ucis)&&(identical(other.lastMove, _this.lastMove) || other.lastMove == _this.lastMove)&&(identical(other.orientation, _this.orientation) || other.orientation == _this.orientation)&&(identical(other.playerSide, _this.playerSide) || other.playerSide == _this.playerSide)&&(identical(other.clock, _this.clock) || other.clock == _this.clock)&&(identical(other.whiteTime, _this.whiteTime) || other.whiteTime == _this.whiteTime)&&(identical(other.blackTime, _this.blackTime) || other.blackTime == _this.blackTime)&&(identical(other.timeEnd, _this.timeEnd) || other.timeEnd == _this.timeEnd));
}


@override
int get hashCode {
  final _this = this as FreeBoardState;
  return Object.hash(runtimeType,_this.start,_this.position,_this.ready,const DeepCollectionEquality().hash(_this.moves),const DeepCollectionEquality().hash(_this.ucis),_this.lastMove,_this.orientation,_this.playerSide,_this.clock,_this.whiteTime,_this.blackTime,_this.timeEnd);
}

@override
String toString() {
  final _this = this as FreeBoardState;
  return 'FreeBoardState(start: ${_this.start}, position: ${_this.position}, ready: ${_this.ready}, moves: ${_this.moves}, ucis: ${_this.ucis}, lastMove: ${_this.lastMove}, orientation: ${_this.orientation}, playerSide: ${_this.playerSide}, clock: ${_this.clock}, whiteTime: ${_this.whiteTime}, blackTime: ${_this.blackTime}, timeEnd: ${_this.timeEnd})';
}


}

/// @nodoc
abstract mixin class $FreeBoardStateCopyWith<$Res>  {
  factory $FreeBoardStateCopyWith(FreeBoardState value, $Res Function(FreeBoardState) _then) = _$FreeBoardStateCopyWithImpl;
@useResult
$Res call({
 Position start, Position position, bool ready, List<String> moves, List<String> ucis, Move? lastMove, Side orientation, Side? playerSide, ClockState? clock, Duration whiteTime, Duration blackTime, GameEnd? timeEnd
});


$ClockStateCopyWith<$Res>? get clock;$GameEndCopyWith<$Res>? get timeEnd;

}
/// @nodoc
class _$FreeBoardStateCopyWithImpl<$Res>
    implements $FreeBoardStateCopyWith<$Res> {
  _$FreeBoardStateCopyWithImpl(this._self, this._then);

  final FreeBoardState _self;
  final $Res Function(FreeBoardState) _then;

/// Create a copy of FreeBoardState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? start = null,Object? position = null,Object? ready = null,Object? moves = null,Object? ucis = null,Object? lastMove = freezed,Object? orientation = null,Object? playerSide = freezed,Object? clock = freezed,Object? whiteTime = null,Object? blackTime = null,Object? timeEnd = freezed,}) {
  return _then(FreeBoardState(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as Position,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Position,ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
as bool,moves: null == moves ? _self.moves : moves // ignore: cast_nullable_to_non_nullable
as List<String>,ucis: null == ucis ? _self.ucis : ucis // ignore: cast_nullable_to_non_nullable
as List<String>,lastMove: freezed == lastMove ? _self.lastMove : lastMove // ignore: cast_nullable_to_non_nullable
as Move?,orientation: null == orientation ? _self.orientation : orientation // ignore: cast_nullable_to_non_nullable
as Side,playerSide: freezed == playerSide ? _self.playerSide : playerSide // ignore: cast_nullable_to_non_nullable
as Side?,clock: freezed == clock ? _self.clock : clock // ignore: cast_nullable_to_non_nullable
as ClockState?,whiteTime: null == whiteTime ? _self.whiteTime : whiteTime // ignore: cast_nullable_to_non_nullable
as Duration,blackTime: null == blackTime ? _self.blackTime : blackTime // ignore: cast_nullable_to_non_nullable
as Duration,timeEnd: freezed == timeEnd ? _self.timeEnd : timeEnd // ignore: cast_nullable_to_non_nullable
as GameEnd?,
  ));
}
/// Create a copy of FreeBoardState
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
}/// Create a copy of FreeBoardState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameEndCopyWith<$Res>? get timeEnd {
    if (_self.timeEnd == null) {
    return null;
  }

  return $GameEndCopyWith<$Res>(_self.timeEnd!, (value) {
    return _then(_self.copyWith(timeEnd: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Position start,  Position position,  bool ready,  List<String> moves,  List<String> ucis,  Move? lastMove,  Side orientation,  Side? playerSide,  ClockState? clock,  Duration whiteTime,  Duration blackTime,  GameEnd? timeEnd)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FreeBoardState() when $default != null:
return $default(_that.start,_that.position,_that.ready,_that.moves,_that.ucis,_that.lastMove,_that.orientation,_that.playerSide,_that.clock,_that.whiteTime,_that.blackTime,_that.timeEnd);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Position start,  Position position,  bool ready,  List<String> moves,  List<String> ucis,  Move? lastMove,  Side orientation,  Side? playerSide,  ClockState? clock,  Duration whiteTime,  Duration blackTime,  GameEnd? timeEnd)  $default,) {final _that = this;
switch (_that) {
case _FreeBoardState():
return $default(_that.start,_that.position,_that.ready,_that.moves,_that.ucis,_that.lastMove,_that.orientation,_that.playerSide,_that.clock,_that.whiteTime,_that.blackTime,_that.timeEnd);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Position start,  Position position,  bool ready,  List<String> moves,  List<String> ucis,  Move? lastMove,  Side orientation,  Side? playerSide,  ClockState? clock,  Duration whiteTime,  Duration blackTime,  GameEnd? timeEnd)?  $default,) {final _that = this;
switch (_that) {
case _FreeBoardState() when $default != null:
return $default(_that.start,_that.position,_that.ready,_that.moves,_that.ucis,_that.lastMove,_that.orientation,_that.playerSide,_that.clock,_that.whiteTime,_that.blackTime,_that.timeEnd);case _:
  return null;

}
}

}

/// @nodoc


class _FreeBoardState extends FreeBoardState {
  const _FreeBoardState({required this.start, required this.position, this.ready = true,  List<String> moves = const <String>[],  List<String> ucis = const <String>[], this.lastMove, this.orientation = Side.white, this.playerSide, this.clock, this.whiteTime = Duration.zero, this.blackTime = Duration.zero, this.timeEnd}): _moves = moves,_ucis = ucis,super._();
  

/// A posição em que o tabuleiro abriu; "nova partida" volta para ela.
@override final  Position start;
/// A posição atual.
@override final  Position position;
/// Falso enquanto a partida em andamento ainda está sendo lida do aparelho.
@override@JsonKey() final  bool ready;
/// Os lances jogados, em notação algébrica (`e4`, `Nf3`, `O-O`).
 final  List<String> _moves;
/// Os lances jogados, em notação algébrica (`e4`, `Nf3`, `O-O`).
@override@JsonKey() List<String> get moves {
  if (_moves is EqualUnmodifiableListView) return _moves;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_moves);
}

/// Os mesmos lances em UCI (`e2e4`, `g1f3`), como são gravados.
 final  List<String> _ucis;
/// Os mesmos lances em UCI (`e2e4`, `g1f3`), como são gravados.
@override@JsonKey() List<String> get ucis {
  if (_ucis is EqualUnmodifiableListView) return _ucis;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ucis);
}

/// O último lance, para o tabuleiro destacar.
@override final  Move? lastMove;
/// O lado que aparece embaixo no tabuleiro.
@override@JsonKey() final  Side orientation;
/// O lado que o jogador move. Nulo: ele move os dois.
@override final  Side? playerSide;
/// O relógio da partida. Nulo: partida sem relógio.
@override final  ClockState? clock;
/// Quanto falta para cada lado, já arredondado como aparece na tela. Só
/// valem com [clock].
@override@JsonKey() final  Duration whiteTime;
@override@JsonKey() final  Duration blackTime;
/// O fim por tempo, quando a bandeira de um lado cai.
@override final  GameEnd? timeEnd;

/// Create a copy of FreeBoardState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FreeBoardStateCopyWith<_FreeBoardState> get copyWith => __$FreeBoardStateCopyWithImpl<_FreeBoardState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FreeBoardState&&(identical(other.start, start) || other.start == start)&&(identical(other.position, position) || other.position == position)&&(identical(other.ready, ready) || other.ready == ready)&&const DeepCollectionEquality().equals(other.moves, _moves)&&const DeepCollectionEquality().equals(other.ucis, _ucis)&&(identical(other.lastMove, lastMove) || other.lastMove == lastMove)&&(identical(other.orientation, orientation) || other.orientation == orientation)&&(identical(other.playerSide, playerSide) || other.playerSide == playerSide)&&(identical(other.clock, clock) || other.clock == clock)&&(identical(other.whiteTime, whiteTime) || other.whiteTime == whiteTime)&&(identical(other.blackTime, blackTime) || other.blackTime == blackTime)&&(identical(other.timeEnd, timeEnd) || other.timeEnd == timeEnd));
}


@override
int get hashCode {
    return Object.hash(runtimeType,start,position,ready,const DeepCollectionEquality().hash(_moves),const DeepCollectionEquality().hash(_ucis),lastMove,orientation,playerSide,clock,whiteTime,blackTime,timeEnd);
}

@override
String toString() {
    return 'FreeBoardState(start: $start, position: $position, ready: $ready, moves: $moves, ucis: $ucis, lastMove: $lastMove, orientation: $orientation, playerSide: $playerSide, clock: $clock, whiteTime: $whiteTime, blackTime: $blackTime, timeEnd: $timeEnd)';
}


}

/// @nodoc
abstract mixin class _$FreeBoardStateCopyWith<$Res> implements $FreeBoardStateCopyWith<$Res> {
  factory _$FreeBoardStateCopyWith(_FreeBoardState value, $Res Function(_FreeBoardState) _then) = __$FreeBoardStateCopyWithImpl;
@override @useResult
$Res call({
 Position start, Position position, bool ready, List<String> moves, List<String> ucis, Move? lastMove, Side orientation, Side? playerSide, ClockState? clock, Duration whiteTime, Duration blackTime, GameEnd? timeEnd
});


@override $ClockStateCopyWith<$Res>? get clock;@override $GameEndCopyWith<$Res>? get timeEnd;

}
/// @nodoc
class __$FreeBoardStateCopyWithImpl<$Res>
    implements _$FreeBoardStateCopyWith<$Res> {
  __$FreeBoardStateCopyWithImpl(this._self, this._then);

  final _FreeBoardState _self;
  final $Res Function(_FreeBoardState) _then;

/// Create a copy of FreeBoardState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? start = null,Object? position = null,Object? ready = null,Object? moves = null,Object? ucis = null,Object? lastMove = freezed,Object? orientation = null,Object? playerSide = freezed,Object? clock = freezed,Object? whiteTime = null,Object? blackTime = null,Object? timeEnd = freezed,}) {
  return _then(_FreeBoardState(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as Position,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Position,ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
as bool,moves: null == moves ? _self._moves : moves // ignore: cast_nullable_to_non_nullable
as List<String>,ucis: null == ucis ? _self._ucis : ucis // ignore: cast_nullable_to_non_nullable
as List<String>,lastMove: freezed == lastMove ? _self.lastMove : lastMove // ignore: cast_nullable_to_non_nullable
as Move?,orientation: null == orientation ? _self.orientation : orientation // ignore: cast_nullable_to_non_nullable
as Side,playerSide: freezed == playerSide ? _self.playerSide : playerSide // ignore: cast_nullable_to_non_nullable
as Side?,clock: freezed == clock ? _self.clock : clock // ignore: cast_nullable_to_non_nullable
as ClockState?,whiteTime: null == whiteTime ? _self.whiteTime : whiteTime // ignore: cast_nullable_to_non_nullable
as Duration,blackTime: null == blackTime ? _self.blackTime : blackTime // ignore: cast_nullable_to_non_nullable
as Duration,timeEnd: freezed == timeEnd ? _self.timeEnd : timeEnd // ignore: cast_nullable_to_non_nullable
as GameEnd?,
  ));
}

/// Create a copy of FreeBoardState
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
}/// Create a copy of FreeBoardState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameEndCopyWith<$Res>? get timeEnd {
    if (_self.timeEnd == null) {
    return null;
  }

  return $GameEndCopyWith<$Res>(_self.timeEnd!, (value) {
    return _then(_self.copyWith(timeEnd: value));
  });
}
}

// dart format on
