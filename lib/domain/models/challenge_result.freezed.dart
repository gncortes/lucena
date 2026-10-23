// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'challenge_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChallengeResult {

/// O desafio jogado: o link que a imagem leva.
 ChallengeLink get link; AttemptOutcome get outcome;/// Quantos lances o jogador fez.
 int get moves;/// Quanto sobrou no relógio dele. Nulo: partida sem relógio.
 Duration? get remaining;/// A peça que deu o mate. Nulo: o jogador não deu mate.
 Role? get matingPiece;/// A posição final, para o tabuleiro pequeno da imagem.
 String get finalFen;/// O último lance da partida, em destaque na miniatura.
 Move? get lastMove;
/// Create a copy of ChallengeResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChallengeResultCopyWith<ChallengeResult> get copyWith => _$ChallengeResultCopyWithImpl<ChallengeResult>(this as ChallengeResult, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ChallengeResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChallengeResult&&(identical(other.link, _this.link) || other.link == _this.link)&&(identical(other.outcome, _this.outcome) || other.outcome == _this.outcome)&&(identical(other.moves, _this.moves) || other.moves == _this.moves)&&(identical(other.remaining, _this.remaining) || other.remaining == _this.remaining)&&(identical(other.matingPiece, _this.matingPiece) || other.matingPiece == _this.matingPiece)&&(identical(other.finalFen, _this.finalFen) || other.finalFen == _this.finalFen)&&(identical(other.lastMove, _this.lastMove) || other.lastMove == _this.lastMove));
}


@override
int get hashCode {
  final _this = this as ChallengeResult;
  return Object.hash(runtimeType,_this.link,_this.outcome,_this.moves,_this.remaining,_this.matingPiece,_this.finalFen,_this.lastMove);
}

@override
String toString() {
  final _this = this as ChallengeResult;
  return 'ChallengeResult(link: ${_this.link}, outcome: ${_this.outcome}, moves: ${_this.moves}, remaining: ${_this.remaining}, matingPiece: ${_this.matingPiece}, finalFen: ${_this.finalFen}, lastMove: ${_this.lastMove})';
}


}

/// @nodoc
abstract mixin class $ChallengeResultCopyWith<$Res>  {
  factory $ChallengeResultCopyWith(ChallengeResult value, $Res Function(ChallengeResult) _then) = _$ChallengeResultCopyWithImpl;
@useResult
$Res call({
 ChallengeLink link, AttemptOutcome outcome, int moves, Duration? remaining, Role? matingPiece, String finalFen, Move? lastMove
});


$ChallengeLinkCopyWith<$Res> get link;

}
/// @nodoc
class _$ChallengeResultCopyWithImpl<$Res>
    implements $ChallengeResultCopyWith<$Res> {
  _$ChallengeResultCopyWithImpl(this._self, this._then);

  final ChallengeResult _self;
  final $Res Function(ChallengeResult) _then;

/// Create a copy of ChallengeResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? link = null,Object? outcome = null,Object? moves = null,Object? remaining = freezed,Object? matingPiece = freezed,Object? finalFen = null,Object? lastMove = freezed,}) {
  return _then(ChallengeResult(
link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as ChallengeLink,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as AttemptOutcome,moves: null == moves ? _self.moves : moves // ignore: cast_nullable_to_non_nullable
as int,remaining: freezed == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as Duration?,matingPiece: freezed == matingPiece ? _self.matingPiece : matingPiece // ignore: cast_nullable_to_non_nullable
as Role?,finalFen: null == finalFen ? _self.finalFen : finalFen // ignore: cast_nullable_to_non_nullable
as String,lastMove: freezed == lastMove ? _self.lastMove : lastMove // ignore: cast_nullable_to_non_nullable
as Move?,
  ));
}
/// Create a copy of ChallengeResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChallengeLinkCopyWith<$Res> get link {
  
  return $ChallengeLinkCopyWith<$Res>(_self.link, (value) {
    return _then(_self.copyWith(link: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChallengeResult].
extension ChallengeResultPatterns on ChallengeResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChallengeResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChallengeResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChallengeResult value)  $default,){
final _that = this;
switch (_that) {
case _ChallengeResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChallengeResult value)?  $default,){
final _that = this;
switch (_that) {
case _ChallengeResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ChallengeLink link,  AttemptOutcome outcome,  int moves,  Duration? remaining,  Role? matingPiece,  String finalFen,  Move? lastMove)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChallengeResult() when $default != null:
return $default(_that.link,_that.outcome,_that.moves,_that.remaining,_that.matingPiece,_that.finalFen,_that.lastMove);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ChallengeLink link,  AttemptOutcome outcome,  int moves,  Duration? remaining,  Role? matingPiece,  String finalFen,  Move? lastMove)  $default,) {final _that = this;
switch (_that) {
case _ChallengeResult():
return $default(_that.link,_that.outcome,_that.moves,_that.remaining,_that.matingPiece,_that.finalFen,_that.lastMove);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ChallengeLink link,  AttemptOutcome outcome,  int moves,  Duration? remaining,  Role? matingPiece,  String finalFen,  Move? lastMove)?  $default,) {final _that = this;
switch (_that) {
case _ChallengeResult() when $default != null:
return $default(_that.link,_that.outcome,_that.moves,_that.remaining,_that.matingPiece,_that.finalFen,_that.lastMove);case _:
  return null;

}
}

}

/// @nodoc


class _ChallengeResult extends ChallengeResult {
  const _ChallengeResult({required this.link, required this.outcome, required this.moves, this.remaining, this.matingPiece, required this.finalFen, this.lastMove}): super._();
  

/// O desafio jogado: o link que a imagem leva.
@override final  ChallengeLink link;
@override final  AttemptOutcome outcome;
/// Quantos lances o jogador fez.
@override final  int moves;
/// Quanto sobrou no relógio dele. Nulo: partida sem relógio.
@override final  Duration? remaining;
/// A peça que deu o mate. Nulo: o jogador não deu mate.
@override final  Role? matingPiece;
/// A posição final, para o tabuleiro pequeno da imagem.
@override final  String finalFen;
/// O último lance da partida, em destaque na miniatura.
@override final  Move? lastMove;

/// Create a copy of ChallengeResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChallengeResultCopyWith<_ChallengeResult> get copyWith => __$ChallengeResultCopyWithImpl<_ChallengeResult>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChallengeResult&&(identical(other.link, link) || other.link == link)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.moves, moves) || other.moves == moves)&&(identical(other.remaining, remaining) || other.remaining == remaining)&&(identical(other.matingPiece, matingPiece) || other.matingPiece == matingPiece)&&(identical(other.finalFen, finalFen) || other.finalFen == finalFen)&&(identical(other.lastMove, lastMove) || other.lastMove == lastMove));
}


@override
int get hashCode {
    return Object.hash(runtimeType,link,outcome,moves,remaining,matingPiece,finalFen,lastMove);
}

@override
String toString() {
    return 'ChallengeResult(link: $link, outcome: $outcome, moves: $moves, remaining: $remaining, matingPiece: $matingPiece, finalFen: $finalFen, lastMove: $lastMove)';
}


}

/// @nodoc
abstract mixin class _$ChallengeResultCopyWith<$Res> implements $ChallengeResultCopyWith<$Res> {
  factory _$ChallengeResultCopyWith(_ChallengeResult value, $Res Function(_ChallengeResult) _then) = __$ChallengeResultCopyWithImpl;
@override @useResult
$Res call({
 ChallengeLink link, AttemptOutcome outcome, int moves, Duration? remaining, Role? matingPiece, String finalFen, Move? lastMove
});


@override $ChallengeLinkCopyWith<$Res> get link;

}
/// @nodoc
class __$ChallengeResultCopyWithImpl<$Res>
    implements _$ChallengeResultCopyWith<$Res> {
  __$ChallengeResultCopyWithImpl(this._self, this._then);

  final _ChallengeResult _self;
  final $Res Function(_ChallengeResult) _then;

/// Create a copy of ChallengeResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? link = null,Object? outcome = null,Object? moves = null,Object? remaining = freezed,Object? matingPiece = freezed,Object? finalFen = null,Object? lastMove = freezed,}) {
  return _then(_ChallengeResult(
link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as ChallengeLink,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as AttemptOutcome,moves: null == moves ? _self.moves : moves // ignore: cast_nullable_to_non_nullable
as int,remaining: freezed == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as Duration?,matingPiece: freezed == matingPiece ? _self.matingPiece : matingPiece // ignore: cast_nullable_to_non_nullable
as Role?,finalFen: null == finalFen ? _self.finalFen : finalFen // ignore: cast_nullable_to_non_nullable
as String,lastMove: freezed == lastMove ? _self.lastMove : lastMove // ignore: cast_nullable_to_non_nullable
as Move?,
  ));
}

/// Create a copy of ChallengeResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChallengeLinkCopyWith<$Res> get link {
  
  return $ChallengeLinkCopyWith<$Res>(_self.link, (value) {
    return _then(_self.copyWith(link: value));
  });
}
}

// dart format on
