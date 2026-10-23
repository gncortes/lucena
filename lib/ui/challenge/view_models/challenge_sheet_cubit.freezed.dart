// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'challenge_sheet_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChallengeSheetState {

/// O desafio, com a trava que a pessoa escolheu.
 ChallengeLink get link;/// O menu do sistema está aberto: sem dois toques abrindo dois menus.
 bool get sharing;
/// Create a copy of ChallengeSheetState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChallengeSheetStateCopyWith<ChallengeSheetState> get copyWith => _$ChallengeSheetStateCopyWithImpl<ChallengeSheetState>(this as ChallengeSheetState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ChallengeSheetState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChallengeSheetState&&(identical(other.link, _this.link) || other.link == _this.link)&&(identical(other.sharing, _this.sharing) || other.sharing == _this.sharing));
}


@override
int get hashCode {
  final _this = this as ChallengeSheetState;
  return Object.hash(runtimeType,_this.link,_this.sharing);
}

@override
String toString() {
  final _this = this as ChallengeSheetState;
  return 'ChallengeSheetState(link: ${_this.link}, sharing: ${_this.sharing})';
}


}

/// @nodoc
abstract mixin class $ChallengeSheetStateCopyWith<$Res>  {
  factory $ChallengeSheetStateCopyWith(ChallengeSheetState value, $Res Function(ChallengeSheetState) _then) = _$ChallengeSheetStateCopyWithImpl;
@useResult
$Res call({
 ChallengeLink link, bool sharing
});


$ChallengeLinkCopyWith<$Res> get link;

}
/// @nodoc
class _$ChallengeSheetStateCopyWithImpl<$Res>
    implements $ChallengeSheetStateCopyWith<$Res> {
  _$ChallengeSheetStateCopyWithImpl(this._self, this._then);

  final ChallengeSheetState _self;
  final $Res Function(ChallengeSheetState) _then;

/// Create a copy of ChallengeSheetState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? link = null,Object? sharing = null,}) {
  return _then(ChallengeSheetState(
link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as ChallengeLink,sharing: null == sharing ? _self.sharing : sharing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ChallengeSheetState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChallengeLinkCopyWith<$Res> get link {
  
  return $ChallengeLinkCopyWith<$Res>(_self.link, (value) {
    return _then(_self.copyWith(link: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChallengeSheetState].
extension ChallengeSheetStatePatterns on ChallengeSheetState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChallengeSheetState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChallengeSheetState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChallengeSheetState value)  $default,){
final _that = this;
switch (_that) {
case _ChallengeSheetState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChallengeSheetState value)?  $default,){
final _that = this;
switch (_that) {
case _ChallengeSheetState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ChallengeLink link,  bool sharing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChallengeSheetState() when $default != null:
return $default(_that.link,_that.sharing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ChallengeLink link,  bool sharing)  $default,) {final _that = this;
switch (_that) {
case _ChallengeSheetState():
return $default(_that.link,_that.sharing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ChallengeLink link,  bool sharing)?  $default,) {final _that = this;
switch (_that) {
case _ChallengeSheetState() when $default != null:
return $default(_that.link,_that.sharing);case _:
  return null;

}
}

}

/// @nodoc


class _ChallengeSheetState implements ChallengeSheetState {
  const _ChallengeSheetState({required this.link, this.sharing = false});
  

/// O desafio, com a trava que a pessoa escolheu.
@override final  ChallengeLink link;
/// O menu do sistema está aberto: sem dois toques abrindo dois menus.
@override@JsonKey() final  bool sharing;

/// Create a copy of ChallengeSheetState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChallengeSheetStateCopyWith<_ChallengeSheetState> get copyWith => __$ChallengeSheetStateCopyWithImpl<_ChallengeSheetState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChallengeSheetState&&(identical(other.link, link) || other.link == link)&&(identical(other.sharing, sharing) || other.sharing == sharing));
}


@override
int get hashCode {
    return Object.hash(runtimeType,link,sharing);
}

@override
String toString() {
    return 'ChallengeSheetState(link: $link, sharing: $sharing)';
}


}

/// @nodoc
abstract mixin class _$ChallengeSheetStateCopyWith<$Res> implements $ChallengeSheetStateCopyWith<$Res> {
  factory _$ChallengeSheetStateCopyWith(_ChallengeSheetState value, $Res Function(_ChallengeSheetState) _then) = __$ChallengeSheetStateCopyWithImpl;
@override @useResult
$Res call({
 ChallengeLink link, bool sharing
});


@override $ChallengeLinkCopyWith<$Res> get link;

}
/// @nodoc
class __$ChallengeSheetStateCopyWithImpl<$Res>
    implements _$ChallengeSheetStateCopyWith<$Res> {
  __$ChallengeSheetStateCopyWithImpl(this._self, this._then);

  final _ChallengeSheetState _self;
  final $Res Function(_ChallengeSheetState) _then;

/// Create a copy of ChallengeSheetState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? link = null,Object? sharing = null,}) {
  return _then(_ChallengeSheetState(
link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as ChallengeLink,sharing: null == sharing ? _self.sharing : sharing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ChallengeSheetState
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
