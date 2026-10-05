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
 List<String> get ucis;/// Quanto cada lance levou, na ordem de [ucis].
 List<Duration> get moveTimes;/// O tempo já gasto no lance da vez antes de [turnStartedAt] e o instante
/// em que a vez (re)começou. Com o instante nulo, o tempo está parado (a
/// partida terminou ou o jogador saiu da tela).
 Duration get turnElapsed; DateTime? get turnStartedAt;/// Quantas vezes a posição atual já apareceu nesta partida.
 int get repetitions;/// O último lance, para o tabuleiro destacar.
 Move? get lastMove;/// O lado que aparece embaixo no tabuleiro.
 Side get orientation;/// O lado que o jogador move. Nulo: ele move os dois.
 Side? get playerSide;/// O relógio da partida. Nulo: partida sem relógio.
 ClockState? get clock;/// Quanto falta para cada lado, já arredondado como aparece na tela. Só
/// valem com [clock].
 Duration get whiteTime; Duration get blackTime;/// O fim que não vem do tabuleiro: bandeira ou desistência.
 GameEnd? get forcedEnd;/// Contra quem, de que lado e, num treino, com que objetivo.
 GameMode get mode;/// A máquina está escolhendo o lance.
 bool get machineThinking;/// Quando a partida começou (ou recomeçou).
 DateTime? get startedAt;/// A última proposta de empate e em que lance (quantos lances já tinham
/// sido jogados) ela foi recusada.
 DrawOffer get drawOffer; int? get drawDeclinedAt;/// O que a partida terminada mudou (rating, recordes, conquistas). Nulo
/// enquanto ela continua ou até a conta terminar.
 GameReport? get report;/// O lance que o jogador está revendo: quantos lances estão no tabuleiro
/// (0 é a posição de início). Nulo: a posição atual da partida.
 int? get viewedPly;/// A posição depois de [viewedPly] lances e o último deles. Só valem com
/// ele.
 Position? get viewedPosition; Move? get viewedMove;
/// Create a copy of FreeBoardState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FreeBoardStateCopyWith<FreeBoardState> get copyWith => _$FreeBoardStateCopyWithImpl<FreeBoardState>(this as FreeBoardState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FreeBoardState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FreeBoardState&&(identical(other.start, _this.start) || other.start == _this.start)&&(identical(other.position, _this.position) || other.position == _this.position)&&(identical(other.ready, _this.ready) || other.ready == _this.ready)&&const DeepCollectionEquality().equals(other.moves, _this.moves)&&const DeepCollectionEquality().equals(other.ucis, _this.ucis)&&const DeepCollectionEquality().equals(other.moveTimes, _this.moveTimes)&&(identical(other.turnElapsed, _this.turnElapsed) || other.turnElapsed == _this.turnElapsed)&&(identical(other.turnStartedAt, _this.turnStartedAt) || other.turnStartedAt == _this.turnStartedAt)&&(identical(other.repetitions, _this.repetitions) || other.repetitions == _this.repetitions)&&(identical(other.lastMove, _this.lastMove) || other.lastMove == _this.lastMove)&&(identical(other.orientation, _this.orientation) || other.orientation == _this.orientation)&&(identical(other.playerSide, _this.playerSide) || other.playerSide == _this.playerSide)&&(identical(other.clock, _this.clock) || other.clock == _this.clock)&&(identical(other.whiteTime, _this.whiteTime) || other.whiteTime == _this.whiteTime)&&(identical(other.blackTime, _this.blackTime) || other.blackTime == _this.blackTime)&&(identical(other.forcedEnd, _this.forcedEnd) || other.forcedEnd == _this.forcedEnd)&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.machineThinking, _this.machineThinking) || other.machineThinking == _this.machineThinking)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.drawOffer, _this.drawOffer) || other.drawOffer == _this.drawOffer)&&(identical(other.drawDeclinedAt, _this.drawDeclinedAt) || other.drawDeclinedAt == _this.drawDeclinedAt)&&(identical(other.report, _this.report) || other.report == _this.report)&&(identical(other.viewedPly, _this.viewedPly) || other.viewedPly == _this.viewedPly)&&(identical(other.viewedPosition, _this.viewedPosition) || other.viewedPosition == _this.viewedPosition)&&(identical(other.viewedMove, _this.viewedMove) || other.viewedMove == _this.viewedMove));
}


@override
int get hashCode {
  final _this = this as FreeBoardState;
  return Object.hashAll([runtimeType,_this.start,_this.position,_this.ready,const DeepCollectionEquality().hash(_this.moves),const DeepCollectionEquality().hash(_this.ucis),const DeepCollectionEquality().hash(_this.moveTimes),_this.turnElapsed,_this.turnStartedAt,_this.repetitions,_this.lastMove,_this.orientation,_this.playerSide,_this.clock,_this.whiteTime,_this.blackTime,_this.forcedEnd,_this.mode,_this.machineThinking,_this.startedAt,_this.drawOffer,_this.drawDeclinedAt,_this.report,_this.viewedPly,_this.viewedPosition,_this.viewedMove]);
}

@override
String toString() {
  final _this = this as FreeBoardState;
  return 'FreeBoardState(start: ${_this.start}, position: ${_this.position}, ready: ${_this.ready}, moves: ${_this.moves}, ucis: ${_this.ucis}, moveTimes: ${_this.moveTimes}, turnElapsed: ${_this.turnElapsed}, turnStartedAt: ${_this.turnStartedAt}, repetitions: ${_this.repetitions}, lastMove: ${_this.lastMove}, orientation: ${_this.orientation}, playerSide: ${_this.playerSide}, clock: ${_this.clock}, whiteTime: ${_this.whiteTime}, blackTime: ${_this.blackTime}, forcedEnd: ${_this.forcedEnd}, mode: ${_this.mode}, machineThinking: ${_this.machineThinking}, startedAt: ${_this.startedAt}, drawOffer: ${_this.drawOffer}, drawDeclinedAt: ${_this.drawDeclinedAt}, report: ${_this.report}, viewedPly: ${_this.viewedPly}, viewedPosition: ${_this.viewedPosition}, viewedMove: ${_this.viewedMove})';
}


}

/// @nodoc
abstract mixin class $FreeBoardStateCopyWith<$Res>  {
  factory $FreeBoardStateCopyWith(FreeBoardState value, $Res Function(FreeBoardState) _then) = _$FreeBoardStateCopyWithImpl;
@useResult
$Res call({
 Position start, Position position, bool ready, List<String> moves, List<String> ucis, List<Duration> moveTimes, Duration turnElapsed, DateTime? turnStartedAt, int repetitions, Move? lastMove, Side orientation, Side? playerSide, ClockState? clock, Duration whiteTime, Duration blackTime, GameEnd? forcedEnd, GameMode mode, bool machineThinking, DateTime? startedAt, DrawOffer drawOffer, int? drawDeclinedAt, GameReport? report, int? viewedPly, Position? viewedPosition, Move? viewedMove
});


$ClockStateCopyWith<$Res>? get clock;$GameEndCopyWith<$Res>? get forcedEnd;$GameModeCopyWith<$Res> get mode;

}
/// @nodoc
class _$FreeBoardStateCopyWithImpl<$Res>
    implements $FreeBoardStateCopyWith<$Res> {
  _$FreeBoardStateCopyWithImpl(this._self, this._then);

  final FreeBoardState _self;
  final $Res Function(FreeBoardState) _then;

/// Create a copy of FreeBoardState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? start = null,Object? position = null,Object? ready = null,Object? moves = null,Object? ucis = null,Object? moveTimes = null,Object? turnElapsed = null,Object? turnStartedAt = freezed,Object? repetitions = null,Object? lastMove = freezed,Object? orientation = null,Object? playerSide = freezed,Object? clock = freezed,Object? whiteTime = null,Object? blackTime = null,Object? forcedEnd = freezed,Object? mode = null,Object? machineThinking = null,Object? startedAt = freezed,Object? drawOffer = null,Object? drawDeclinedAt = freezed,Object? report = freezed,Object? viewedPly = freezed,Object? viewedPosition = freezed,Object? viewedMove = freezed,}) {
  return _then(FreeBoardState(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as Position,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Position,ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
as bool,moves: null == moves ? _self.moves : moves // ignore: cast_nullable_to_non_nullable
as List<String>,ucis: null == ucis ? _self.ucis : ucis // ignore: cast_nullable_to_non_nullable
as List<String>,moveTimes: null == moveTimes ? _self.moveTimes : moveTimes // ignore: cast_nullable_to_non_nullable
as List<Duration>,turnElapsed: null == turnElapsed ? _self.turnElapsed : turnElapsed // ignore: cast_nullable_to_non_nullable
as Duration,turnStartedAt: freezed == turnStartedAt ? _self.turnStartedAt : turnStartedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,repetitions: null == repetitions ? _self.repetitions : repetitions // ignore: cast_nullable_to_non_nullable
as int,lastMove: freezed == lastMove ? _self.lastMove : lastMove // ignore: cast_nullable_to_non_nullable
as Move?,orientation: null == orientation ? _self.orientation : orientation // ignore: cast_nullable_to_non_nullable
as Side,playerSide: freezed == playerSide ? _self.playerSide : playerSide // ignore: cast_nullable_to_non_nullable
as Side?,clock: freezed == clock ? _self.clock : clock // ignore: cast_nullable_to_non_nullable
as ClockState?,whiteTime: null == whiteTime ? _self.whiteTime : whiteTime // ignore: cast_nullable_to_non_nullable
as Duration,blackTime: null == blackTime ? _self.blackTime : blackTime // ignore: cast_nullable_to_non_nullable
as Duration,forcedEnd: freezed == forcedEnd ? _self.forcedEnd : forcedEnd // ignore: cast_nullable_to_non_nullable
as GameEnd?,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as GameMode,machineThinking: null == machineThinking ? _self.machineThinking : machineThinking // ignore: cast_nullable_to_non_nullable
as bool,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,drawOffer: null == drawOffer ? _self.drawOffer : drawOffer // ignore: cast_nullable_to_non_nullable
as DrawOffer,drawDeclinedAt: freezed == drawDeclinedAt ? _self.drawDeclinedAt : drawDeclinedAt // ignore: cast_nullable_to_non_nullable
as int?,report: freezed == report ? _self.report : report // ignore: cast_nullable_to_non_nullable
as GameReport?,viewedPly: freezed == viewedPly ? _self.viewedPly : viewedPly // ignore: cast_nullable_to_non_nullable
as int?,viewedPosition: freezed == viewedPosition ? _self.viewedPosition : viewedPosition // ignore: cast_nullable_to_non_nullable
as Position?,viewedMove: freezed == viewedMove ? _self.viewedMove : viewedMove // ignore: cast_nullable_to_non_nullable
as Move?,
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
$GameEndCopyWith<$Res>? get forcedEnd {
    if (_self.forcedEnd == null) {
    return null;
  }

  return $GameEndCopyWith<$Res>(_self.forcedEnd!, (value) {
    return _then(_self.copyWith(forcedEnd: value));
  });
}/// Create a copy of FreeBoardState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameModeCopyWith<$Res> get mode {
  
  return $GameModeCopyWith<$Res>(_self.mode, (value) {
    return _then(_self.copyWith(mode: value));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Position start,  Position position,  bool ready,  List<String> moves,  List<String> ucis,  List<Duration> moveTimes,  Duration turnElapsed,  DateTime? turnStartedAt,  int repetitions,  Move? lastMove,  Side orientation,  Side? playerSide,  ClockState? clock,  Duration whiteTime,  Duration blackTime,  GameEnd? forcedEnd,  GameMode mode,  bool machineThinking,  DateTime? startedAt,  DrawOffer drawOffer,  int? drawDeclinedAt,  GameReport? report,  int? viewedPly,  Position? viewedPosition,  Move? viewedMove)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FreeBoardState() when $default != null:
return $default(_that.start,_that.position,_that.ready,_that.moves,_that.ucis,_that.moveTimes,_that.turnElapsed,_that.turnStartedAt,_that.repetitions,_that.lastMove,_that.orientation,_that.playerSide,_that.clock,_that.whiteTime,_that.blackTime,_that.forcedEnd,_that.mode,_that.machineThinking,_that.startedAt,_that.drawOffer,_that.drawDeclinedAt,_that.report,_that.viewedPly,_that.viewedPosition,_that.viewedMove);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Position start,  Position position,  bool ready,  List<String> moves,  List<String> ucis,  List<Duration> moveTimes,  Duration turnElapsed,  DateTime? turnStartedAt,  int repetitions,  Move? lastMove,  Side orientation,  Side? playerSide,  ClockState? clock,  Duration whiteTime,  Duration blackTime,  GameEnd? forcedEnd,  GameMode mode,  bool machineThinking,  DateTime? startedAt,  DrawOffer drawOffer,  int? drawDeclinedAt,  GameReport? report,  int? viewedPly,  Position? viewedPosition,  Move? viewedMove)  $default,) {final _that = this;
switch (_that) {
case _FreeBoardState():
return $default(_that.start,_that.position,_that.ready,_that.moves,_that.ucis,_that.moveTimes,_that.turnElapsed,_that.turnStartedAt,_that.repetitions,_that.lastMove,_that.orientation,_that.playerSide,_that.clock,_that.whiteTime,_that.blackTime,_that.forcedEnd,_that.mode,_that.machineThinking,_that.startedAt,_that.drawOffer,_that.drawDeclinedAt,_that.report,_that.viewedPly,_that.viewedPosition,_that.viewedMove);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Position start,  Position position,  bool ready,  List<String> moves,  List<String> ucis,  List<Duration> moveTimes,  Duration turnElapsed,  DateTime? turnStartedAt,  int repetitions,  Move? lastMove,  Side orientation,  Side? playerSide,  ClockState? clock,  Duration whiteTime,  Duration blackTime,  GameEnd? forcedEnd,  GameMode mode,  bool machineThinking,  DateTime? startedAt,  DrawOffer drawOffer,  int? drawDeclinedAt,  GameReport? report,  int? viewedPly,  Position? viewedPosition,  Move? viewedMove)?  $default,) {final _that = this;
switch (_that) {
case _FreeBoardState() when $default != null:
return $default(_that.start,_that.position,_that.ready,_that.moves,_that.ucis,_that.moveTimes,_that.turnElapsed,_that.turnStartedAt,_that.repetitions,_that.lastMove,_that.orientation,_that.playerSide,_that.clock,_that.whiteTime,_that.blackTime,_that.forcedEnd,_that.mode,_that.machineThinking,_that.startedAt,_that.drawOffer,_that.drawDeclinedAt,_that.report,_that.viewedPly,_that.viewedPosition,_that.viewedMove);case _:
  return null;

}
}

}

/// @nodoc


class _FreeBoardState extends FreeBoardState {
  const _FreeBoardState({required this.start, required this.position, this.ready = true,  List<String> moves = const <String>[],  List<String> ucis = const <String>[],  List<Duration> moveTimes = const <Duration>[], this.turnElapsed = Duration.zero, this.turnStartedAt, this.repetitions = 1, this.lastMove, this.orientation = Side.white, this.playerSide, this.clock, this.whiteTime = Duration.zero, this.blackTime = Duration.zero, this.forcedEnd, this.mode = const GameMode(), this.machineThinking = false, this.startedAt, this.drawOffer = DrawOffer.none, this.drawDeclinedAt, this.report, this.viewedPly, this.viewedPosition, this.viewedMove}): _moves = moves,_ucis = ucis,_moveTimes = moveTimes,super._();
  

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

/// Quanto cada lance levou, na ordem de [ucis].
 final  List<Duration> _moveTimes;
/// Quanto cada lance levou, na ordem de [ucis].
@override@JsonKey() List<Duration> get moveTimes {
  if (_moveTimes is EqualUnmodifiableListView) return _moveTimes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_moveTimes);
}

/// O tempo já gasto no lance da vez antes de [turnStartedAt] e o instante
/// em que a vez (re)começou. Com o instante nulo, o tempo está parado (a
/// partida terminou ou o jogador saiu da tela).
@override@JsonKey() final  Duration turnElapsed;
@override final  DateTime? turnStartedAt;
/// Quantas vezes a posição atual já apareceu nesta partida.
@override@JsonKey() final  int repetitions;
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
/// O fim que não vem do tabuleiro: bandeira ou desistência.
@override final  GameEnd? forcedEnd;
/// Contra quem, de que lado e, num treino, com que objetivo.
@override@JsonKey() final  GameMode mode;
/// A máquina está escolhendo o lance.
@override@JsonKey() final  bool machineThinking;
/// Quando a partida começou (ou recomeçou).
@override final  DateTime? startedAt;
/// A última proposta de empate e em que lance (quantos lances já tinham
/// sido jogados) ela foi recusada.
@override@JsonKey() final  DrawOffer drawOffer;
@override final  int? drawDeclinedAt;
/// O que a partida terminada mudou (rating, recordes, conquistas). Nulo
/// enquanto ela continua ou até a conta terminar.
@override final  GameReport? report;
/// O lance que o jogador está revendo: quantos lances estão no tabuleiro
/// (0 é a posição de início). Nulo: a posição atual da partida.
@override final  int? viewedPly;
/// A posição depois de [viewedPly] lances e o último deles. Só valem com
/// ele.
@override final  Position? viewedPosition;
@override final  Move? viewedMove;

/// Create a copy of FreeBoardState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FreeBoardStateCopyWith<_FreeBoardState> get copyWith => __$FreeBoardStateCopyWithImpl<_FreeBoardState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FreeBoardState&&(identical(other.start, start) || other.start == start)&&(identical(other.position, position) || other.position == position)&&(identical(other.ready, ready) || other.ready == ready)&&const DeepCollectionEquality().equals(other.moves, _moves)&&const DeepCollectionEquality().equals(other.ucis, _ucis)&&const DeepCollectionEquality().equals(other.moveTimes, _moveTimes)&&(identical(other.turnElapsed, turnElapsed) || other.turnElapsed == turnElapsed)&&(identical(other.turnStartedAt, turnStartedAt) || other.turnStartedAt == turnStartedAt)&&(identical(other.repetitions, repetitions) || other.repetitions == repetitions)&&(identical(other.lastMove, lastMove) || other.lastMove == lastMove)&&(identical(other.orientation, orientation) || other.orientation == orientation)&&(identical(other.playerSide, playerSide) || other.playerSide == playerSide)&&(identical(other.clock, clock) || other.clock == clock)&&(identical(other.whiteTime, whiteTime) || other.whiteTime == whiteTime)&&(identical(other.blackTime, blackTime) || other.blackTime == blackTime)&&(identical(other.forcedEnd, forcedEnd) || other.forcedEnd == forcedEnd)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.machineThinking, machineThinking) || other.machineThinking == machineThinking)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.drawOffer, drawOffer) || other.drawOffer == drawOffer)&&(identical(other.drawDeclinedAt, drawDeclinedAt) || other.drawDeclinedAt == drawDeclinedAt)&&(identical(other.report, report) || other.report == report)&&(identical(other.viewedPly, viewedPly) || other.viewedPly == viewedPly)&&(identical(other.viewedPosition, viewedPosition) || other.viewedPosition == viewedPosition)&&(identical(other.viewedMove, viewedMove) || other.viewedMove == viewedMove));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,start,position,ready,const DeepCollectionEquality().hash(_moves),const DeepCollectionEquality().hash(_ucis),const DeepCollectionEquality().hash(_moveTimes),turnElapsed,turnStartedAt,repetitions,lastMove,orientation,playerSide,clock,whiteTime,blackTime,forcedEnd,mode,machineThinking,startedAt,drawOffer,drawDeclinedAt,report,viewedPly,viewedPosition,viewedMove]);
}

@override
String toString() {
    return 'FreeBoardState(start: $start, position: $position, ready: $ready, moves: $moves, ucis: $ucis, moveTimes: $moveTimes, turnElapsed: $turnElapsed, turnStartedAt: $turnStartedAt, repetitions: $repetitions, lastMove: $lastMove, orientation: $orientation, playerSide: $playerSide, clock: $clock, whiteTime: $whiteTime, blackTime: $blackTime, forcedEnd: $forcedEnd, mode: $mode, machineThinking: $machineThinking, startedAt: $startedAt, drawOffer: $drawOffer, drawDeclinedAt: $drawDeclinedAt, report: $report, viewedPly: $viewedPly, viewedPosition: $viewedPosition, viewedMove: $viewedMove)';
}


}

/// @nodoc
abstract mixin class _$FreeBoardStateCopyWith<$Res> implements $FreeBoardStateCopyWith<$Res> {
  factory _$FreeBoardStateCopyWith(_FreeBoardState value, $Res Function(_FreeBoardState) _then) = __$FreeBoardStateCopyWithImpl;
@override @useResult
$Res call({
 Position start, Position position, bool ready, List<String> moves, List<String> ucis, List<Duration> moveTimes, Duration turnElapsed, DateTime? turnStartedAt, int repetitions, Move? lastMove, Side orientation, Side? playerSide, ClockState? clock, Duration whiteTime, Duration blackTime, GameEnd? forcedEnd, GameMode mode, bool machineThinking, DateTime? startedAt, DrawOffer drawOffer, int? drawDeclinedAt, GameReport? report, int? viewedPly, Position? viewedPosition, Move? viewedMove
});


@override $ClockStateCopyWith<$Res>? get clock;@override $GameEndCopyWith<$Res>? get forcedEnd;@override $GameModeCopyWith<$Res> get mode;

}
/// @nodoc
class __$FreeBoardStateCopyWithImpl<$Res>
    implements _$FreeBoardStateCopyWith<$Res> {
  __$FreeBoardStateCopyWithImpl(this._self, this._then);

  final _FreeBoardState _self;
  final $Res Function(_FreeBoardState) _then;

/// Create a copy of FreeBoardState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? start = null,Object? position = null,Object? ready = null,Object? moves = null,Object? ucis = null,Object? moveTimes = null,Object? turnElapsed = null,Object? turnStartedAt = freezed,Object? repetitions = null,Object? lastMove = freezed,Object? orientation = null,Object? playerSide = freezed,Object? clock = freezed,Object? whiteTime = null,Object? blackTime = null,Object? forcedEnd = freezed,Object? mode = null,Object? machineThinking = null,Object? startedAt = freezed,Object? drawOffer = null,Object? drawDeclinedAt = freezed,Object? report = freezed,Object? viewedPly = freezed,Object? viewedPosition = freezed,Object? viewedMove = freezed,}) {
  return _then(_FreeBoardState(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as Position,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Position,ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
as bool,moves: null == moves ? _self._moves : moves // ignore: cast_nullable_to_non_nullable
as List<String>,ucis: null == ucis ? _self._ucis : ucis // ignore: cast_nullable_to_non_nullable
as List<String>,moveTimes: null == moveTimes ? _self._moveTimes : moveTimes // ignore: cast_nullable_to_non_nullable
as List<Duration>,turnElapsed: null == turnElapsed ? _self.turnElapsed : turnElapsed // ignore: cast_nullable_to_non_nullable
as Duration,turnStartedAt: freezed == turnStartedAt ? _self.turnStartedAt : turnStartedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,repetitions: null == repetitions ? _self.repetitions : repetitions // ignore: cast_nullable_to_non_nullable
as int,lastMove: freezed == lastMove ? _self.lastMove : lastMove // ignore: cast_nullable_to_non_nullable
as Move?,orientation: null == orientation ? _self.orientation : orientation // ignore: cast_nullable_to_non_nullable
as Side,playerSide: freezed == playerSide ? _self.playerSide : playerSide // ignore: cast_nullable_to_non_nullable
as Side?,clock: freezed == clock ? _self.clock : clock // ignore: cast_nullable_to_non_nullable
as ClockState?,whiteTime: null == whiteTime ? _self.whiteTime : whiteTime // ignore: cast_nullable_to_non_nullable
as Duration,blackTime: null == blackTime ? _self.blackTime : blackTime // ignore: cast_nullable_to_non_nullable
as Duration,forcedEnd: freezed == forcedEnd ? _self.forcedEnd : forcedEnd // ignore: cast_nullable_to_non_nullable
as GameEnd?,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as GameMode,machineThinking: null == machineThinking ? _self.machineThinking : machineThinking // ignore: cast_nullable_to_non_nullable
as bool,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,drawOffer: null == drawOffer ? _self.drawOffer : drawOffer // ignore: cast_nullable_to_non_nullable
as DrawOffer,drawDeclinedAt: freezed == drawDeclinedAt ? _self.drawDeclinedAt : drawDeclinedAt // ignore: cast_nullable_to_non_nullable
as int?,report: freezed == report ? _self.report : report // ignore: cast_nullable_to_non_nullable
as GameReport?,viewedPly: freezed == viewedPly ? _self.viewedPly : viewedPly // ignore: cast_nullable_to_non_nullable
as int?,viewedPosition: freezed == viewedPosition ? _self.viewedPosition : viewedPosition // ignore: cast_nullable_to_non_nullable
as Position?,viewedMove: freezed == viewedMove ? _self.viewedMove : viewedMove // ignore: cast_nullable_to_non_nullable
as Move?,
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
$GameEndCopyWith<$Res>? get forcedEnd {
    if (_self.forcedEnd == null) {
    return null;
  }

  return $GameEndCopyWith<$Res>(_self.forcedEnd!, (value) {
    return _then(_self.copyWith(forcedEnd: value));
  });
}/// Create a copy of FreeBoardState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameModeCopyWith<$Res> get mode {
  
  return $GameModeCopyWith<$Res>(_self.mode, (value) {
    return _then(_self.copyWith(mode: value));
  });
}
}

// dart format on
