// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'endgame_position.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EndgamePosition {

/// `categoria.subcategoria.NNNN`, estável entre versões do catálogo.
 String get id; String get category; String get subcategory; String get fen; PositionGoal get goal;/// Mate em quantos lances, quando a fonte informa.
 int? get mateIn;/// Conferida na tablebase do Lichess.
 bool get verified;
/// Create a copy of EndgamePosition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EndgamePositionCopyWith<EndgamePosition> get copyWith => _$EndgamePositionCopyWithImpl<EndgamePosition>(this as EndgamePosition, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EndgamePosition;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EndgamePosition&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.subcategory, _this.subcategory) || other.subcategory == _this.subcategory)&&(identical(other.fen, _this.fen) || other.fen == _this.fen)&&(identical(other.goal, _this.goal) || other.goal == _this.goal)&&(identical(other.mateIn, _this.mateIn) || other.mateIn == _this.mateIn)&&(identical(other.verified, _this.verified) || other.verified == _this.verified));
}


@override
int get hashCode {
  final _this = this as EndgamePosition;
  return Object.hash(runtimeType,_this.id,_this.category,_this.subcategory,_this.fen,_this.goal,_this.mateIn,_this.verified);
}

@override
String toString() {
  final _this = this as EndgamePosition;
  return 'EndgamePosition(id: ${_this.id}, category: ${_this.category}, subcategory: ${_this.subcategory}, fen: ${_this.fen}, goal: ${_this.goal}, mateIn: ${_this.mateIn}, verified: ${_this.verified})';
}


}

/// @nodoc
abstract mixin class $EndgamePositionCopyWith<$Res>  {
  factory $EndgamePositionCopyWith(EndgamePosition value, $Res Function(EndgamePosition) _then) = _$EndgamePositionCopyWithImpl;
@useResult
$Res call({
 String id, String category, String subcategory, String fen, PositionGoal goal, int? mateIn, bool verified
});




}
/// @nodoc
class _$EndgamePositionCopyWithImpl<$Res>
    implements $EndgamePositionCopyWith<$Res> {
  _$EndgamePositionCopyWithImpl(this._self, this._then);

  final EndgamePosition _self;
  final $Res Function(EndgamePosition) _then;

/// Create a copy of EndgamePosition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? category = null,Object? subcategory = null,Object? fen = null,Object? goal = null,Object? mateIn = freezed,Object? verified = null,}) {
  return _then(EndgamePosition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,subcategory: null == subcategory ? _self.subcategory : subcategory // ignore: cast_nullable_to_non_nullable
as String,fen: null == fen ? _self.fen : fen // ignore: cast_nullable_to_non_nullable
as String,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as PositionGoal,mateIn: freezed == mateIn ? _self.mateIn : mateIn // ignore: cast_nullable_to_non_nullable
as int?,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [EndgamePosition].
extension EndgamePositionPatterns on EndgamePosition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EndgamePosition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EndgamePosition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EndgamePosition value)  $default,){
final _that = this;
switch (_that) {
case _EndgamePosition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EndgamePosition value)?  $default,){
final _that = this;
switch (_that) {
case _EndgamePosition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String category,  String subcategory,  String fen,  PositionGoal goal,  int? mateIn,  bool verified)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EndgamePosition() when $default != null:
return $default(_that.id,_that.category,_that.subcategory,_that.fen,_that.goal,_that.mateIn,_that.verified);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String category,  String subcategory,  String fen,  PositionGoal goal,  int? mateIn,  bool verified)  $default,) {final _that = this;
switch (_that) {
case _EndgamePosition():
return $default(_that.id,_that.category,_that.subcategory,_that.fen,_that.goal,_that.mateIn,_that.verified);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String category,  String subcategory,  String fen,  PositionGoal goal,  int? mateIn,  bool verified)?  $default,) {final _that = this;
switch (_that) {
case _EndgamePosition() when $default != null:
return $default(_that.id,_that.category,_that.subcategory,_that.fen,_that.goal,_that.mateIn,_that.verified);case _:
  return null;

}
}

}

/// @nodoc


class _EndgamePosition extends EndgamePosition {
  const _EndgamePosition({required this.id, required this.category, required this.subcategory, required this.fen, required this.goal, this.mateIn, this.verified = false}): super._();
  

/// `categoria.subcategoria.NNNN`, estável entre versões do catálogo.
@override final  String id;
@override final  String category;
@override final  String subcategory;
@override final  String fen;
@override final  PositionGoal goal;
/// Mate em quantos lances, quando a fonte informa.
@override final  int? mateIn;
/// Conferida na tablebase do Lichess.
@override@JsonKey() final  bool verified;

/// Create a copy of EndgamePosition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EndgamePositionCopyWith<_EndgamePosition> get copyWith => __$EndgamePositionCopyWithImpl<_EndgamePosition>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EndgamePosition&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.subcategory, subcategory) || other.subcategory == subcategory)&&(identical(other.fen, fen) || other.fen == fen)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.mateIn, mateIn) || other.mateIn == mateIn)&&(identical(other.verified, verified) || other.verified == verified));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,category,subcategory,fen,goal,mateIn,verified);
}

@override
String toString() {
    return 'EndgamePosition(id: $id, category: $category, subcategory: $subcategory, fen: $fen, goal: $goal, mateIn: $mateIn, verified: $verified)';
}


}

/// @nodoc
abstract mixin class _$EndgamePositionCopyWith<$Res> implements $EndgamePositionCopyWith<$Res> {
  factory _$EndgamePositionCopyWith(_EndgamePosition value, $Res Function(_EndgamePosition) _then) = __$EndgamePositionCopyWithImpl;
@override @useResult
$Res call({
 String id, String category, String subcategory, String fen, PositionGoal goal, int? mateIn, bool verified
});




}
/// @nodoc
class __$EndgamePositionCopyWithImpl<$Res>
    implements _$EndgamePositionCopyWith<$Res> {
  __$EndgamePositionCopyWithImpl(this._self, this._then);

  final _EndgamePosition _self;
  final $Res Function(_EndgamePosition) _then;

/// Create a copy of EndgamePosition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? category = null,Object? subcategory = null,Object? fen = null,Object? goal = null,Object? mateIn = freezed,Object? verified = null,}) {
  return _then(_EndgamePosition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,subcategory: null == subcategory ? _self.subcategory : subcategory // ignore: cast_nullable_to_non_nullable
as String,fen: null == fen ? _self.fen : fen // ignore: cast_nullable_to_non_nullable
as String,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as PositionGoal,mateIn: freezed == mateIn ? _self.mateIn : mateIn // ignore: cast_nullable_to_non_nullable
as int?,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$CatalogSubcategory {

 String get key; String get category; int get winCount; int get drawCount;
/// Create a copy of CatalogSubcategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogSubcategoryCopyWith<CatalogSubcategory> get copyWith => _$CatalogSubcategoryCopyWithImpl<CatalogSubcategory>(this as CatalogSubcategory, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CatalogSubcategory;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogSubcategory&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.winCount, _this.winCount) || other.winCount == _this.winCount)&&(identical(other.drawCount, _this.drawCount) || other.drawCount == _this.drawCount));
}


@override
int get hashCode {
  final _this = this as CatalogSubcategory;
  return Object.hash(runtimeType,_this.key,_this.category,_this.winCount,_this.drawCount);
}

@override
String toString() {
  final _this = this as CatalogSubcategory;
  return 'CatalogSubcategory(key: ${_this.key}, category: ${_this.category}, winCount: ${_this.winCount}, drawCount: ${_this.drawCount})';
}


}

/// @nodoc
abstract mixin class $CatalogSubcategoryCopyWith<$Res>  {
  factory $CatalogSubcategoryCopyWith(CatalogSubcategory value, $Res Function(CatalogSubcategory) _then) = _$CatalogSubcategoryCopyWithImpl;
@useResult
$Res call({
 String key, String category, int winCount, int drawCount
});




}
/// @nodoc
class _$CatalogSubcategoryCopyWithImpl<$Res>
    implements $CatalogSubcategoryCopyWith<$Res> {
  _$CatalogSubcategoryCopyWithImpl(this._self, this._then);

  final CatalogSubcategory _self;
  final $Res Function(CatalogSubcategory) _then;

/// Create a copy of CatalogSubcategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? category = null,Object? winCount = null,Object? drawCount = null,}) {
  return _then(CatalogSubcategory(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,winCount: null == winCount ? _self.winCount : winCount // ignore: cast_nullable_to_non_nullable
as int,drawCount: null == drawCount ? _self.drawCount : drawCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogSubcategory].
extension CatalogSubcategoryPatterns on CatalogSubcategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogSubcategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogSubcategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogSubcategory value)  $default,){
final _that = this;
switch (_that) {
case _CatalogSubcategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogSubcategory value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogSubcategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String category,  int winCount,  int drawCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogSubcategory() when $default != null:
return $default(_that.key,_that.category,_that.winCount,_that.drawCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String category,  int winCount,  int drawCount)  $default,) {final _that = this;
switch (_that) {
case _CatalogSubcategory():
return $default(_that.key,_that.category,_that.winCount,_that.drawCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String category,  int winCount,  int drawCount)?  $default,) {final _that = this;
switch (_that) {
case _CatalogSubcategory() when $default != null:
return $default(_that.key,_that.category,_that.winCount,_that.drawCount);case _:
  return null;

}
}

}

/// @nodoc


class _CatalogSubcategory extends CatalogSubcategory {
  const _CatalogSubcategory({required this.key, required this.category, this.winCount = 0, this.drawCount = 0}): super._();
  

@override final  String key;
@override final  String category;
@override@JsonKey() final  int winCount;
@override@JsonKey() final  int drawCount;

/// Create a copy of CatalogSubcategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogSubcategoryCopyWith<_CatalogSubcategory> get copyWith => __$CatalogSubcategoryCopyWithImpl<_CatalogSubcategory>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogSubcategory&&(identical(other.key, key) || other.key == key)&&(identical(other.category, category) || other.category == category)&&(identical(other.winCount, winCount) || other.winCount == winCount)&&(identical(other.drawCount, drawCount) || other.drawCount == drawCount));
}


@override
int get hashCode {
    return Object.hash(runtimeType,key,category,winCount,drawCount);
}

@override
String toString() {
    return 'CatalogSubcategory(key: $key, category: $category, winCount: $winCount, drawCount: $drawCount)';
}


}

/// @nodoc
abstract mixin class _$CatalogSubcategoryCopyWith<$Res> implements $CatalogSubcategoryCopyWith<$Res> {
  factory _$CatalogSubcategoryCopyWith(_CatalogSubcategory value, $Res Function(_CatalogSubcategory) _then) = __$CatalogSubcategoryCopyWithImpl;
@override @useResult
$Res call({
 String key, String category, int winCount, int drawCount
});




}
/// @nodoc
class __$CatalogSubcategoryCopyWithImpl<$Res>
    implements _$CatalogSubcategoryCopyWith<$Res> {
  __$CatalogSubcategoryCopyWithImpl(this._self, this._then);

  final _CatalogSubcategory _self;
  final $Res Function(_CatalogSubcategory) _then;

/// Create a copy of CatalogSubcategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? category = null,Object? winCount = null,Object? drawCount = null,}) {
  return _then(_CatalogSubcategory(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,winCount: null == winCount ? _self.winCount : winCount // ignore: cast_nullable_to_non_nullable
as int,drawCount: null == drawCount ? _self.drawCount : drawCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$CatalogCategory {

 String get key; List<CatalogSubcategory> get subcategories;
/// Create a copy of CatalogCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogCategoryCopyWith<CatalogCategory> get copyWith => _$CatalogCategoryCopyWithImpl<CatalogCategory>(this as CatalogCategory, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CatalogCategory;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogCategory&&(identical(other.key, _this.key) || other.key == _this.key)&&const DeepCollectionEquality().equals(other.subcategories, _this.subcategories));
}


@override
int get hashCode {
  final _this = this as CatalogCategory;
  return Object.hash(runtimeType,_this.key,const DeepCollectionEquality().hash(_this.subcategories));
}

@override
String toString() {
  final _this = this as CatalogCategory;
  return 'CatalogCategory(key: ${_this.key}, subcategories: ${_this.subcategories})';
}


}

/// @nodoc
abstract mixin class $CatalogCategoryCopyWith<$Res>  {
  factory $CatalogCategoryCopyWith(CatalogCategory value, $Res Function(CatalogCategory) _then) = _$CatalogCategoryCopyWithImpl;
@useResult
$Res call({
 String key, List<CatalogSubcategory> subcategories
});




}
/// @nodoc
class _$CatalogCategoryCopyWithImpl<$Res>
    implements $CatalogCategoryCopyWith<$Res> {
  _$CatalogCategoryCopyWithImpl(this._self, this._then);

  final CatalogCategory _self;
  final $Res Function(CatalogCategory) _then;

/// Create a copy of CatalogCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? subcategories = null,}) {
  return _then(CatalogCategory(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,subcategories: null == subcategories ? _self.subcategories : subcategories // ignore: cast_nullable_to_non_nullable
as List<CatalogSubcategory>,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogCategory].
extension CatalogCategoryPatterns on CatalogCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogCategory value)  $default,){
final _that = this;
switch (_that) {
case _CatalogCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogCategory value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  List<CatalogSubcategory> subcategories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogCategory() when $default != null:
return $default(_that.key,_that.subcategories);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  List<CatalogSubcategory> subcategories)  $default,) {final _that = this;
switch (_that) {
case _CatalogCategory():
return $default(_that.key,_that.subcategories);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  List<CatalogSubcategory> subcategories)?  $default,) {final _that = this;
switch (_that) {
case _CatalogCategory() when $default != null:
return $default(_that.key,_that.subcategories);case _:
  return null;

}
}

}

/// @nodoc


class _CatalogCategory extends CatalogCategory {
  const _CatalogCategory({required this.key, required  List<CatalogSubcategory> subcategories}): _subcategories = subcategories,super._();
  

@override final  String key;
 final  List<CatalogSubcategory> _subcategories;
@override List<CatalogSubcategory> get subcategories {
  if (_subcategories is EqualUnmodifiableListView) return _subcategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subcategories);
}


/// Create a copy of CatalogCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogCategoryCopyWith<_CatalogCategory> get copyWith => __$CatalogCategoryCopyWithImpl<_CatalogCategory>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogCategory&&(identical(other.key, key) || other.key == key)&&const DeepCollectionEquality().equals(other.subcategories, _subcategories));
}


@override
int get hashCode {
    return Object.hash(runtimeType,key,const DeepCollectionEquality().hash(_subcategories));
}

@override
String toString() {
    return 'CatalogCategory(key: $key, subcategories: $subcategories)';
}


}

/// @nodoc
abstract mixin class _$CatalogCategoryCopyWith<$Res> implements $CatalogCategoryCopyWith<$Res> {
  factory _$CatalogCategoryCopyWith(_CatalogCategory value, $Res Function(_CatalogCategory) _then) = __$CatalogCategoryCopyWithImpl;
@override @useResult
$Res call({
 String key, List<CatalogSubcategory> subcategories
});




}
/// @nodoc
class __$CatalogCategoryCopyWithImpl<$Res>
    implements _$CatalogCategoryCopyWith<$Res> {
  __$CatalogCategoryCopyWithImpl(this._self, this._then);

  final _CatalogCategory _self;
  final $Res Function(_CatalogCategory) _then;

/// Create a copy of CatalogCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? subcategories = null,}) {
  return _then(_CatalogCategory(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,subcategories: null == subcategories ? _self._subcategories : subcategories // ignore: cast_nullable_to_non_nullable
as List<CatalogSubcategory>,
  ));
}


}

// dart format on
