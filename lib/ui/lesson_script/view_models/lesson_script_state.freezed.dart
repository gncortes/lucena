// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lesson_script_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LessonScriptState {

/// Falso até o roteiro, as falas e a tabela carregarem.
 bool get ready; int get stageIndex; int get stageCount;/// `ideia`, `demos` ou `pratica`.
 String get stageId; int get exampleIndex; int get exampleCount; ScriptPhase get phase;/// A posição do tabuleiro.
 String get fen;/// O lado que fica embaixo (e o lado do aluno).
 Side get orientation;/// O último lance (UCI), para destacar.
 String? get lastMove;/// Os balões, já com o texto. Mais de um quando os trechos cabem juntos.
 List<String> get speech; ScriptTone get tone; List<String> get marks; List<ScriptArrow> get arrows;/// O botão principal e o secundário. Nulos: não aparece.
 ScriptAction? get primary; ScriptAction? get secondary;/// O ◀ está ativo.
 bool get canBack;/// O lado que pode mexer peças agora. Nulo: o tabuleiro não aceita toque.
 Side? get movable;/// Os destinos que o tabuleiro aceita de cada peça, quando [movable] não
/// é nulo. Vale também sem rei (lições de peça do curso de iniciante), em
/// que o `GameRules` não monta a posição.
 Map<Square, Set<Square>>? get dests;/// As estrelas que faltam pegar (prática do tipo estrelas).
 List<String> get stars;/// A máquina está para responder.
 bool get machineThinking;/// Os lances já vistos, na ordem da lista, e o atual.
 List<ScriptMoveEntry> get moves; String? get currentMoveId; ScriptTransition get transition;/// A folha Curiosidades do exemplo; nula se não tem (esconde o livro).
 ScriptCuriosities? get curiosities;/// A demonstração automática (etapa 2); nula fora dela.
 ScriptDemo? get demo;/// Preenchido quando a parte foi concluída (`finishPart`).
 LessonOutcome? get outcome;
/// Create a copy of LessonScriptState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonScriptStateCopyWith<LessonScriptState> get copyWith => _$LessonScriptStateCopyWithImpl<LessonScriptState>(this as LessonScriptState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LessonScriptState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LessonScriptState&&(identical(other.ready, _this.ready) || other.ready == _this.ready)&&(identical(other.stageIndex, _this.stageIndex) || other.stageIndex == _this.stageIndex)&&(identical(other.stageCount, _this.stageCount) || other.stageCount == _this.stageCount)&&(identical(other.stageId, _this.stageId) || other.stageId == _this.stageId)&&(identical(other.exampleIndex, _this.exampleIndex) || other.exampleIndex == _this.exampleIndex)&&(identical(other.exampleCount, _this.exampleCount) || other.exampleCount == _this.exampleCount)&&(identical(other.phase, _this.phase) || other.phase == _this.phase)&&(identical(other.fen, _this.fen) || other.fen == _this.fen)&&(identical(other.orientation, _this.orientation) || other.orientation == _this.orientation)&&(identical(other.lastMove, _this.lastMove) || other.lastMove == _this.lastMove)&&const DeepCollectionEquality().equals(other.speech, _this.speech)&&(identical(other.tone, _this.tone) || other.tone == _this.tone)&&const DeepCollectionEquality().equals(other.marks, _this.marks)&&const DeepCollectionEquality().equals(other.arrows, _this.arrows)&&(identical(other.primary, _this.primary) || other.primary == _this.primary)&&(identical(other.secondary, _this.secondary) || other.secondary == _this.secondary)&&(identical(other.canBack, _this.canBack) || other.canBack == _this.canBack)&&(identical(other.movable, _this.movable) || other.movable == _this.movable)&&const DeepCollectionEquality().equals(other.dests, _this.dests)&&const DeepCollectionEquality().equals(other.stars, _this.stars)&&(identical(other.machineThinking, _this.machineThinking) || other.machineThinking == _this.machineThinking)&&const DeepCollectionEquality().equals(other.moves, _this.moves)&&(identical(other.currentMoveId, _this.currentMoveId) || other.currentMoveId == _this.currentMoveId)&&(identical(other.transition, _this.transition) || other.transition == _this.transition)&&(identical(other.curiosities, _this.curiosities) || other.curiosities == _this.curiosities)&&(identical(other.demo, _this.demo) || other.demo == _this.demo)&&(identical(other.outcome, _this.outcome) || other.outcome == _this.outcome));
}


@override
int get hashCode {
  final _this = this as LessonScriptState;
  return Object.hashAll([runtimeType,_this.ready,_this.stageIndex,_this.stageCount,_this.stageId,_this.exampleIndex,_this.exampleCount,_this.phase,_this.fen,_this.orientation,_this.lastMove,const DeepCollectionEquality().hash(_this.speech),_this.tone,const DeepCollectionEquality().hash(_this.marks),const DeepCollectionEquality().hash(_this.arrows),_this.primary,_this.secondary,_this.canBack,_this.movable,const DeepCollectionEquality().hash(_this.dests),const DeepCollectionEquality().hash(_this.stars),_this.machineThinking,const DeepCollectionEquality().hash(_this.moves),_this.currentMoveId,_this.transition,_this.curiosities,_this.demo,_this.outcome]);
}

@override
String toString() {
  final _this = this as LessonScriptState;
  return 'LessonScriptState(ready: ${_this.ready}, stageIndex: ${_this.stageIndex}, stageCount: ${_this.stageCount}, stageId: ${_this.stageId}, exampleIndex: ${_this.exampleIndex}, exampleCount: ${_this.exampleCount}, phase: ${_this.phase}, fen: ${_this.fen}, orientation: ${_this.orientation}, lastMove: ${_this.lastMove}, speech: ${_this.speech}, tone: ${_this.tone}, marks: ${_this.marks}, arrows: ${_this.arrows}, primary: ${_this.primary}, secondary: ${_this.secondary}, canBack: ${_this.canBack}, movable: ${_this.movable}, dests: ${_this.dests}, stars: ${_this.stars}, machineThinking: ${_this.machineThinking}, moves: ${_this.moves}, currentMoveId: ${_this.currentMoveId}, transition: ${_this.transition}, curiosities: ${_this.curiosities}, demo: ${_this.demo}, outcome: ${_this.outcome})';
}


}

/// @nodoc
abstract mixin class $LessonScriptStateCopyWith<$Res>  {
  factory $LessonScriptStateCopyWith(LessonScriptState value, $Res Function(LessonScriptState) _then) = _$LessonScriptStateCopyWithImpl;
@useResult
$Res call({
 bool ready, int stageIndex, int stageCount, String stageId, int exampleIndex, int exampleCount, ScriptPhase phase, String fen, Side orientation, String? lastMove, List<String> speech, ScriptTone tone, List<String> marks, List<ScriptArrow> arrows, ScriptAction? primary, ScriptAction? secondary, bool canBack, Side? movable, Map<Square, Set<Square>>? dests, List<String> stars, bool machineThinking, List<ScriptMoveEntry> moves, String? currentMoveId, ScriptTransition transition, ScriptCuriosities? curiosities, ScriptDemo? demo, LessonOutcome? outcome
});




}
/// @nodoc
class _$LessonScriptStateCopyWithImpl<$Res>
    implements $LessonScriptStateCopyWith<$Res> {
  _$LessonScriptStateCopyWithImpl(this._self, this._then);

  final LessonScriptState _self;
  final $Res Function(LessonScriptState) _then;

/// Create a copy of LessonScriptState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ready = null,Object? stageIndex = null,Object? stageCount = null,Object? stageId = null,Object? exampleIndex = null,Object? exampleCount = null,Object? phase = null,Object? fen = null,Object? orientation = null,Object? lastMove = freezed,Object? speech = null,Object? tone = null,Object? marks = null,Object? arrows = null,Object? primary = freezed,Object? secondary = freezed,Object? canBack = null,Object? movable = freezed,Object? dests = freezed,Object? stars = null,Object? machineThinking = null,Object? moves = null,Object? currentMoveId = freezed,Object? transition = null,Object? curiosities = freezed,Object? demo = freezed,Object? outcome = freezed,}) {
  return _then(LessonScriptState(
ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
as bool,stageIndex: null == stageIndex ? _self.stageIndex : stageIndex // ignore: cast_nullable_to_non_nullable
as int,stageCount: null == stageCount ? _self.stageCount : stageCount // ignore: cast_nullable_to_non_nullable
as int,stageId: null == stageId ? _self.stageId : stageId // ignore: cast_nullable_to_non_nullable
as String,exampleIndex: null == exampleIndex ? _self.exampleIndex : exampleIndex // ignore: cast_nullable_to_non_nullable
as int,exampleCount: null == exampleCount ? _self.exampleCount : exampleCount // ignore: cast_nullable_to_non_nullable
as int,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as ScriptPhase,fen: null == fen ? _self.fen : fen // ignore: cast_nullable_to_non_nullable
as String,orientation: null == orientation ? _self.orientation : orientation // ignore: cast_nullable_to_non_nullable
as Side,lastMove: freezed == lastMove ? _self.lastMove : lastMove // ignore: cast_nullable_to_non_nullable
as String?,speech: null == speech ? _self.speech : speech // ignore: cast_nullable_to_non_nullable
as List<String>,tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as ScriptTone,marks: null == marks ? _self.marks : marks // ignore: cast_nullable_to_non_nullable
as List<String>,arrows: null == arrows ? _self.arrows : arrows // ignore: cast_nullable_to_non_nullable
as List<ScriptArrow>,primary: freezed == primary ? _self.primary : primary // ignore: cast_nullable_to_non_nullable
as ScriptAction?,secondary: freezed == secondary ? _self.secondary : secondary // ignore: cast_nullable_to_non_nullable
as ScriptAction?,canBack: null == canBack ? _self.canBack : canBack // ignore: cast_nullable_to_non_nullable
as bool,movable: freezed == movable ? _self.movable : movable // ignore: cast_nullable_to_non_nullable
as Side?,dests: freezed == dests ? _self.dests : dests // ignore: cast_nullable_to_non_nullable
as Map<Square, Set<Square>>?,stars: null == stars ? _self.stars : stars // ignore: cast_nullable_to_non_nullable
as List<String>,machineThinking: null == machineThinking ? _self.machineThinking : machineThinking // ignore: cast_nullable_to_non_nullable
as bool,moves: null == moves ? _self.moves : moves // ignore: cast_nullable_to_non_nullable
as List<ScriptMoveEntry>,currentMoveId: freezed == currentMoveId ? _self.currentMoveId : currentMoveId // ignore: cast_nullable_to_non_nullable
as String?,transition: null == transition ? _self.transition : transition // ignore: cast_nullable_to_non_nullable
as ScriptTransition,curiosities: freezed == curiosities ? _self.curiosities : curiosities // ignore: cast_nullable_to_non_nullable
as ScriptCuriosities?,demo: freezed == demo ? _self.demo : demo // ignore: cast_nullable_to_non_nullable
as ScriptDemo?,outcome: freezed == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as LessonOutcome?,
  ));
}

}


/// Adds pattern-matching-related methods to [LessonScriptState].
extension LessonScriptStatePatterns on LessonScriptState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LessonScriptState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LessonScriptState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LessonScriptState value)  $default,){
final _that = this;
switch (_that) {
case _LessonScriptState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LessonScriptState value)?  $default,){
final _that = this;
switch (_that) {
case _LessonScriptState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool ready,  int stageIndex,  int stageCount,  String stageId,  int exampleIndex,  int exampleCount,  ScriptPhase phase,  String fen,  Side orientation,  String? lastMove,  List<String> speech,  ScriptTone tone,  List<String> marks,  List<ScriptArrow> arrows,  ScriptAction? primary,  ScriptAction? secondary,  bool canBack,  Side? movable,  Map<Square, Set<Square>>? dests,  List<String> stars,  bool machineThinking,  List<ScriptMoveEntry> moves,  String? currentMoveId,  ScriptTransition transition,  ScriptCuriosities? curiosities,  ScriptDemo? demo,  LessonOutcome? outcome)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LessonScriptState() when $default != null:
return $default(_that.ready,_that.stageIndex,_that.stageCount,_that.stageId,_that.exampleIndex,_that.exampleCount,_that.phase,_that.fen,_that.orientation,_that.lastMove,_that.speech,_that.tone,_that.marks,_that.arrows,_that.primary,_that.secondary,_that.canBack,_that.movable,_that.dests,_that.stars,_that.machineThinking,_that.moves,_that.currentMoveId,_that.transition,_that.curiosities,_that.demo,_that.outcome);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool ready,  int stageIndex,  int stageCount,  String stageId,  int exampleIndex,  int exampleCount,  ScriptPhase phase,  String fen,  Side orientation,  String? lastMove,  List<String> speech,  ScriptTone tone,  List<String> marks,  List<ScriptArrow> arrows,  ScriptAction? primary,  ScriptAction? secondary,  bool canBack,  Side? movable,  Map<Square, Set<Square>>? dests,  List<String> stars,  bool machineThinking,  List<ScriptMoveEntry> moves,  String? currentMoveId,  ScriptTransition transition,  ScriptCuriosities? curiosities,  ScriptDemo? demo,  LessonOutcome? outcome)  $default,) {final _that = this;
switch (_that) {
case _LessonScriptState():
return $default(_that.ready,_that.stageIndex,_that.stageCount,_that.stageId,_that.exampleIndex,_that.exampleCount,_that.phase,_that.fen,_that.orientation,_that.lastMove,_that.speech,_that.tone,_that.marks,_that.arrows,_that.primary,_that.secondary,_that.canBack,_that.movable,_that.dests,_that.stars,_that.machineThinking,_that.moves,_that.currentMoveId,_that.transition,_that.curiosities,_that.demo,_that.outcome);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool ready,  int stageIndex,  int stageCount,  String stageId,  int exampleIndex,  int exampleCount,  ScriptPhase phase,  String fen,  Side orientation,  String? lastMove,  List<String> speech,  ScriptTone tone,  List<String> marks,  List<ScriptArrow> arrows,  ScriptAction? primary,  ScriptAction? secondary,  bool canBack,  Side? movable,  Map<Square, Set<Square>>? dests,  List<String> stars,  bool machineThinking,  List<ScriptMoveEntry> moves,  String? currentMoveId,  ScriptTransition transition,  ScriptCuriosities? curiosities,  ScriptDemo? demo,  LessonOutcome? outcome)?  $default,) {final _that = this;
switch (_that) {
case _LessonScriptState() when $default != null:
return $default(_that.ready,_that.stageIndex,_that.stageCount,_that.stageId,_that.exampleIndex,_that.exampleCount,_that.phase,_that.fen,_that.orientation,_that.lastMove,_that.speech,_that.tone,_that.marks,_that.arrows,_that.primary,_that.secondary,_that.canBack,_that.movable,_that.dests,_that.stars,_that.machineThinking,_that.moves,_that.currentMoveId,_that.transition,_that.curiosities,_that.demo,_that.outcome);case _:
  return null;

}
}

}

/// @nodoc


class _LessonScriptState implements LessonScriptState {
  const _LessonScriptState({this.ready = false, this.stageIndex = 0, this.stageCount = 1, this.stageId = '', this.exampleIndex = 0, this.exampleCount = 1, this.phase = ScriptPhase.entrada, this.fen = '', this.orientation = Side.white, this.lastMove,  List<String> speech = const <String>[], this.tone = ScriptTone.neutral,  List<String> marks = const <String>[],  List<ScriptArrow> arrows = const <ScriptArrow>[], this.primary, this.secondary, this.canBack = false, this.movable,  Map<Square, Set<Square>>? dests,  List<String> stars = const <String>[], this.machineThinking = false,  List<ScriptMoveEntry> moves = const <ScriptMoveEntry>[], this.currentMoveId, this.transition = const ScriptTransition(id: 0), this.curiosities, this.demo, this.outcome}): _speech = speech,_marks = marks,_arrows = arrows,_dests = dests,_stars = stars,_moves = moves;
  

/// Falso até o roteiro, as falas e a tabela carregarem.
@override@JsonKey() final  bool ready;
@override@JsonKey() final  int stageIndex;
@override@JsonKey() final  int stageCount;
/// `ideia`, `demos` ou `pratica`.
@override@JsonKey() final  String stageId;
@override@JsonKey() final  int exampleIndex;
@override@JsonKey() final  int exampleCount;
@override@JsonKey() final  ScriptPhase phase;
/// A posição do tabuleiro.
@override@JsonKey() final  String fen;
/// O lado que fica embaixo (e o lado do aluno).
@override@JsonKey() final  Side orientation;
/// O último lance (UCI), para destacar.
@override final  String? lastMove;
/// Os balões, já com o texto. Mais de um quando os trechos cabem juntos.
 final  List<String> _speech;
/// Os balões, já com o texto. Mais de um quando os trechos cabem juntos.
@override@JsonKey() List<String> get speech {
  if (_speech is EqualUnmodifiableListView) return _speech;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_speech);
}

@override@JsonKey() final  ScriptTone tone;
 final  List<String> _marks;
@override@JsonKey() List<String> get marks {
  if (_marks is EqualUnmodifiableListView) return _marks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_marks);
}

 final  List<ScriptArrow> _arrows;
@override@JsonKey() List<ScriptArrow> get arrows {
  if (_arrows is EqualUnmodifiableListView) return _arrows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_arrows);
}

/// O botão principal e o secundário. Nulos: não aparece.
@override final  ScriptAction? primary;
@override final  ScriptAction? secondary;
/// O ◀ está ativo.
@override@JsonKey() final  bool canBack;
/// O lado que pode mexer peças agora. Nulo: o tabuleiro não aceita toque.
@override final  Side? movable;
/// Os destinos que o tabuleiro aceita de cada peça, quando [movable] não
/// é nulo. Vale também sem rei (lições de peça do curso de iniciante), em
/// que o `GameRules` não monta a posição.
 final  Map<Square, Set<Square>>? _dests;
/// Os destinos que o tabuleiro aceita de cada peça, quando [movable] não
/// é nulo. Vale também sem rei (lições de peça do curso de iniciante), em
/// que o `GameRules` não monta a posição.
@override Map<Square, Set<Square>>? get dests {
  final value = _dests;
  if (value == null) return null;
  if (_dests is EqualUnmodifiableMapView) return _dests;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// As estrelas que faltam pegar (prática do tipo estrelas).
 final  List<String> _stars;
/// As estrelas que faltam pegar (prática do tipo estrelas).
@override@JsonKey() List<String> get stars {
  if (_stars is EqualUnmodifiableListView) return _stars;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stars);
}

/// A máquina está para responder.
@override@JsonKey() final  bool machineThinking;
/// Os lances já vistos, na ordem da lista, e o atual.
 final  List<ScriptMoveEntry> _moves;
/// Os lances já vistos, na ordem da lista, e o atual.
@override@JsonKey() List<ScriptMoveEntry> get moves {
  if (_moves is EqualUnmodifiableListView) return _moves;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_moves);
}

@override final  String? currentMoveId;
@override@JsonKey() final  ScriptTransition transition;
/// A folha Curiosidades do exemplo; nula se não tem (esconde o livro).
@override final  ScriptCuriosities? curiosities;
/// A demonstração automática (etapa 2); nula fora dela.
@override final  ScriptDemo? demo;
/// Preenchido quando a parte foi concluída (`finishPart`).
@override final  LessonOutcome? outcome;

/// Create a copy of LessonScriptState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonScriptStateCopyWith<_LessonScriptState> get copyWith => __$LessonScriptStateCopyWithImpl<_LessonScriptState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LessonScriptState&&(identical(other.ready, ready) || other.ready == ready)&&(identical(other.stageIndex, stageIndex) || other.stageIndex == stageIndex)&&(identical(other.stageCount, stageCount) || other.stageCount == stageCount)&&(identical(other.stageId, stageId) || other.stageId == stageId)&&(identical(other.exampleIndex, exampleIndex) || other.exampleIndex == exampleIndex)&&(identical(other.exampleCount, exampleCount) || other.exampleCount == exampleCount)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.fen, fen) || other.fen == fen)&&(identical(other.orientation, orientation) || other.orientation == orientation)&&(identical(other.lastMove, lastMove) || other.lastMove == lastMove)&&const DeepCollectionEquality().equals(other.speech, _speech)&&(identical(other.tone, tone) || other.tone == tone)&&const DeepCollectionEquality().equals(other.marks, _marks)&&const DeepCollectionEquality().equals(other.arrows, _arrows)&&(identical(other.primary, primary) || other.primary == primary)&&(identical(other.secondary, secondary) || other.secondary == secondary)&&(identical(other.canBack, canBack) || other.canBack == canBack)&&(identical(other.movable, movable) || other.movable == movable)&&const DeepCollectionEquality().equals(other.dests, _dests)&&const DeepCollectionEquality().equals(other.stars, _stars)&&(identical(other.machineThinking, machineThinking) || other.machineThinking == machineThinking)&&const DeepCollectionEquality().equals(other.moves, _moves)&&(identical(other.currentMoveId, currentMoveId) || other.currentMoveId == currentMoveId)&&(identical(other.transition, transition) || other.transition == transition)&&(identical(other.curiosities, curiosities) || other.curiosities == curiosities)&&(identical(other.demo, demo) || other.demo == demo)&&(identical(other.outcome, outcome) || other.outcome == outcome));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,ready,stageIndex,stageCount,stageId,exampleIndex,exampleCount,phase,fen,orientation,lastMove,const DeepCollectionEquality().hash(_speech),tone,const DeepCollectionEquality().hash(_marks),const DeepCollectionEquality().hash(_arrows),primary,secondary,canBack,movable,const DeepCollectionEquality().hash(_dests),const DeepCollectionEquality().hash(_stars),machineThinking,const DeepCollectionEquality().hash(_moves),currentMoveId,transition,curiosities,demo,outcome]);
}

@override
String toString() {
    return 'LessonScriptState(ready: $ready, stageIndex: $stageIndex, stageCount: $stageCount, stageId: $stageId, exampleIndex: $exampleIndex, exampleCount: $exampleCount, phase: $phase, fen: $fen, orientation: $orientation, lastMove: $lastMove, speech: $speech, tone: $tone, marks: $marks, arrows: $arrows, primary: $primary, secondary: $secondary, canBack: $canBack, movable: $movable, dests: $dests, stars: $stars, machineThinking: $machineThinking, moves: $moves, currentMoveId: $currentMoveId, transition: $transition, curiosities: $curiosities, demo: $demo, outcome: $outcome)';
}


}

/// @nodoc
abstract mixin class _$LessonScriptStateCopyWith<$Res> implements $LessonScriptStateCopyWith<$Res> {
  factory _$LessonScriptStateCopyWith(_LessonScriptState value, $Res Function(_LessonScriptState) _then) = __$LessonScriptStateCopyWithImpl;
@override @useResult
$Res call({
 bool ready, int stageIndex, int stageCount, String stageId, int exampleIndex, int exampleCount, ScriptPhase phase, String fen, Side orientation, String? lastMove, List<String> speech, ScriptTone tone, List<String> marks, List<ScriptArrow> arrows, ScriptAction? primary, ScriptAction? secondary, bool canBack, Side? movable, Map<Square, Set<Square>>? dests, List<String> stars, bool machineThinking, List<ScriptMoveEntry> moves, String? currentMoveId, ScriptTransition transition, ScriptCuriosities? curiosities, ScriptDemo? demo, LessonOutcome? outcome
});




}
/// @nodoc
class __$LessonScriptStateCopyWithImpl<$Res>
    implements _$LessonScriptStateCopyWith<$Res> {
  __$LessonScriptStateCopyWithImpl(this._self, this._then);

  final _LessonScriptState _self;
  final $Res Function(_LessonScriptState) _then;

/// Create a copy of LessonScriptState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ready = null,Object? stageIndex = null,Object? stageCount = null,Object? stageId = null,Object? exampleIndex = null,Object? exampleCount = null,Object? phase = null,Object? fen = null,Object? orientation = null,Object? lastMove = freezed,Object? speech = null,Object? tone = null,Object? marks = null,Object? arrows = null,Object? primary = freezed,Object? secondary = freezed,Object? canBack = null,Object? movable = freezed,Object? dests = freezed,Object? stars = null,Object? machineThinking = null,Object? moves = null,Object? currentMoveId = freezed,Object? transition = null,Object? curiosities = freezed,Object? demo = freezed,Object? outcome = freezed,}) {
  return _then(_LessonScriptState(
ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
as bool,stageIndex: null == stageIndex ? _self.stageIndex : stageIndex // ignore: cast_nullable_to_non_nullable
as int,stageCount: null == stageCount ? _self.stageCount : stageCount // ignore: cast_nullable_to_non_nullable
as int,stageId: null == stageId ? _self.stageId : stageId // ignore: cast_nullable_to_non_nullable
as String,exampleIndex: null == exampleIndex ? _self.exampleIndex : exampleIndex // ignore: cast_nullable_to_non_nullable
as int,exampleCount: null == exampleCount ? _self.exampleCount : exampleCount // ignore: cast_nullable_to_non_nullable
as int,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as ScriptPhase,fen: null == fen ? _self.fen : fen // ignore: cast_nullable_to_non_nullable
as String,orientation: null == orientation ? _self.orientation : orientation // ignore: cast_nullable_to_non_nullable
as Side,lastMove: freezed == lastMove ? _self.lastMove : lastMove // ignore: cast_nullable_to_non_nullable
as String?,speech: null == speech ? _self._speech : speech // ignore: cast_nullable_to_non_nullable
as List<String>,tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as ScriptTone,marks: null == marks ? _self._marks : marks // ignore: cast_nullable_to_non_nullable
as List<String>,arrows: null == arrows ? _self._arrows : arrows // ignore: cast_nullable_to_non_nullable
as List<ScriptArrow>,primary: freezed == primary ? _self.primary : primary // ignore: cast_nullable_to_non_nullable
as ScriptAction?,secondary: freezed == secondary ? _self.secondary : secondary // ignore: cast_nullable_to_non_nullable
as ScriptAction?,canBack: null == canBack ? _self.canBack : canBack // ignore: cast_nullable_to_non_nullable
as bool,movable: freezed == movable ? _self.movable : movable // ignore: cast_nullable_to_non_nullable
as Side?,dests: freezed == dests ? _self._dests : dests // ignore: cast_nullable_to_non_nullable
as Map<Square, Set<Square>>?,stars: null == stars ? _self._stars : stars // ignore: cast_nullable_to_non_nullable
as List<String>,machineThinking: null == machineThinking ? _self.machineThinking : machineThinking // ignore: cast_nullable_to_non_nullable
as bool,moves: null == moves ? _self._moves : moves // ignore: cast_nullable_to_non_nullable
as List<ScriptMoveEntry>,currentMoveId: freezed == currentMoveId ? _self.currentMoveId : currentMoveId // ignore: cast_nullable_to_non_nullable
as String?,transition: null == transition ? _self.transition : transition // ignore: cast_nullable_to_non_nullable
as ScriptTransition,curiosities: freezed == curiosities ? _self.curiosities : curiosities // ignore: cast_nullable_to_non_nullable
as ScriptCuriosities?,demo: freezed == demo ? _self.demo : demo // ignore: cast_nullable_to_non_nullable
as ScriptDemo?,outcome: freezed == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as LessonOutcome?,
  ));
}


}

// dart format on
