// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'maia_timing.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MaiaTiming {

/// Quantas contas foram medidas.
 int get runs;/// O tempo do meio: metade das contas foi mais rápida, metade mais lenta.
 Duration get median; Duration get fastest; Duration get slowest;
/// Create a copy of MaiaTiming
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MaiaTimingCopyWith<MaiaTiming> get copyWith => _$MaiaTimingCopyWithImpl<MaiaTiming>(this as MaiaTiming, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MaiaTiming;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MaiaTiming&&(identical(other.runs, _this.runs) || other.runs == _this.runs)&&(identical(other.median, _this.median) || other.median == _this.median)&&(identical(other.fastest, _this.fastest) || other.fastest == _this.fastest)&&(identical(other.slowest, _this.slowest) || other.slowest == _this.slowest));
}


@override
int get hashCode {
  final _this = this as MaiaTiming;
  return Object.hash(runtimeType,_this.runs,_this.median,_this.fastest,_this.slowest);
}

@override
String toString() {
  final _this = this as MaiaTiming;
  return 'MaiaTiming(runs: ${_this.runs}, median: ${_this.median}, fastest: ${_this.fastest}, slowest: ${_this.slowest})';
}


}

/// @nodoc
abstract mixin class $MaiaTimingCopyWith<$Res>  {
  factory $MaiaTimingCopyWith(MaiaTiming value, $Res Function(MaiaTiming) _then) = _$MaiaTimingCopyWithImpl;
@useResult
$Res call({
 int runs, Duration median, Duration fastest, Duration slowest
});




}
/// @nodoc
class _$MaiaTimingCopyWithImpl<$Res>
    implements $MaiaTimingCopyWith<$Res> {
  _$MaiaTimingCopyWithImpl(this._self, this._then);

  final MaiaTiming _self;
  final $Res Function(MaiaTiming) _then;

/// Create a copy of MaiaTiming
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? runs = null,Object? median = null,Object? fastest = null,Object? slowest = null,}) {
  return _then(MaiaTiming(
runs: null == runs ? _self.runs : runs // ignore: cast_nullable_to_non_nullable
as int,median: null == median ? _self.median : median // ignore: cast_nullable_to_non_nullable
as Duration,fastest: null == fastest ? _self.fastest : fastest // ignore: cast_nullable_to_non_nullable
as Duration,slowest: null == slowest ? _self.slowest : slowest // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}

}


/// Adds pattern-matching-related methods to [MaiaTiming].
extension MaiaTimingPatterns on MaiaTiming {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MaiaTiming value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MaiaTiming() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MaiaTiming value)  $default,){
final _that = this;
switch (_that) {
case _MaiaTiming():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MaiaTiming value)?  $default,){
final _that = this;
switch (_that) {
case _MaiaTiming() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int runs,  Duration median,  Duration fastest,  Duration slowest)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MaiaTiming() when $default != null:
return $default(_that.runs,_that.median,_that.fastest,_that.slowest);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int runs,  Duration median,  Duration fastest,  Duration slowest)  $default,) {final _that = this;
switch (_that) {
case _MaiaTiming():
return $default(_that.runs,_that.median,_that.fastest,_that.slowest);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int runs,  Duration median,  Duration fastest,  Duration slowest)?  $default,) {final _that = this;
switch (_that) {
case _MaiaTiming() when $default != null:
return $default(_that.runs,_that.median,_that.fastest,_that.slowest);case _:
  return null;

}
}

}

/// @nodoc


class _MaiaTiming implements MaiaTiming {
  const _MaiaTiming({required this.runs, required this.median, required this.fastest, required this.slowest});
  

/// Quantas contas foram medidas.
@override final  int runs;
/// O tempo do meio: metade das contas foi mais rápida, metade mais lenta.
@override final  Duration median;
@override final  Duration fastest;
@override final  Duration slowest;

/// Create a copy of MaiaTiming
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MaiaTimingCopyWith<_MaiaTiming> get copyWith => __$MaiaTimingCopyWithImpl<_MaiaTiming>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MaiaTiming&&(identical(other.runs, runs) || other.runs == runs)&&(identical(other.median, median) || other.median == median)&&(identical(other.fastest, fastest) || other.fastest == fastest)&&(identical(other.slowest, slowest) || other.slowest == slowest));
}


@override
int get hashCode {
    return Object.hash(runtimeType,runs,median,fastest,slowest);
}

@override
String toString() {
    return 'MaiaTiming(runs: $runs, median: $median, fastest: $fastest, slowest: $slowest)';
}


}

/// @nodoc
abstract mixin class _$MaiaTimingCopyWith<$Res> implements $MaiaTimingCopyWith<$Res> {
  factory _$MaiaTimingCopyWith(_MaiaTiming value, $Res Function(_MaiaTiming) _then) = __$MaiaTimingCopyWithImpl;
@override @useResult
$Res call({
 int runs, Duration median, Duration fastest, Duration slowest
});




}
/// @nodoc
class __$MaiaTimingCopyWithImpl<$Res>
    implements _$MaiaTimingCopyWith<$Res> {
  __$MaiaTimingCopyWithImpl(this._self, this._then);

  final _MaiaTiming _self;
  final $Res Function(_MaiaTiming) _then;

/// Create a copy of MaiaTiming
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? runs = null,Object? median = null,Object? fastest = null,Object? slowest = null,}) {
  return _then(_MaiaTiming(
runs: null == runs ? _self.runs : runs // ignore: cast_nullable_to_non_nullable
as int,median: null == median ? _self.median : median // ignore: cast_nullable_to_non_nullable
as Duration,fastest: null == fastest ? _self.fastest : fastest // ignore: cast_nullable_to_non_nullable
as Duration,slowest: null == slowest ? _self.slowest : slowest // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

// dart format on
