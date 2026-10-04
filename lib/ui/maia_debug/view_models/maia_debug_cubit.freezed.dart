// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'maia_debug_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MaiaDebugState {

 String get fen; int get level; MaiaDebugStatus get status;/// A última previsão, da posição e do nível em que foi pedida.
 MovePrediction? get prediction;
/// Create a copy of MaiaDebugState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MaiaDebugStateCopyWith<MaiaDebugState> get copyWith => _$MaiaDebugStateCopyWithImpl<MaiaDebugState>(this as MaiaDebugState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MaiaDebugState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MaiaDebugState&&(identical(other.fen, _this.fen) || other.fen == _this.fen)&&(identical(other.level, _this.level) || other.level == _this.level)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.prediction, _this.prediction) || other.prediction == _this.prediction));
}


@override
int get hashCode {
  final _this = this as MaiaDebugState;
  return Object.hash(runtimeType,_this.fen,_this.level,_this.status,_this.prediction);
}

@override
String toString() {
  final _this = this as MaiaDebugState;
  return 'MaiaDebugState(fen: ${_this.fen}, level: ${_this.level}, status: ${_this.status}, prediction: ${_this.prediction})';
}


}

/// @nodoc
abstract mixin class $MaiaDebugStateCopyWith<$Res>  {
  factory $MaiaDebugStateCopyWith(MaiaDebugState value, $Res Function(MaiaDebugState) _then) = _$MaiaDebugStateCopyWithImpl;
@useResult
$Res call({
 String fen, int level, MaiaDebugStatus status, MovePrediction? prediction
});




}
/// @nodoc
class _$MaiaDebugStateCopyWithImpl<$Res>
    implements $MaiaDebugStateCopyWith<$Res> {
  _$MaiaDebugStateCopyWithImpl(this._self, this._then);

  final MaiaDebugState _self;
  final $Res Function(MaiaDebugState) _then;

/// Create a copy of MaiaDebugState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fen = null,Object? level = null,Object? status = null,Object? prediction = freezed,}) {
  return _then(MaiaDebugState(
fen: null == fen ? _self.fen : fen // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MaiaDebugStatus,prediction: freezed == prediction ? _self.prediction : prediction // ignore: cast_nullable_to_non_nullable
as MovePrediction?,
  ));
}

}


/// Adds pattern-matching-related methods to [MaiaDebugState].
extension MaiaDebugStatePatterns on MaiaDebugState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MaiaDebugState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MaiaDebugState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MaiaDebugState value)  $default,){
final _that = this;
switch (_that) {
case _MaiaDebugState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MaiaDebugState value)?  $default,){
final _that = this;
switch (_that) {
case _MaiaDebugState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fen,  int level,  MaiaDebugStatus status,  MovePrediction? prediction)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MaiaDebugState() when $default != null:
return $default(_that.fen,_that.level,_that.status,_that.prediction);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fen,  int level,  MaiaDebugStatus status,  MovePrediction? prediction)  $default,) {final _that = this;
switch (_that) {
case _MaiaDebugState():
return $default(_that.fen,_that.level,_that.status,_that.prediction);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fen,  int level,  MaiaDebugStatus status,  MovePrediction? prediction)?  $default,) {final _that = this;
switch (_that) {
case _MaiaDebugState() when $default != null:
return $default(_that.fen,_that.level,_that.status,_that.prediction);case _:
  return null;

}
}

}

/// @nodoc


class _MaiaDebugState implements MaiaDebugState {
  const _MaiaDebugState({this.fen = MaiaDebugState.defaultFen, this.level = 1400, this.status = MaiaDebugStatus.idle, this.prediction});
  

@override@JsonKey() final  String fen;
@override@JsonKey() final  int level;
@override@JsonKey() final  MaiaDebugStatus status;
/// A última previsão, da posição e do nível em que foi pedida.
@override final  MovePrediction? prediction;

/// Create a copy of MaiaDebugState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MaiaDebugStateCopyWith<_MaiaDebugState> get copyWith => __$MaiaDebugStateCopyWithImpl<_MaiaDebugState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MaiaDebugState&&(identical(other.fen, fen) || other.fen == fen)&&(identical(other.level, level) || other.level == level)&&(identical(other.status, status) || other.status == status)&&(identical(other.prediction, prediction) || other.prediction == prediction));
}


@override
int get hashCode {
    return Object.hash(runtimeType,fen,level,status,prediction);
}

@override
String toString() {
    return 'MaiaDebugState(fen: $fen, level: $level, status: $status, prediction: $prediction)';
}


}

/// @nodoc
abstract mixin class _$MaiaDebugStateCopyWith<$Res> implements $MaiaDebugStateCopyWith<$Res> {
  factory _$MaiaDebugStateCopyWith(_MaiaDebugState value, $Res Function(_MaiaDebugState) _then) = __$MaiaDebugStateCopyWithImpl;
@override @useResult
$Res call({
 String fen, int level, MaiaDebugStatus status, MovePrediction? prediction
});




}
/// @nodoc
class __$MaiaDebugStateCopyWithImpl<$Res>
    implements _$MaiaDebugStateCopyWith<$Res> {
  __$MaiaDebugStateCopyWithImpl(this._self, this._then);

  final _MaiaDebugState _self;
  final $Res Function(_MaiaDebugState) _then;

/// Create a copy of MaiaDebugState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fen = null,Object? level = null,Object? status = null,Object? prediction = freezed,}) {
  return _then(_MaiaDebugState(
fen: null == fen ? _self.fen : fen // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MaiaDebugStatus,prediction: freezed == prediction ? _self.prediction : prediction // ignore: cast_nullable_to_non_nullable
as MovePrediction?,
  ));
}


}

// dart format on
