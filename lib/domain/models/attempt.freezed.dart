// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attempt.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Attempt {

 String get positionId; DateTime get playedAt; AttemptOutcome get outcome;/// O objetivo da posição foi cumprido.
 bool get fulfilled; OpponentKind get opponent;
/// Create a copy of Attempt
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttemptCopyWith<Attempt> get copyWith => _$AttemptCopyWithImpl<Attempt>(this as Attempt, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Attempt;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Attempt&&(identical(other.positionId, _this.positionId) || other.positionId == _this.positionId)&&(identical(other.playedAt, _this.playedAt) || other.playedAt == _this.playedAt)&&(identical(other.outcome, _this.outcome) || other.outcome == _this.outcome)&&(identical(other.fulfilled, _this.fulfilled) || other.fulfilled == _this.fulfilled)&&(identical(other.opponent, _this.opponent) || other.opponent == _this.opponent));
}


@override
int get hashCode {
  final _this = this as Attempt;
  return Object.hash(runtimeType,_this.positionId,_this.playedAt,_this.outcome,_this.fulfilled,_this.opponent);
}

@override
String toString() {
  final _this = this as Attempt;
  return 'Attempt(positionId: ${_this.positionId}, playedAt: ${_this.playedAt}, outcome: ${_this.outcome}, fulfilled: ${_this.fulfilled}, opponent: ${_this.opponent})';
}


}

/// @nodoc
abstract mixin class $AttemptCopyWith<$Res>  {
  factory $AttemptCopyWith(Attempt value, $Res Function(Attempt) _then) = _$AttemptCopyWithImpl;
@useResult
$Res call({
 String positionId, DateTime playedAt, AttemptOutcome outcome, bool fulfilled, OpponentKind opponent
});




}
/// @nodoc
class _$AttemptCopyWithImpl<$Res>
    implements $AttemptCopyWith<$Res> {
  _$AttemptCopyWithImpl(this._self, this._then);

  final Attempt _self;
  final $Res Function(Attempt) _then;

/// Create a copy of Attempt
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? positionId = null,Object? playedAt = null,Object? outcome = null,Object? fulfilled = null,Object? opponent = null,}) {
  return _then(Attempt(
positionId: null == positionId ? _self.positionId : positionId // ignore: cast_nullable_to_non_nullable
as String,playedAt: null == playedAt ? _self.playedAt : playedAt // ignore: cast_nullable_to_non_nullable
as DateTime,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as AttemptOutcome,fulfilled: null == fulfilled ? _self.fulfilled : fulfilled // ignore: cast_nullable_to_non_nullable
as bool,opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as OpponentKind,
  ));
}

}


/// Adds pattern-matching-related methods to [Attempt].
extension AttemptPatterns on Attempt {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Attempt value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Attempt() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Attempt value)  $default,){
final _that = this;
switch (_that) {
case _Attempt():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Attempt value)?  $default,){
final _that = this;
switch (_that) {
case _Attempt() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String positionId,  DateTime playedAt,  AttemptOutcome outcome,  bool fulfilled,  OpponentKind opponent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Attempt() when $default != null:
return $default(_that.positionId,_that.playedAt,_that.outcome,_that.fulfilled,_that.opponent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String positionId,  DateTime playedAt,  AttemptOutcome outcome,  bool fulfilled,  OpponentKind opponent)  $default,) {final _that = this;
switch (_that) {
case _Attempt():
return $default(_that.positionId,_that.playedAt,_that.outcome,_that.fulfilled,_that.opponent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String positionId,  DateTime playedAt,  AttemptOutcome outcome,  bool fulfilled,  OpponentKind opponent)?  $default,) {final _that = this;
switch (_that) {
case _Attempt() when $default != null:
return $default(_that.positionId,_that.playedAt,_that.outcome,_that.fulfilled,_that.opponent);case _:
  return null;

}
}

}

/// @nodoc


class _Attempt implements Attempt {
  const _Attempt({required this.positionId, required this.playedAt, required this.outcome, required this.fulfilled, required this.opponent});
  

@override final  String positionId;
@override final  DateTime playedAt;
@override final  AttemptOutcome outcome;
/// O objetivo da posição foi cumprido.
@override final  bool fulfilled;
@override final  OpponentKind opponent;

/// Create a copy of Attempt
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttemptCopyWith<_Attempt> get copyWith => __$AttemptCopyWithImpl<_Attempt>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Attempt&&(identical(other.positionId, positionId) || other.positionId == positionId)&&(identical(other.playedAt, playedAt) || other.playedAt == playedAt)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.fulfilled, fulfilled) || other.fulfilled == fulfilled)&&(identical(other.opponent, opponent) || other.opponent == opponent));
}


@override
int get hashCode {
    return Object.hash(runtimeType,positionId,playedAt,outcome,fulfilled,opponent);
}

@override
String toString() {
    return 'Attempt(positionId: $positionId, playedAt: $playedAt, outcome: $outcome, fulfilled: $fulfilled, opponent: $opponent)';
}


}

/// @nodoc
abstract mixin class _$AttemptCopyWith<$Res> implements $AttemptCopyWith<$Res> {
  factory _$AttemptCopyWith(_Attempt value, $Res Function(_Attempt) _then) = __$AttemptCopyWithImpl;
@override @useResult
$Res call({
 String positionId, DateTime playedAt, AttemptOutcome outcome, bool fulfilled, OpponentKind opponent
});




}
/// @nodoc
class __$AttemptCopyWithImpl<$Res>
    implements _$AttemptCopyWith<$Res> {
  __$AttemptCopyWithImpl(this._self, this._then);

  final _Attempt _self;
  final $Res Function(_Attempt) _then;

/// Create a copy of Attempt
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? positionId = null,Object? playedAt = null,Object? outcome = null,Object? fulfilled = null,Object? opponent = null,}) {
  return _then(_Attempt(
positionId: null == positionId ? _self.positionId : positionId // ignore: cast_nullable_to_non_nullable
as String,playedAt: null == playedAt ? _self.playedAt : playedAt // ignore: cast_nullable_to_non_nullable
as DateTime,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as AttemptOutcome,fulfilled: null == fulfilled ? _self.fulfilled : fulfilled // ignore: cast_nullable_to_non_nullable
as bool,opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as OpponentKind,
  ));
}


}

// dart format on
