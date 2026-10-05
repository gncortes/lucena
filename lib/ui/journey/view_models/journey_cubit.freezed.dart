// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'journey_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$JourneyState {

/// Nulo enquanto a Jornada é lida.
 JourneyProgress? get progress;/// O desafio aberto e as partidas dele, da mais recente para a mais
/// antiga. Nulo fora da tela do desafio.
 Challenge? get challenge; List<Attempt> get attempts;/// Os personagens, um por nível do Maia.
 List<Character> get characters;
/// Create a copy of JourneyState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JourneyStateCopyWith<JourneyState> get copyWith => _$JourneyStateCopyWithImpl<JourneyState>(this as JourneyState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as JourneyState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JourneyState&&(identical(other.progress, _this.progress) || other.progress == _this.progress)&&(identical(other.challenge, _this.challenge) || other.challenge == _this.challenge)&&const DeepCollectionEquality().equals(other.attempts, _this.attempts)&&const DeepCollectionEquality().equals(other.characters, _this.characters));
}


@override
int get hashCode {
  final _this = this as JourneyState;
  return Object.hash(runtimeType,_this.progress,_this.challenge,const DeepCollectionEquality().hash(_this.attempts),const DeepCollectionEquality().hash(_this.characters));
}

@override
String toString() {
  final _this = this as JourneyState;
  return 'JourneyState(progress: ${_this.progress}, challenge: ${_this.challenge}, attempts: ${_this.attempts}, characters: ${_this.characters})';
}


}

/// @nodoc
abstract mixin class $JourneyStateCopyWith<$Res>  {
  factory $JourneyStateCopyWith(JourneyState value, $Res Function(JourneyState) _then) = _$JourneyStateCopyWithImpl;
@useResult
$Res call({
 JourneyProgress? progress, Challenge? challenge, List<Attempt> attempts, List<Character> characters
});


$JourneyProgressCopyWith<$Res>? get progress;$ChallengeCopyWith<$Res>? get challenge;

}
/// @nodoc
class _$JourneyStateCopyWithImpl<$Res>
    implements $JourneyStateCopyWith<$Res> {
  _$JourneyStateCopyWithImpl(this._self, this._then);

  final JourneyState _self;
  final $Res Function(JourneyState) _then;

/// Create a copy of JourneyState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? progress = freezed,Object? challenge = freezed,Object? attempts = null,Object? characters = null,}) {
  return _then(JourneyState(
progress: freezed == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as JourneyProgress?,challenge: freezed == challenge ? _self.challenge : challenge // ignore: cast_nullable_to_non_nullable
as Challenge?,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as List<Attempt>,characters: null == characters ? _self.characters : characters // ignore: cast_nullable_to_non_nullable
as List<Character>,
  ));
}
/// Create a copy of JourneyState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JourneyProgressCopyWith<$Res>? get progress {
    if (_self.progress == null) {
    return null;
  }

  return $JourneyProgressCopyWith<$Res>(_self.progress!, (value) {
    return _then(_self.copyWith(progress: value));
  });
}/// Create a copy of JourneyState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChallengeCopyWith<$Res>? get challenge {
    if (_self.challenge == null) {
    return null;
  }

  return $ChallengeCopyWith<$Res>(_self.challenge!, (value) {
    return _then(_self.copyWith(challenge: value));
  });
}
}


/// Adds pattern-matching-related methods to [JourneyState].
extension JourneyStatePatterns on JourneyState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JourneyState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JourneyState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JourneyState value)  $default,){
final _that = this;
switch (_that) {
case _JourneyState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JourneyState value)?  $default,){
final _that = this;
switch (_that) {
case _JourneyState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( JourneyProgress? progress,  Challenge? challenge,  List<Attempt> attempts,  List<Character> characters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JourneyState() when $default != null:
return $default(_that.progress,_that.challenge,_that.attempts,_that.characters);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( JourneyProgress? progress,  Challenge? challenge,  List<Attempt> attempts,  List<Character> characters)  $default,) {final _that = this;
switch (_that) {
case _JourneyState():
return $default(_that.progress,_that.challenge,_that.attempts,_that.characters);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( JourneyProgress? progress,  Challenge? challenge,  List<Attempt> attempts,  List<Character> characters)?  $default,) {final _that = this;
switch (_that) {
case _JourneyState() when $default != null:
return $default(_that.progress,_that.challenge,_that.attempts,_that.characters);case _:
  return null;

}
}

}

/// @nodoc


class _JourneyState implements JourneyState {
  const _JourneyState({this.progress, this.challenge,  List<Attempt> attempts = const <Attempt>[],  List<Character> characters = const <Character>[]}): _attempts = attempts,_characters = characters;
  

/// Nulo enquanto a Jornada é lida.
@override final  JourneyProgress? progress;
/// O desafio aberto e as partidas dele, da mais recente para a mais
/// antiga. Nulo fora da tela do desafio.
@override final  Challenge? challenge;
 final  List<Attempt> _attempts;
@override@JsonKey() List<Attempt> get attempts {
  if (_attempts is EqualUnmodifiableListView) return _attempts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attempts);
}

/// Os personagens, um por nível do Maia.
 final  List<Character> _characters;
/// Os personagens, um por nível do Maia.
@override@JsonKey() List<Character> get characters {
  if (_characters is EqualUnmodifiableListView) return _characters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_characters);
}


/// Create a copy of JourneyState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JourneyStateCopyWith<_JourneyState> get copyWith => __$JourneyStateCopyWithImpl<_JourneyState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _JourneyState&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.challenge, challenge) || other.challenge == challenge)&&const DeepCollectionEquality().equals(other.attempts, _attempts)&&const DeepCollectionEquality().equals(other.characters, _characters));
}


@override
int get hashCode {
    return Object.hash(runtimeType,progress,challenge,const DeepCollectionEquality().hash(_attempts),const DeepCollectionEquality().hash(_characters));
}

@override
String toString() {
    return 'JourneyState(progress: $progress, challenge: $challenge, attempts: $attempts, characters: $characters)';
}


}

/// @nodoc
abstract mixin class _$JourneyStateCopyWith<$Res> implements $JourneyStateCopyWith<$Res> {
  factory _$JourneyStateCopyWith(_JourneyState value, $Res Function(_JourneyState) _then) = __$JourneyStateCopyWithImpl;
@override @useResult
$Res call({
 JourneyProgress? progress, Challenge? challenge, List<Attempt> attempts, List<Character> characters
});


@override $JourneyProgressCopyWith<$Res>? get progress;@override $ChallengeCopyWith<$Res>? get challenge;

}
/// @nodoc
class __$JourneyStateCopyWithImpl<$Res>
    implements _$JourneyStateCopyWith<$Res> {
  __$JourneyStateCopyWithImpl(this._self, this._then);

  final _JourneyState _self;
  final $Res Function(_JourneyState) _then;

/// Create a copy of JourneyState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? progress = freezed,Object? challenge = freezed,Object? attempts = null,Object? characters = null,}) {
  return _then(_JourneyState(
progress: freezed == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as JourneyProgress?,challenge: freezed == challenge ? _self.challenge : challenge // ignore: cast_nullable_to_non_nullable
as Challenge?,attempts: null == attempts ? _self._attempts : attempts // ignore: cast_nullable_to_non_nullable
as List<Attempt>,characters: null == characters ? _self._characters : characters // ignore: cast_nullable_to_non_nullable
as List<Character>,
  ));
}

/// Create a copy of JourneyState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JourneyProgressCopyWith<$Res>? get progress {
    if (_self.progress == null) {
    return null;
  }

  return $JourneyProgressCopyWith<$Res>(_self.progress!, (value) {
    return _then(_self.copyWith(progress: value));
  });
}/// Create a copy of JourneyState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChallengeCopyWith<$Res>? get challenge {
    if (_self.challenge == null) {
    return null;
  }

  return $ChallengeCopyWith<$Res>(_self.challenge!, (value) {
    return _then(_self.copyWith(challenge: value));
  });
}
}

// dart format on
