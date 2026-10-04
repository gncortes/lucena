// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CatalogState {

/// Nulo enquanto o catálogo é lido.
 List<CatalogCategory>? get categories;/// As posições da subcategoria aberta, na ordem do catálogo. Nulo fora da
/// lista de posições ou enquanto ela é lida.
 List<EndgamePosition>? get positions; GoalFilter get filter;/// As posições em que o objetivo já foi cumprido.
 Set<String> get fulfilled;
/// Create a copy of CatalogState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogStateCopyWith<CatalogState> get copyWith => _$CatalogStateCopyWithImpl<CatalogState>(this as CatalogState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CatalogState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogState&&const DeepCollectionEquality().equals(other.categories, _this.categories)&&const DeepCollectionEquality().equals(other.positions, _this.positions)&&(identical(other.filter, _this.filter) || other.filter == _this.filter)&&const DeepCollectionEquality().equals(other.fulfilled, _this.fulfilled));
}


@override
int get hashCode {
  final _this = this as CatalogState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.categories),const DeepCollectionEquality().hash(_this.positions),_this.filter,const DeepCollectionEquality().hash(_this.fulfilled));
}

@override
String toString() {
  final _this = this as CatalogState;
  return 'CatalogState(categories: ${_this.categories}, positions: ${_this.positions}, filter: ${_this.filter}, fulfilled: ${_this.fulfilled})';
}


}

/// @nodoc
abstract mixin class $CatalogStateCopyWith<$Res>  {
  factory $CatalogStateCopyWith(CatalogState value, $Res Function(CatalogState) _then) = _$CatalogStateCopyWithImpl;
@useResult
$Res call({
 List<CatalogCategory>? categories, List<EndgamePosition>? positions, GoalFilter filter, Set<String> fulfilled
});




}
/// @nodoc
class _$CatalogStateCopyWithImpl<$Res>
    implements $CatalogStateCopyWith<$Res> {
  _$CatalogStateCopyWithImpl(this._self, this._then);

  final CatalogState _self;
  final $Res Function(CatalogState) _then;

/// Create a copy of CatalogState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categories = freezed,Object? positions = freezed,Object? filter = null,Object? fulfilled = null,}) {
  return _then(CatalogState(
categories: freezed == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<CatalogCategory>?,positions: freezed == positions ? _self.positions : positions // ignore: cast_nullable_to_non_nullable
as List<EndgamePosition>?,filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as GoalFilter,fulfilled: null == fulfilled ? _self.fulfilled : fulfilled // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogState].
extension CatalogStatePatterns on CatalogState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogState value)  $default,){
final _that = this;
switch (_that) {
case _CatalogState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogState value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CatalogCategory>? categories,  List<EndgamePosition>? positions,  GoalFilter filter,  Set<String> fulfilled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogState() when $default != null:
return $default(_that.categories,_that.positions,_that.filter,_that.fulfilled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CatalogCategory>? categories,  List<EndgamePosition>? positions,  GoalFilter filter,  Set<String> fulfilled)  $default,) {final _that = this;
switch (_that) {
case _CatalogState():
return $default(_that.categories,_that.positions,_that.filter,_that.fulfilled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CatalogCategory>? categories,  List<EndgamePosition>? positions,  GoalFilter filter,  Set<String> fulfilled)?  $default,) {final _that = this;
switch (_that) {
case _CatalogState() when $default != null:
return $default(_that.categories,_that.positions,_that.filter,_that.fulfilled);case _:
  return null;

}
}

}

/// @nodoc


class _CatalogState extends CatalogState {
  const _CatalogState({ List<CatalogCategory>? categories,  List<EndgamePosition>? positions, this.filter = GoalFilter.all,  Set<String> fulfilled = const <String>{}}): _categories = categories,_positions = positions,_fulfilled = fulfilled,super._();
  

/// Nulo enquanto o catálogo é lido.
 final  List<CatalogCategory>? _categories;
/// Nulo enquanto o catálogo é lido.
@override List<CatalogCategory>? get categories {
  final value = _categories;
  if (value == null) return null;
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// As posições da subcategoria aberta, na ordem do catálogo. Nulo fora da
/// lista de posições ou enquanto ela é lida.
 final  List<EndgamePosition>? _positions;
/// As posições da subcategoria aberta, na ordem do catálogo. Nulo fora da
/// lista de posições ou enquanto ela é lida.
@override List<EndgamePosition>? get positions {
  final value = _positions;
  if (value == null) return null;
  if (_positions is EqualUnmodifiableListView) return _positions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey() final  GoalFilter filter;
/// As posições em que o objetivo já foi cumprido.
 final  Set<String> _fulfilled;
/// As posições em que o objetivo já foi cumprido.
@override@JsonKey() Set<String> get fulfilled {
  if (_fulfilled is EqualUnmodifiableSetView) return _fulfilled;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_fulfilled);
}


/// Create a copy of CatalogState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogStateCopyWith<_CatalogState> get copyWith => __$CatalogStateCopyWithImpl<_CatalogState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogState&&const DeepCollectionEquality().equals(other.categories, _categories)&&const DeepCollectionEquality().equals(other.positions, _positions)&&(identical(other.filter, filter) || other.filter == filter)&&const DeepCollectionEquality().equals(other.fulfilled, _fulfilled));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_positions),filter,const DeepCollectionEquality().hash(_fulfilled));
}

@override
String toString() {
    return 'CatalogState(categories: $categories, positions: $positions, filter: $filter, fulfilled: $fulfilled)';
}


}

/// @nodoc
abstract mixin class _$CatalogStateCopyWith<$Res> implements $CatalogStateCopyWith<$Res> {
  factory _$CatalogStateCopyWith(_CatalogState value, $Res Function(_CatalogState) _then) = __$CatalogStateCopyWithImpl;
@override @useResult
$Res call({
 List<CatalogCategory>? categories, List<EndgamePosition>? positions, GoalFilter filter, Set<String> fulfilled
});




}
/// @nodoc
class __$CatalogStateCopyWithImpl<$Res>
    implements _$CatalogStateCopyWith<$Res> {
  __$CatalogStateCopyWithImpl(this._self, this._then);

  final _CatalogState _self;
  final $Res Function(_CatalogState) _then;

/// Create a copy of CatalogState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categories = freezed,Object? positions = freezed,Object? filter = null,Object? fulfilled = null,}) {
  return _then(_CatalogState(
categories: freezed == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<CatalogCategory>?,positions: freezed == positions ? _self._positions : positions // ignore: cast_nullable_to_non_nullable
as List<EndgamePosition>?,filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as GoalFilter,fulfilled: null == fulfilled ? _self._fulfilled : fulfilled // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on
