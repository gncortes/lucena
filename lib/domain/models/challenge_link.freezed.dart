// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'challenge_link.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChallengeLink {

/// A posição de início.
 String get fen; PositionGoal get goal;/// O id da posição no catálogo (para o histórico). Nulo: personalizada.
 String? get positionId;/// O lado de quem joga o desafio.
 Side get userSide;/// Só `maia` ou `stockfish`: o desafio é sempre contra a máquina.
 OpponentKind get opponent;/// O nível do Maia. Nulo: o sugerido pelo rating de quem abre.
 int? get level;/// O tempo dos dois lados. Nulo: sem relógio.
 TimeControl? get clock;/// Às cegas, sem ver as peças.
 bool get blind;/// Desafio fechado: dá para ver os dados, não para trocar.
 bool get locked;/// O que a E1.16 conta por post (`utm_source`, `utm_medium`,
/// `utm_campaign`, `utm_content`): passa de quem mandou para quem abre.
/// O link criado no app leva `utm_source=app` (E1.03 §9).
 Map<String, String> get utm;/// Quantas vezes o link foi repassado (`g`, E1.03 §9): 0 no nosso post,
/// 1 no link de quem nunca chegou por link, e assim por diante. Fica fora
/// do código.
 int get generation;/// Em quantos lances quem mandou venceu o desafio (`mv`): só no link
/// criado depois de uma vitória. Fica fora do código; o resultado de quem
/// abre se compara com ele. Nulo: link sem resultado (os antigos).
 int? get senderMoves;
/// Create a copy of ChallengeLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChallengeLinkCopyWith<ChallengeLink> get copyWith => _$ChallengeLinkCopyWithImpl<ChallengeLink>(this as ChallengeLink, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ChallengeLink;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChallengeLink&&(identical(other.fen, _this.fen) || other.fen == _this.fen)&&(identical(other.goal, _this.goal) || other.goal == _this.goal)&&(identical(other.positionId, _this.positionId) || other.positionId == _this.positionId)&&(identical(other.userSide, _this.userSide) || other.userSide == _this.userSide)&&(identical(other.opponent, _this.opponent) || other.opponent == _this.opponent)&&(identical(other.level, _this.level) || other.level == _this.level)&&(identical(other.clock, _this.clock) || other.clock == _this.clock)&&(identical(other.blind, _this.blind) || other.blind == _this.blind)&&(identical(other.locked, _this.locked) || other.locked == _this.locked)&&const DeepCollectionEquality().equals(other.utm, _this.utm)&&(identical(other.generation, _this.generation) || other.generation == _this.generation)&&(identical(other.senderMoves, _this.senderMoves) || other.senderMoves == _this.senderMoves));
}


@override
int get hashCode {
  final _this = this as ChallengeLink;
  return Object.hash(runtimeType,_this.fen,_this.goal,_this.positionId,_this.userSide,_this.opponent,_this.level,_this.clock,_this.blind,_this.locked,const DeepCollectionEquality().hash(_this.utm),_this.generation,_this.senderMoves);
}

@override
String toString() {
  final _this = this as ChallengeLink;
  return 'ChallengeLink(fen: ${_this.fen}, goal: ${_this.goal}, positionId: ${_this.positionId}, userSide: ${_this.userSide}, opponent: ${_this.opponent}, level: ${_this.level}, clock: ${_this.clock}, blind: ${_this.blind}, locked: ${_this.locked}, utm: ${_this.utm}, generation: ${_this.generation}, senderMoves: ${_this.senderMoves})';
}


}

/// @nodoc
abstract mixin class $ChallengeLinkCopyWith<$Res>  {
  factory $ChallengeLinkCopyWith(ChallengeLink value, $Res Function(ChallengeLink) _then) = _$ChallengeLinkCopyWithImpl;
@useResult
$Res call({
 String fen, PositionGoal goal, String? positionId, Side userSide, OpponentKind opponent, int? level, TimeControl? clock, bool blind, bool locked, Map<String, String> utm, int generation, int? senderMoves
});


$TimeControlCopyWith<$Res>? get clock;

}
/// @nodoc
class _$ChallengeLinkCopyWithImpl<$Res>
    implements $ChallengeLinkCopyWith<$Res> {
  _$ChallengeLinkCopyWithImpl(this._self, this._then);

  final ChallengeLink _self;
  final $Res Function(ChallengeLink) _then;

/// Create a copy of ChallengeLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fen = null,Object? goal = null,Object? positionId = freezed,Object? userSide = null,Object? opponent = null,Object? level = freezed,Object? clock = freezed,Object? blind = null,Object? locked = null,Object? utm = null,Object? generation = null,Object? senderMoves = freezed,}) {
  return _then(ChallengeLink(
fen: null == fen ? _self.fen : fen // ignore: cast_nullable_to_non_nullable
as String,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as PositionGoal,positionId: freezed == positionId ? _self.positionId : positionId // ignore: cast_nullable_to_non_nullable
as String?,userSide: null == userSide ? _self.userSide : userSide // ignore: cast_nullable_to_non_nullable
as Side,opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as OpponentKind,level: freezed == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int?,clock: freezed == clock ? _self.clock : clock // ignore: cast_nullable_to_non_nullable
as TimeControl?,blind: null == blind ? _self.blind : blind // ignore: cast_nullable_to_non_nullable
as bool,locked: null == locked ? _self.locked : locked // ignore: cast_nullable_to_non_nullable
as bool,utm: null == utm ? _self.utm : utm // ignore: cast_nullable_to_non_nullable
as Map<String, String>,generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as int,senderMoves: freezed == senderMoves ? _self.senderMoves : senderMoves // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of ChallengeLink
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeControlCopyWith<$Res>? get clock {
    if (_self.clock == null) {
    return null;
  }

  return $TimeControlCopyWith<$Res>(_self.clock!, (value) {
    return _then(_self.copyWith(clock: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChallengeLink].
extension ChallengeLinkPatterns on ChallengeLink {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChallengeLink value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChallengeLink() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChallengeLink value)  $default,){
final _that = this;
switch (_that) {
case _ChallengeLink():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChallengeLink value)?  $default,){
final _that = this;
switch (_that) {
case _ChallengeLink() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fen,  PositionGoal goal,  String? positionId,  Side userSide,  OpponentKind opponent,  int? level,  TimeControl? clock,  bool blind,  bool locked,  Map<String, String> utm,  int generation,  int? senderMoves)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChallengeLink() when $default != null:
return $default(_that.fen,_that.goal,_that.positionId,_that.userSide,_that.opponent,_that.level,_that.clock,_that.blind,_that.locked,_that.utm,_that.generation,_that.senderMoves);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fen,  PositionGoal goal,  String? positionId,  Side userSide,  OpponentKind opponent,  int? level,  TimeControl? clock,  bool blind,  bool locked,  Map<String, String> utm,  int generation,  int? senderMoves)  $default,) {final _that = this;
switch (_that) {
case _ChallengeLink():
return $default(_that.fen,_that.goal,_that.positionId,_that.userSide,_that.opponent,_that.level,_that.clock,_that.blind,_that.locked,_that.utm,_that.generation,_that.senderMoves);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fen,  PositionGoal goal,  String? positionId,  Side userSide,  OpponentKind opponent,  int? level,  TimeControl? clock,  bool blind,  bool locked,  Map<String, String> utm,  int generation,  int? senderMoves)?  $default,) {final _that = this;
switch (_that) {
case _ChallengeLink() when $default != null:
return $default(_that.fen,_that.goal,_that.positionId,_that.userSide,_that.opponent,_that.level,_that.clock,_that.blind,_that.locked,_that.utm,_that.generation,_that.senderMoves);case _:
  return null;

}
}

}

/// @nodoc


class _ChallengeLink extends ChallengeLink {
  const _ChallengeLink({required this.fen, this.goal = PositionGoal.win, this.positionId, required this.userSide, this.opponent = OpponentKind.maia, this.level, this.clock, this.blind = false, this.locked = false,  Map<String, String> utm = const <String, String>{}, this.generation = 0, this.senderMoves}): _utm = utm,super._();
  

/// A posição de início.
@override final  String fen;
@override@JsonKey() final  PositionGoal goal;
/// O id da posição no catálogo (para o histórico). Nulo: personalizada.
@override final  String? positionId;
/// O lado de quem joga o desafio.
@override final  Side userSide;
/// Só `maia` ou `stockfish`: o desafio é sempre contra a máquina.
@override@JsonKey() final  OpponentKind opponent;
/// O nível do Maia. Nulo: o sugerido pelo rating de quem abre.
@override final  int? level;
/// O tempo dos dois lados. Nulo: sem relógio.
@override final  TimeControl? clock;
/// Às cegas, sem ver as peças.
@override@JsonKey() final  bool blind;
/// Desafio fechado: dá para ver os dados, não para trocar.
@override@JsonKey() final  bool locked;
/// O que a E1.16 conta por post (`utm_source`, `utm_medium`,
/// `utm_campaign`, `utm_content`): passa de quem mandou para quem abre.
/// O link criado no app leva `utm_source=app` (E1.03 §9).
 final  Map<String, String> _utm;
/// O que a E1.16 conta por post (`utm_source`, `utm_medium`,
/// `utm_campaign`, `utm_content`): passa de quem mandou para quem abre.
/// O link criado no app leva `utm_source=app` (E1.03 §9).
@override@JsonKey() Map<String, String> get utm {
  if (_utm is EqualUnmodifiableMapView) return _utm;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_utm);
}

/// Quantas vezes o link foi repassado (`g`, E1.03 §9): 0 no nosso post,
/// 1 no link de quem nunca chegou por link, e assim por diante. Fica fora
/// do código.
@override@JsonKey() final  int generation;
/// Em quantos lances quem mandou venceu o desafio (`mv`): só no link
/// criado depois de uma vitória. Fica fora do código; o resultado de quem
/// abre se compara com ele. Nulo: link sem resultado (os antigos).
@override final  int? senderMoves;

/// Create a copy of ChallengeLink
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChallengeLinkCopyWith<_ChallengeLink> get copyWith => __$ChallengeLinkCopyWithImpl<_ChallengeLink>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChallengeLink&&(identical(other.fen, fen) || other.fen == fen)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.positionId, positionId) || other.positionId == positionId)&&(identical(other.userSide, userSide) || other.userSide == userSide)&&(identical(other.opponent, opponent) || other.opponent == opponent)&&(identical(other.level, level) || other.level == level)&&(identical(other.clock, clock) || other.clock == clock)&&(identical(other.blind, blind) || other.blind == blind)&&(identical(other.locked, locked) || other.locked == locked)&&const DeepCollectionEquality().equals(other.utm, _utm)&&(identical(other.generation, generation) || other.generation == generation)&&(identical(other.senderMoves, senderMoves) || other.senderMoves == senderMoves));
}


@override
int get hashCode {
    return Object.hash(runtimeType,fen,goal,positionId,userSide,opponent,level,clock,blind,locked,const DeepCollectionEquality().hash(_utm),generation,senderMoves);
}

@override
String toString() {
    return 'ChallengeLink(fen: $fen, goal: $goal, positionId: $positionId, userSide: $userSide, opponent: $opponent, level: $level, clock: $clock, blind: $blind, locked: $locked, utm: $utm, generation: $generation, senderMoves: $senderMoves)';
}


}

/// @nodoc
abstract mixin class _$ChallengeLinkCopyWith<$Res> implements $ChallengeLinkCopyWith<$Res> {
  factory _$ChallengeLinkCopyWith(_ChallengeLink value, $Res Function(_ChallengeLink) _then) = __$ChallengeLinkCopyWithImpl;
@override @useResult
$Res call({
 String fen, PositionGoal goal, String? positionId, Side userSide, OpponentKind opponent, int? level, TimeControl? clock, bool blind, bool locked, Map<String, String> utm, int generation, int? senderMoves
});


@override $TimeControlCopyWith<$Res>? get clock;

}
/// @nodoc
class __$ChallengeLinkCopyWithImpl<$Res>
    implements _$ChallengeLinkCopyWith<$Res> {
  __$ChallengeLinkCopyWithImpl(this._self, this._then);

  final _ChallengeLink _self;
  final $Res Function(_ChallengeLink) _then;

/// Create a copy of ChallengeLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fen = null,Object? goal = null,Object? positionId = freezed,Object? userSide = null,Object? opponent = null,Object? level = freezed,Object? clock = freezed,Object? blind = null,Object? locked = null,Object? utm = null,Object? generation = null,Object? senderMoves = freezed,}) {
  return _then(_ChallengeLink(
fen: null == fen ? _self.fen : fen // ignore: cast_nullable_to_non_nullable
as String,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as PositionGoal,positionId: freezed == positionId ? _self.positionId : positionId // ignore: cast_nullable_to_non_nullable
as String?,userSide: null == userSide ? _self.userSide : userSide // ignore: cast_nullable_to_non_nullable
as Side,opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as OpponentKind,level: freezed == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int?,clock: freezed == clock ? _self.clock : clock // ignore: cast_nullable_to_non_nullable
as TimeControl?,blind: null == blind ? _self.blind : blind // ignore: cast_nullable_to_non_nullable
as bool,locked: null == locked ? _self.locked : locked // ignore: cast_nullable_to_non_nullable
as bool,utm: null == utm ? _self._utm : utm // ignore: cast_nullable_to_non_nullable
as Map<String, String>,generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as int,senderMoves: freezed == senderMoves ? _self.senderMoves : senderMoves // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of ChallengeLink
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeControlCopyWith<$Res>? get clock {
    if (_self.clock == null) {
    return null;
  }

  return $TimeControlCopyWith<$Res>(_self.clock!, (value) {
    return _then(_self.copyWith(clock: value));
  });
}
}

// dart format on
