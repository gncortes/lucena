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
 Position get position; PositionGoal get goal;/// A posição do catálogo. Nula na posição personalizada.
 String? get positionId;/// As partidas já jogadas nesta posição, da mais recente para a mais
/// antiga.
 List<Attempt> get attempts;/// O lado do jogador. Começa no lado que joga na posição.
 Side get userSide; GameSetup get setup;/// O nível do Maia mais próximo do rating do jogador.
 int get suggestedLevel;/// O rating do jogador, quando ele já tem partidas que contaram. Nulo: a
/// sugestão vem da faixa do perfil.
 int? get rating;/// Os ritmos nomeados (`1+0`, `3+2`...).
 List<NamedTimeControl> get paces;/// Os personagens, um por nível do Maia.
 List<Character> get characters;/// Falso até a última configuração ser lida.
 bool get ready;
/// Create a copy of GameSetupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameSetupStateCopyWith<GameSetupState> get copyWith => _$GameSetupStateCopyWithImpl<GameSetupState>(this as GameSetupState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GameSetupState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameSetupState&&(identical(other.position, _this.position) || other.position == _this.position)&&(identical(other.goal, _this.goal) || other.goal == _this.goal)&&(identical(other.positionId, _this.positionId) || other.positionId == _this.positionId)&&const DeepCollectionEquality().equals(other.attempts, _this.attempts)&&(identical(other.userSide, _this.userSide) || other.userSide == _this.userSide)&&(identical(other.setup, _this.setup) || other.setup == _this.setup)&&(identical(other.suggestedLevel, _this.suggestedLevel) || other.suggestedLevel == _this.suggestedLevel)&&(identical(other.rating, _this.rating) || other.rating == _this.rating)&&const DeepCollectionEquality().equals(other.paces, _this.paces)&&const DeepCollectionEquality().equals(other.characters, _this.characters)&&(identical(other.ready, _this.ready) || other.ready == _this.ready));
}


@override
int get hashCode {
  final _this = this as GameSetupState;
  return Object.hash(runtimeType,_this.position,_this.goal,_this.positionId,const DeepCollectionEquality().hash(_this.attempts),_this.userSide,_this.setup,_this.suggestedLevel,_this.rating,const DeepCollectionEquality().hash(_this.paces),const DeepCollectionEquality().hash(_this.characters),_this.ready);
}

@override
String toString() {
  final _this = this as GameSetupState;
  return 'GameSetupState(position: ${_this.position}, goal: ${_this.goal}, positionId: ${_this.positionId}, attempts: ${_this.attempts}, userSide: ${_this.userSide}, setup: ${_this.setup}, suggestedLevel: ${_this.suggestedLevel}, rating: ${_this.rating}, paces: ${_this.paces}, characters: ${_this.characters}, ready: ${_this.ready})';
}


}

/// @nodoc
abstract mixin class $GameSetupStateCopyWith<$Res>  {
  factory $GameSetupStateCopyWith(GameSetupState value, $Res Function(GameSetupState) _then) = _$GameSetupStateCopyWithImpl;
@useResult
$Res call({
 Position position, PositionGoal goal, String? positionId, List<Attempt> attempts, Side userSide, GameSetup setup, int suggestedLevel, int? rating, List<NamedTimeControl> paces, List<Character> characters, bool ready
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
@pragma('vm:prefer-inline') @override $Res call({Object? position = null,Object? goal = null,Object? positionId = freezed,Object? attempts = null,Object? userSide = null,Object? setup = null,Object? suggestedLevel = null,Object? rating = freezed,Object? paces = null,Object? characters = null,Object? ready = null,}) {
  return _then(GameSetupState(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Position,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as PositionGoal,positionId: freezed == positionId ? _self.positionId : positionId // ignore: cast_nullable_to_non_nullable
as String?,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as List<Attempt>,userSide: null == userSide ? _self.userSide : userSide // ignore: cast_nullable_to_non_nullable
as Side,setup: null == setup ? _self.setup : setup // ignore: cast_nullable_to_non_nullable
as GameSetup,suggestedLevel: null == suggestedLevel ? _self.suggestedLevel : suggestedLevel // ignore: cast_nullable_to_non_nullable
as int,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int?,paces: null == paces ? _self.paces : paces // ignore: cast_nullable_to_non_nullable
as List<NamedTimeControl>,characters: null == characters ? _self.characters : characters // ignore: cast_nullable_to_non_nullable
as List<Character>,ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Position position,  PositionGoal goal,  String? positionId,  List<Attempt> attempts,  Side userSide,  GameSetup setup,  int suggestedLevel,  int? rating,  List<NamedTimeControl> paces,  List<Character> characters,  bool ready)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameSetupState() when $default != null:
return $default(_that.position,_that.goal,_that.positionId,_that.attempts,_that.userSide,_that.setup,_that.suggestedLevel,_that.rating,_that.paces,_that.characters,_that.ready);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Position position,  PositionGoal goal,  String? positionId,  List<Attempt> attempts,  Side userSide,  GameSetup setup,  int suggestedLevel,  int? rating,  List<NamedTimeControl> paces,  List<Character> characters,  bool ready)  $default,) {final _that = this;
switch (_that) {
case _GameSetupState():
return $default(_that.position,_that.goal,_that.positionId,_that.attempts,_that.userSide,_that.setup,_that.suggestedLevel,_that.rating,_that.paces,_that.characters,_that.ready);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Position position,  PositionGoal goal,  String? positionId,  List<Attempt> attempts,  Side userSide,  GameSetup setup,  int suggestedLevel,  int? rating,  List<NamedTimeControl> paces,  List<Character> characters,  bool ready)?  $default,) {final _that = this;
switch (_that) {
case _GameSetupState() when $default != null:
return $default(_that.position,_that.goal,_that.positionId,_that.attempts,_that.userSide,_that.setup,_that.suggestedLevel,_that.rating,_that.paces,_that.characters,_that.ready);case _:
  return null;

}
}

}

/// @nodoc


class _GameSetupState extends GameSetupState {
  const _GameSetupState({required this.position, required this.goal, this.positionId,  List<Attempt> attempts = const <Attempt>[], required this.userSide, this.setup = const GameSetup(), this.suggestedLevel = MaiaLevels.min, this.rating,  List<NamedTimeControl> paces = const <NamedTimeControl>[],  List<Character> characters = const <Character>[], this.ready = false}): _attempts = attempts,_paces = paces,_characters = characters,super._();
  

/// A posição de início.
@override final  Position position;
@override final  PositionGoal goal;
/// A posição do catálogo. Nula na posição personalizada.
@override final  String? positionId;
/// As partidas já jogadas nesta posição, da mais recente para a mais
/// antiga.
 final  List<Attempt> _attempts;
/// As partidas já jogadas nesta posição, da mais recente para a mais
/// antiga.
@override@JsonKey() List<Attempt> get attempts {
  if (_attempts is EqualUnmodifiableListView) return _attempts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attempts);
}

/// O lado do jogador. Começa no lado que joga na posição.
@override final  Side userSide;
@override@JsonKey() final  GameSetup setup;
/// O nível do Maia mais próximo do rating do jogador.
@override@JsonKey() final  int suggestedLevel;
/// O rating do jogador, quando ele já tem partidas que contaram. Nulo: a
/// sugestão vem da faixa do perfil.
@override final  int? rating;
/// Os ritmos nomeados (`1+0`, `3+2`...).
 final  List<NamedTimeControl> _paces;
/// Os ritmos nomeados (`1+0`, `3+2`...).
@override@JsonKey() List<NamedTimeControl> get paces {
  if (_paces is EqualUnmodifiableListView) return _paces;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_paces);
}

/// Os personagens, um por nível do Maia.
 final  List<Character> _characters;
/// Os personagens, um por nível do Maia.
@override@JsonKey() List<Character> get characters {
  if (_characters is EqualUnmodifiableListView) return _characters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_characters);
}

/// Falso até a última configuração ser lida.
@override@JsonKey() final  bool ready;

/// Create a copy of GameSetupState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameSetupStateCopyWith<_GameSetupState> get copyWith => __$GameSetupStateCopyWithImpl<_GameSetupState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameSetupState&&(identical(other.position, position) || other.position == position)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.positionId, positionId) || other.positionId == positionId)&&const DeepCollectionEquality().equals(other.attempts, _attempts)&&(identical(other.userSide, userSide) || other.userSide == userSide)&&(identical(other.setup, setup) || other.setup == setup)&&(identical(other.suggestedLevel, suggestedLevel) || other.suggestedLevel == suggestedLevel)&&(identical(other.rating, rating) || other.rating == rating)&&const DeepCollectionEquality().equals(other.paces, _paces)&&const DeepCollectionEquality().equals(other.characters, _characters)&&(identical(other.ready, ready) || other.ready == ready));
}


@override
int get hashCode {
    return Object.hash(runtimeType,position,goal,positionId,const DeepCollectionEquality().hash(_attempts),userSide,setup,suggestedLevel,rating,const DeepCollectionEquality().hash(_paces),const DeepCollectionEquality().hash(_characters),ready);
}

@override
String toString() {
    return 'GameSetupState(position: $position, goal: $goal, positionId: $positionId, attempts: $attempts, userSide: $userSide, setup: $setup, suggestedLevel: $suggestedLevel, rating: $rating, paces: $paces, characters: $characters, ready: $ready)';
}


}

/// @nodoc
abstract mixin class _$GameSetupStateCopyWith<$Res> implements $GameSetupStateCopyWith<$Res> {
  factory _$GameSetupStateCopyWith(_GameSetupState value, $Res Function(_GameSetupState) _then) = __$GameSetupStateCopyWithImpl;
@override @useResult
$Res call({
 Position position, PositionGoal goal, String? positionId, List<Attempt> attempts, Side userSide, GameSetup setup, int suggestedLevel, int? rating, List<NamedTimeControl> paces, List<Character> characters, bool ready
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
@override @pragma('vm:prefer-inline') $Res call({Object? position = null,Object? goal = null,Object? positionId = freezed,Object? attempts = null,Object? userSide = null,Object? setup = null,Object? suggestedLevel = null,Object? rating = freezed,Object? paces = null,Object? characters = null,Object? ready = null,}) {
  return _then(_GameSetupState(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Position,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as PositionGoal,positionId: freezed == positionId ? _self.positionId : positionId // ignore: cast_nullable_to_non_nullable
as String?,attempts: null == attempts ? _self._attempts : attempts // ignore: cast_nullable_to_non_nullable
as List<Attempt>,userSide: null == userSide ? _self.userSide : userSide // ignore: cast_nullable_to_non_nullable
as Side,setup: null == setup ? _self.setup : setup // ignore: cast_nullable_to_non_nullable
as GameSetup,suggestedLevel: null == suggestedLevel ? _self.suggestedLevel : suggestedLevel // ignore: cast_nullable_to_non_nullable
as int,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int?,paces: null == paces ? _self._paces : paces // ignore: cast_nullable_to_non_nullable
as List<NamedTimeControl>,characters: null == characters ? _self._characters : characters // ignore: cast_nullable_to_non_nullable
as List<Character>,ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
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
