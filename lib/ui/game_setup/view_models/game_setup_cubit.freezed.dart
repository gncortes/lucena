// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_setup_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GameSetupState {

/// A posição de início.
 Position get position; PositionGoal get goal;/// O lado do jogador. Começa no lado que joga na posição.
 Side get userSide; GameSetup get setup;/// Falso até a última configuração ser lida.
 bool get ready;
/// Create a copy of GameSetupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameSetupStateCopyWith<GameSetupState> get copyWith => _$GameSetupStateCopyWithImpl<GameSetupState>(this as GameSetupState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GameSetupState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameSetupState&&(identical(other.position, _this.position) || other.position == _this.position)&&(identical(other.goal, _this.goal) || other.goal == _this.goal)&&(identical(other.userSide, _this.userSide) || other.userSide == _this.userSide)&&(identical(other.setup, _this.setup) || other.setup == _this.setup)&&(identical(other.ready, _this.ready) || other.ready == _this.ready));
}


@override
int get hashCode {
  final _this = this as GameSetupState;
  return Object.hash(runtimeType,_this.position,_this.goal,_this.userSide,_this.setup,_this.ready);
}

@override
String toString() {
  final _this = this as GameSetupState;
  return 'GameSetupState(position: ${_this.position}, goal: ${_this.goal}, userSide: ${_this.userSide}, setup: ${_this.setup}, ready: ${_this.ready})';
}


}

/// @nodoc
abstract mixin class $GameSetupStateCopyWith<$Res>  {
  factory $GameSetupStateCopyWith(GameSetupState value, $Res Function(GameSetupState) _then) = _$GameSetupStateCopyWithImpl;
@useResult
$Res call({
 Position position, PositionGoal goal, Side userSide, GameSetup setup, bool ready
});


$GameSetupCopyWith<$Res> get setup;

}
/// @nodoc
class _$GameSetupStateCopyWithImpl<$Res>
    implements $GameSetupStateCopyWith<$Res> {
  _$GameSetupStateCopyWithImpl(this._self, this._then);

  final GameSetupState _self;
  final $Res Function(GameSetupState) _then;

/// Create a copy of GameSetupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? position = null,Object? goal = null,Object? userSide = null,Object? setup = null,Object? ready = null,}) {
  return _then(GameSetupState(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Position,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as PositionGoal,userSide: null == userSide ? _self.userSide : userSide // ignore: cast_nullable_to_non_nullable
as Side,setup: null == setup ? _self.setup : setup // ignore: cast_nullable_to_non_nullable
as GameSetup,ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of GameSetupState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameSetupCopyWith<$Res> get setup {
  
  return $GameSetupCopyWith<$Res>(_self.setup, (value) {
    return _then(_self.copyWith(setup: value));
  });
}
}


/// Adds pattern-matching-related methods to [GameSetupState].
extension GameSetupStatePatterns on GameSetupState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameSetupState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameSetupState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameSetupState value)  $default,){
final _that = this;
switch (_that) {
case _GameSetupState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameSetupState value)?  $default,){
final _that = this;
switch (_that) {
case _GameSetupState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Position position,  PositionGoal goal,  Side userSide,  GameSetup setup,  bool ready)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameSetupState() when $default != null:
return $default(_that.position,_that.goal,_that.userSide,_that.setup,_that.ready);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Position position,  PositionGoal goal,  Side userSide,  GameSetup setup,  bool ready)  $default,) {final _that = this;
switch (_that) {
case _GameSetupState():
return $default(_that.position,_that.goal,_that.userSide,_that.setup,_that.ready);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Position position,  PositionGoal goal,  Side userSide,  GameSetup setup,  bool ready)?  $default,) {final _that = this;
switch (_that) {
case _GameSetupState() when $default != null:
return $default(_that.position,_that.goal,_that.userSide,_that.setup,_that.ready);case _:
  return null;

}
}

}

/// @nodoc


class _GameSetupState extends GameSetupState {
  const _GameSetupState({required this.position, required this.goal, required this.userSide, this.setup = const GameSetup(), this.ready = false}): super._();
  

/// A posição de início.
@override final  Position position;
@override final  PositionGoal goal;
/// O lado do jogador. Começa no lado que joga na posição.
@override final  Side userSide;
@override@JsonKey() final  GameSetup setup;
/// Falso até a última configuração ser lida.
@override@JsonKey() final  bool ready;

/// Create a copy of GameSetupState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameSetupStateCopyWith<_GameSetupState> get copyWith => __$GameSetupStateCopyWithImpl<_GameSetupState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameSetupState&&(identical(other.position, position) || other.position == position)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.userSide, userSide) || other.userSide == userSide)&&(identical(other.setup, setup) || other.setup == setup)&&(identical(other.ready, ready) || other.ready == ready));
}


@override
int get hashCode {
    return Object.hash(runtimeType,position,goal,userSide,setup,ready);
}

@override
String toString() {
    return 'GameSetupState(position: $position, goal: $goal, userSide: $userSide, setup: $setup, ready: $ready)';
}


}

/// @nodoc
abstract mixin class _$GameSetupStateCopyWith<$Res> implements $GameSetupStateCopyWith<$Res> {
  factory _$GameSetupStateCopyWith(_GameSetupState value, $Res Function(_GameSetupState) _then) = __$GameSetupStateCopyWithImpl;
@override @useResult
$Res call({
 Position position, PositionGoal goal, Side userSide, GameSetup setup, bool ready
});


@override $GameSetupCopyWith<$Res> get setup;

}
/// @nodoc
class __$GameSetupStateCopyWithImpl<$Res>
    implements _$GameSetupStateCopyWith<$Res> {
  __$GameSetupStateCopyWithImpl(this._self, this._then);

  final _GameSetupState _self;
  final $Res Function(_GameSetupState) _then;

/// Create a copy of GameSetupState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? position = null,Object? goal = null,Object? userSide = null,Object? setup = null,Object? ready = null,}) {
  return _then(_GameSetupState(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Position,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as PositionGoal,userSide: null == userSide ? _self.userSide : userSide // ignore: cast_nullable_to_non_nullable
as Side,setup: null == setup ? _self.setup : setup // ignore: cast_nullable_to_non_nullable
as GameSetup,ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of GameSetupState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameSetupCopyWith<$Res> get setup {
  
  return $GameSetupCopyWith<$Res>(_self.setup, (value) {
    return _then(_self.copyWith(setup: value));
  });
}
}

// dart format on
