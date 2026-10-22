// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'challenge_link_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChallengeLinkState {

 ChallengeLink get link;/// O nível do Maia que vale: o do link ou, sem ele, o do rating de quem
/// abriu.
 int get level; List<Character> get characters; bool get ready;
/// Create a copy of ChallengeLinkState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChallengeLinkStateCopyWith<ChallengeLinkState> get copyWith => _$ChallengeLinkStateCopyWithImpl<ChallengeLinkState>(this as ChallengeLinkState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ChallengeLinkState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChallengeLinkState&&(identical(other.link, _this.link) || other.link == _this.link)&&(identical(other.level, _this.level) || other.level == _this.level)&&const DeepCollectionEquality().equals(other.characters, _this.characters)&&(identical(other.ready, _this.ready) || other.ready == _this.ready));
}


@override
int get hashCode {
  final _this = this as ChallengeLinkState;
  return Object.hash(runtimeType,_this.link,_this.level,const DeepCollectionEquality().hash(_this.characters),_this.ready);
}

@override
String toString() {
  final _this = this as ChallengeLinkState;
  return 'ChallengeLinkState(link: ${_this.link}, level: ${_this.level}, characters: ${_this.characters}, ready: ${_this.ready})';
}


}

/// @nodoc
abstract mixin class $ChallengeLinkStateCopyWith<$Res>  {
  factory $ChallengeLinkStateCopyWith(ChallengeLinkState value, $Res Function(ChallengeLinkState) _then) = _$ChallengeLinkStateCopyWithImpl;
@useResult
$Res call({
 ChallengeLink link, int level, List<Character> characters, bool ready
});


$ChallengeLinkCopyWith<$Res> get link;

}
/// @nodoc
class _$ChallengeLinkStateCopyWithImpl<$Res>
    implements $ChallengeLinkStateCopyWith<$Res> {
  _$ChallengeLinkStateCopyWithImpl(this._self, this._then);

  final ChallengeLinkState _self;
  final $Res Function(ChallengeLinkState) _then;

/// Create a copy of ChallengeLinkState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? link = null,Object? level = null,Object? characters = null,Object? ready = null,}) {
  return _then(ChallengeLinkState(
link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as ChallengeLink,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,characters: null == characters ? _self.characters : characters // ignore: cast_nullable_to_non_nullable
as List<Character>,ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ChallengeLinkState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChallengeLinkCopyWith<$Res> get link {
  
  return $ChallengeLinkCopyWith<$Res>(_self.link, (value) {
    return _then(_self.copyWith(link: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChallengeLinkState].
extension ChallengeLinkStatePatterns on ChallengeLinkState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChallengeLinkState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChallengeLinkState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChallengeLinkState value)  $default,){
final _that = this;
switch (_that) {
case _ChallengeLinkState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChallengeLinkState value)?  $default,){
final _that = this;
switch (_that) {
case _ChallengeLinkState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ChallengeLink link,  int level,  List<Character> characters,  bool ready)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChallengeLinkState() when $default != null:
return $default(_that.link,_that.level,_that.characters,_that.ready);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ChallengeLink link,  int level,  List<Character> characters,  bool ready)  $default,) {final _that = this;
switch (_that) {
case _ChallengeLinkState():
return $default(_that.link,_that.level,_that.characters,_that.ready);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ChallengeLink link,  int level,  List<Character> characters,  bool ready)?  $default,) {final _that = this;
switch (_that) {
case _ChallengeLinkState() when $default != null:
return $default(_that.link,_that.level,_that.characters,_that.ready);case _:
  return null;

}
}

}

/// @nodoc


class _ChallengeLinkState extends ChallengeLinkState {
  const _ChallengeLinkState({required this.link, required this.level,  List<Character> characters = const <Character>[], this.ready = false}): _characters = characters,super._();
  

@override final  ChallengeLink link;
/// O nível do Maia que vale: o do link ou, sem ele, o do rating de quem
/// abriu.
@override final  int level;
 final  List<Character> _characters;
@override@JsonKey() List<Character> get characters {
  if (_characters is EqualUnmodifiableListView) return _characters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_characters);
}

@override@JsonKey() final  bool ready;

/// Create a copy of ChallengeLinkState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChallengeLinkStateCopyWith<_ChallengeLinkState> get copyWith => __$ChallengeLinkStateCopyWithImpl<_ChallengeLinkState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChallengeLinkState&&(identical(other.link, link) || other.link == link)&&(identical(other.level, level) || other.level == level)&&const DeepCollectionEquality().equals(other.characters, _characters)&&(identical(other.ready, ready) || other.ready == ready));
}


@override
int get hashCode {
    return Object.hash(runtimeType,link,level,const DeepCollectionEquality().hash(_characters),ready);
}

@override
String toString() {
    return 'ChallengeLinkState(link: $link, level: $level, characters: $characters, ready: $ready)';
}


}

/// @nodoc
abstract mixin class _$ChallengeLinkStateCopyWith<$Res> implements $ChallengeLinkStateCopyWith<$Res> {
  factory _$ChallengeLinkStateCopyWith(_ChallengeLinkState value, $Res Function(_ChallengeLinkState) _then) = __$ChallengeLinkStateCopyWithImpl;
@override @useResult
$Res call({
 ChallengeLink link, int level, List<Character> characters, bool ready
});


@override $ChallengeLinkCopyWith<$Res> get link;

}
/// @nodoc
class __$ChallengeLinkStateCopyWithImpl<$Res>
    implements _$ChallengeLinkStateCopyWith<$Res> {
  __$ChallengeLinkStateCopyWithImpl(this._self, this._then);

  final _ChallengeLinkState _self;
  final $Res Function(_ChallengeLinkState) _then;

/// Create a copy of ChallengeLinkState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? link = null,Object? level = null,Object? characters = null,Object? ready = null,}) {
  return _then(_ChallengeLinkState(
link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as ChallengeLink,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,characters: null == characters ? _self._characters : characters // ignore: cast_nullable_to_non_nullable
as List<Character>,ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ChallengeLinkState
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
