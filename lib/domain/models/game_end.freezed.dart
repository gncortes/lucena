// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_end.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GameEnd {

 GameEndReason get reason; Side? get winner;
/// Create a copy of GameEnd
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameEndCopyWith<GameEnd> get copyWith => _$GameEndCopyWithImpl<GameEnd>(this as GameEnd, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GameEnd;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameEnd&&(identical(other.reason, _this.reason) || other.reason == _this.reason)&&(identical(other.winner, _this.winner) || other.winner == _this.winner));
}


@override
int get hashCode {
  final _this = this as GameEnd;
  return Object.hash(runtimeType,_this.reason,_this.winner);
}

@override
String toString() {
  final _this = this as GameEnd;
  return 'GameEnd(reason: ${_this.reason}, winner: ${_this.winner})';
}


}

/// @nodoc
abstract mixin class $GameEndCopyWith<$Res>  {
  factory $GameEndCopyWith(GameEnd value, $Res Function(GameEnd) _then) = _$GameEndCopyWithImpl;
@useResult
$Res call({
 GameEndReason reason, Side? winner
});




}
/// @nodoc
class _$GameEndCopyWithImpl<$Res>
    implements $GameEndCopyWith<$Res> {
  _$GameEndCopyWithImpl(this._self, this._then);

  final GameEnd _self;
  final $Res Function(GameEnd) _then;

/// Create a copy of GameEnd
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reason = null,Object? winner = freezed,}) {
  return _then(GameEnd(
null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as GameEndReason,winner: freezed == winner ? _self.winner : winner // ignore: cast_nullable_to_non_nullable
as Side?,
  ));
}

}


/// Adds pattern-matching-related methods to [GameEnd].
extension GameEndPatterns on GameEnd {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameEnd value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameEnd() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameEnd value)  $default,){
final _that = this;
switch (_that) {
case _GameEnd():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameEnd value)?  $default,){
final _that = this;
switch (_that) {
case _GameEnd() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GameEndReason reason,  Side? winner)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameEnd() when $default != null:
return $default(_that.reason,_that.winner);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GameEndReason reason,  Side? winner)  $default,) {final _that = this;
switch (_that) {
case _GameEnd():
return $default(_that.reason,_that.winner);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GameEndReason reason,  Side? winner)?  $default,) {final _that = this;
switch (_that) {
case _GameEnd() when $default != null:
return $default(_that.reason,_that.winner);case _:
  return null;

}
}

}

/// @nodoc


class _GameEnd implements GameEnd {
  const _GameEnd(this.reason, {this.winner});
  

@override final  GameEndReason reason;
@override final  Side? winner;

/// Create a copy of GameEnd
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameEndCopyWith<_GameEnd> get copyWith => __$GameEndCopyWithImpl<_GameEnd>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameEnd&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.winner, winner) || other.winner == winner));
}


@override
int get hashCode {
    return Object.hash(runtimeType,reason,winner);
}

@override
String toString() {
    return 'GameEnd(reason: $reason, winner: $winner)';
}


}

/// @nodoc
abstract mixin class _$GameEndCopyWith<$Res> implements $GameEndCopyWith<$Res> {
  factory _$GameEndCopyWith(_GameEnd value, $Res Function(_GameEnd) _then) = __$GameEndCopyWithImpl;
@override @useResult
$Res call({
 GameEndReason reason, Side? winner
});




}
/// @nodoc
class __$GameEndCopyWithImpl<$Res>
    implements _$GameEndCopyWith<$Res> {
  __$GameEndCopyWithImpl(this._self, this._then);

  final _GameEnd _self;
  final $Res Function(_GameEnd) _then;

/// Create a copy of GameEnd
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reason = null,Object? winner = freezed,}) {
  return _then(_GameEnd(
null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as GameEndReason,winner: freezed == winner ? _self.winner : winner // ignore: cast_nullable_to_non_nullable
as Side?,
  ));
}


}

// dart format on
