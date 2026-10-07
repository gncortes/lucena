// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'speedrun.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Speedrun {

 String get id; SpeedrunKind get kind;/// O degrau (`1000`), no speedrun de degrau.
 String? get rungId;/// A posição do catálogo, no speedrun de final.
 String? get positionId;/// A dificuldade, nos speedruns de final (e nas Maratonas deles).
 SpeedrunCategory? get category;/// Só da Jornada (desafio especial de um degrau): fora da lista do
/// speedrun.
 bool get journeyOnly;/// O tempo de cada lado em todas as etapas.
 TimeControl get time;/// As etapas: posição, adversário e objetivo, como um desafio.
 List<Challenge> get stages;
/// Create a copy of Speedrun
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpeedrunCopyWith<Speedrun> get copyWith => _$SpeedrunCopyWithImpl<Speedrun>(this as Speedrun, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Speedrun;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Speedrun&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.rungId, _this.rungId) || other.rungId == _this.rungId)&&(identical(other.positionId, _this.positionId) || other.positionId == _this.positionId)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.journeyOnly, _this.journeyOnly) || other.journeyOnly == _this.journeyOnly)&&(identical(other.time, _this.time) || other.time == _this.time)&&const DeepCollectionEquality().equals(other.stages, _this.stages));
}


@override
int get hashCode {
  final _this = this as Speedrun;
  return Object.hash(runtimeType,_this.id,_this.kind,_this.rungId,_this.positionId,_this.category,_this.journeyOnly,_this.time,const DeepCollectionEquality().hash(_this.stages));
}

@override
String toString() {
  final _this = this as Speedrun;
  return 'Speedrun(id: ${_this.id}, kind: ${_this.kind}, rungId: ${_this.rungId}, positionId: ${_this.positionId}, category: ${_this.category}, journeyOnly: ${_this.journeyOnly}, time: ${_this.time}, stages: ${_this.stages})';
}


}

/// @nodoc
abstract mixin class $SpeedrunCopyWith<$Res>  {
  factory $SpeedrunCopyWith(Speedrun value, $Res Function(Speedrun) _then) = _$SpeedrunCopyWithImpl;
@useResult
$Res call({
 String id, SpeedrunKind kind, String? rungId, String? positionId, SpeedrunCategory? category, bool journeyOnly, TimeControl time, List<Challenge> stages
});


$TimeControlCopyWith<$Res> get time;

}
/// @nodoc
class _$SpeedrunCopyWithImpl<$Res>
    implements $SpeedrunCopyWith<$Res> {
  _$SpeedrunCopyWithImpl(this._self, this._then);

  final Speedrun _self;
  final $Res Function(Speedrun) _then;

/// Create a copy of Speedrun
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? rungId = freezed,Object? positionId = freezed,Object? category = freezed,Object? journeyOnly = null,Object? time = null,Object? stages = null,}) {
  return _then(Speedrun(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SpeedrunKind,rungId: freezed == rungId ? _self.rungId : rungId // ignore: cast_nullable_to_non_nullable
as String?,positionId: freezed == positionId ? _self.positionId : positionId // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as SpeedrunCategory?,journeyOnly: null == journeyOnly ? _self.journeyOnly : journeyOnly // ignore: cast_nullable_to_non_nullable
as bool,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as TimeControl,stages: null == stages ? _self.stages : stages // ignore: cast_nullable_to_non_nullable
as List<Challenge>,
  ));
}
/// Create a copy of Speedrun
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeControlCopyWith<$Res> get time {
  
  return $TimeControlCopyWith<$Res>(_self.time, (value) {
    return _then(_self.copyWith(time: value));
  });
}
}


/// Adds pattern-matching-related methods to [Speedrun].
extension SpeedrunPatterns on Speedrun {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Speedrun value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Speedrun() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Speedrun value)  $default,){
final _that = this;
switch (_that) {
case _Speedrun():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Speedrun value)?  $default,){
final _that = this;
switch (_that) {
case _Speedrun() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  SpeedrunKind kind,  String? rungId,  String? positionId,  SpeedrunCategory? category,  bool journeyOnly,  TimeControl time,  List<Challenge> stages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Speedrun() when $default != null:
return $default(_that.id,_that.kind,_that.rungId,_that.positionId,_that.category,_that.journeyOnly,_that.time,_that.stages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  SpeedrunKind kind,  String? rungId,  String? positionId,  SpeedrunCategory? category,  bool journeyOnly,  TimeControl time,  List<Challenge> stages)  $default,) {final _that = this;
switch (_that) {
case _Speedrun():
return $default(_that.id,_that.kind,_that.rungId,_that.positionId,_that.category,_that.journeyOnly,_that.time,_that.stages);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  SpeedrunKind kind,  String? rungId,  String? positionId,  SpeedrunCategory? category,  bool journeyOnly,  TimeControl time,  List<Challenge> stages)?  $default,) {final _that = this;
switch (_that) {
case _Speedrun() when $default != null:
return $default(_that.id,_that.kind,_that.rungId,_that.positionId,_that.category,_that.journeyOnly,_that.time,_that.stages);case _:
  return null;

}
}

}

/// @nodoc


class _Speedrun implements Speedrun {
  const _Speedrun({required this.id, required this.kind, this.rungId, this.positionId, this.category, this.journeyOnly = false, required this.time, required  List<Challenge> stages}): _stages = stages;
  

@override final  String id;
@override final  SpeedrunKind kind;
/// O degrau (`1000`), no speedrun de degrau.
@override final  String? rungId;
/// A posição do catálogo, no speedrun de final.
@override final  String? positionId;
/// A dificuldade, nos speedruns de final (e nas Maratonas deles).
@override final  SpeedrunCategory? category;
/// Só da Jornada (desafio especial de um degrau): fora da lista do
/// speedrun.
@override@JsonKey() final  bool journeyOnly;
/// O tempo de cada lado em todas as etapas.
@override final  TimeControl time;
/// As etapas: posição, adversário e objetivo, como um desafio.
 final  List<Challenge> _stages;
/// As etapas: posição, adversário e objetivo, como um desafio.
@override List<Challenge> get stages {
  if (_stages is EqualUnmodifiableListView) return _stages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stages);
}


/// Create a copy of Speedrun
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpeedrunCopyWith<_Speedrun> get copyWith => __$SpeedrunCopyWithImpl<_Speedrun>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Speedrun&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.rungId, rungId) || other.rungId == rungId)&&(identical(other.positionId, positionId) || other.positionId == positionId)&&(identical(other.category, category) || other.category == category)&&(identical(other.journeyOnly, journeyOnly) || other.journeyOnly == journeyOnly)&&(identical(other.time, time) || other.time == time)&&const DeepCollectionEquality().equals(other.stages, _stages));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,kind,rungId,positionId,category,journeyOnly,time,const DeepCollectionEquality().hash(_stages));
}

@override
String toString() {
    return 'Speedrun(id: $id, kind: $kind, rungId: $rungId, positionId: $positionId, category: $category, journeyOnly: $journeyOnly, time: $time, stages: $stages)';
}


}

/// @nodoc
abstract mixin class _$SpeedrunCopyWith<$Res> implements $SpeedrunCopyWith<$Res> {
  factory _$SpeedrunCopyWith(_Speedrun value, $Res Function(_Speedrun) _then) = __$SpeedrunCopyWithImpl;
@override @useResult
$Res call({
 String id, SpeedrunKind kind, String? rungId, String? positionId, SpeedrunCategory? category, bool journeyOnly, TimeControl time, List<Challenge> stages
});


@override $TimeControlCopyWith<$Res> get time;

}
/// @nodoc
class __$SpeedrunCopyWithImpl<$Res>
    implements _$SpeedrunCopyWith<$Res> {
  __$SpeedrunCopyWithImpl(this._self, this._then);

  final _Speedrun _self;
  final $Res Function(_Speedrun) _then;

/// Create a copy of Speedrun
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? rungId = freezed,Object? positionId = freezed,Object? category = freezed,Object? journeyOnly = null,Object? time = null,Object? stages = null,}) {
  return _then(_Speedrun(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SpeedrunKind,rungId: freezed == rungId ? _self.rungId : rungId // ignore: cast_nullable_to_non_nullable
as String?,positionId: freezed == positionId ? _self.positionId : positionId // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as SpeedrunCategory?,journeyOnly: null == journeyOnly ? _self.journeyOnly : journeyOnly // ignore: cast_nullable_to_non_nullable
as bool,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as TimeControl,stages: null == stages ? _self._stages : stages // ignore: cast_nullable_to_non_nullable
as List<Challenge>,
  ));
}

/// Create a copy of Speedrun
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeControlCopyWith<$Res> get time {
  
  return $TimeControlCopyWith<$Res>(_self.time, (value) {
    return _then(_self.copyWith(time: value));
  });
}
}

/// @nodoc
mixin _$SpeedrunAttempt {

 int get id; String get speedrunId; DateTime get startedAt;/// Quando o jogador desistiu da tentativa. Nulo: não desistiu.
 DateTime? get abandonedAt;/// As partidas da tentativa, na ordem em que foram jogadas.
 List<Attempt> get games;
/// Create a copy of SpeedrunAttempt
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpeedrunAttemptCopyWith<SpeedrunAttempt> get copyWith => _$SpeedrunAttemptCopyWithImpl<SpeedrunAttempt>(this as SpeedrunAttempt, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SpeedrunAttempt;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpeedrunAttempt&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.speedrunId, _this.speedrunId) || other.speedrunId == _this.speedrunId)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.abandonedAt, _this.abandonedAt) || other.abandonedAt == _this.abandonedAt)&&const DeepCollectionEquality().equals(other.games, _this.games));
}


@override
int get hashCode {
  final _this = this as SpeedrunAttempt;
  return Object.hash(runtimeType,_this.id,_this.speedrunId,_this.startedAt,_this.abandonedAt,const DeepCollectionEquality().hash(_this.games));
}

@override
String toString() {
  final _this = this as SpeedrunAttempt;
  return 'SpeedrunAttempt(id: ${_this.id}, speedrunId: ${_this.speedrunId}, startedAt: ${_this.startedAt}, abandonedAt: ${_this.abandonedAt}, games: ${_this.games})';
}


}

/// @nodoc
abstract mixin class $SpeedrunAttemptCopyWith<$Res>  {
  factory $SpeedrunAttemptCopyWith(SpeedrunAttempt value, $Res Function(SpeedrunAttempt) _then) = _$SpeedrunAttemptCopyWithImpl;
@useResult
$Res call({
 int id, String speedrunId, DateTime startedAt, DateTime? abandonedAt, List<Attempt> games
});




}
/// @nodoc
class _$SpeedrunAttemptCopyWithImpl<$Res>
    implements $SpeedrunAttemptCopyWith<$Res> {
  _$SpeedrunAttemptCopyWithImpl(this._self, this._then);

  final SpeedrunAttempt _self;
  final $Res Function(SpeedrunAttempt) _then;

/// Create a copy of SpeedrunAttempt
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? speedrunId = null,Object? startedAt = null,Object? abandonedAt = freezed,Object? games = null,}) {
  return _then(SpeedrunAttempt(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,speedrunId: null == speedrunId ? _self.speedrunId : speedrunId // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,abandonedAt: freezed == abandonedAt ? _self.abandonedAt : abandonedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,games: null == games ? _self.games : games // ignore: cast_nullable_to_non_nullable
as List<Attempt>,
  ));
}

}


/// Adds pattern-matching-related methods to [SpeedrunAttempt].
extension SpeedrunAttemptPatterns on SpeedrunAttempt {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpeedrunAttempt value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpeedrunAttempt() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpeedrunAttempt value)  $default,){
final _that = this;
switch (_that) {
case _SpeedrunAttempt():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpeedrunAttempt value)?  $default,){
final _that = this;
switch (_that) {
case _SpeedrunAttempt() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String speedrunId,  DateTime startedAt,  DateTime? abandonedAt,  List<Attempt> games)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpeedrunAttempt() when $default != null:
return $default(_that.id,_that.speedrunId,_that.startedAt,_that.abandonedAt,_that.games);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String speedrunId,  DateTime startedAt,  DateTime? abandonedAt,  List<Attempt> games)  $default,) {final _that = this;
switch (_that) {
case _SpeedrunAttempt():
return $default(_that.id,_that.speedrunId,_that.startedAt,_that.abandonedAt,_that.games);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String speedrunId,  DateTime startedAt,  DateTime? abandonedAt,  List<Attempt> games)?  $default,) {final _that = this;
switch (_that) {
case _SpeedrunAttempt() when $default != null:
return $default(_that.id,_that.speedrunId,_that.startedAt,_that.abandonedAt,_that.games);case _:
  return null;

}
}

}

/// @nodoc


class _SpeedrunAttempt implements SpeedrunAttempt {
  const _SpeedrunAttempt({required this.id, required this.speedrunId, required this.startedAt, this.abandonedAt,  List<Attempt> games = const <Attempt>[]}): _games = games;
  

@override final  int id;
@override final  String speedrunId;
@override final  DateTime startedAt;
/// Quando o jogador desistiu da tentativa. Nulo: não desistiu.
@override final  DateTime? abandonedAt;
/// As partidas da tentativa, na ordem em que foram jogadas.
 final  List<Attempt> _games;
/// As partidas da tentativa, na ordem em que foram jogadas.
@override@JsonKey() List<Attempt> get games {
  if (_games is EqualUnmodifiableListView) return _games;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_games);
}


/// Create a copy of SpeedrunAttempt
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpeedrunAttemptCopyWith<_SpeedrunAttempt> get copyWith => __$SpeedrunAttemptCopyWithImpl<_SpeedrunAttempt>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpeedrunAttempt&&(identical(other.id, id) || other.id == id)&&(identical(other.speedrunId, speedrunId) || other.speedrunId == speedrunId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.abandonedAt, abandonedAt) || other.abandonedAt == abandonedAt)&&const DeepCollectionEquality().equals(other.games, _games));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,speedrunId,startedAt,abandonedAt,const DeepCollectionEquality().hash(_games));
}

@override
String toString() {
    return 'SpeedrunAttempt(id: $id, speedrunId: $speedrunId, startedAt: $startedAt, abandonedAt: $abandonedAt, games: $games)';
}


}

/// @nodoc
abstract mixin class _$SpeedrunAttemptCopyWith<$Res> implements $SpeedrunAttemptCopyWith<$Res> {
  factory _$SpeedrunAttemptCopyWith(_SpeedrunAttempt value, $Res Function(_SpeedrunAttempt) _then) = __$SpeedrunAttemptCopyWithImpl;
@override @useResult
$Res call({
 int id, String speedrunId, DateTime startedAt, DateTime? abandonedAt, List<Attempt> games
});




}
/// @nodoc
class __$SpeedrunAttemptCopyWithImpl<$Res>
    implements _$SpeedrunAttemptCopyWith<$Res> {
  __$SpeedrunAttemptCopyWithImpl(this._self, this._then);

  final _SpeedrunAttempt _self;
  final $Res Function(_SpeedrunAttempt) _then;

/// Create a copy of SpeedrunAttempt
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? speedrunId = null,Object? startedAt = null,Object? abandonedAt = freezed,Object? games = null,}) {
  return _then(_SpeedrunAttempt(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,speedrunId: null == speedrunId ? _self.speedrunId : speedrunId // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,abandonedAt: freezed == abandonedAt ? _self.abandonedAt : abandonedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,games: null == games ? _self._games : games // ignore: cast_nullable_to_non_nullable
as List<Attempt>,
  ));
}


}

/// @nodoc
mixin _$StageResult {

/// O tempo que o relógio do jogador gastou na etapa, somando as partidas
/// perdidas.
 Duration get time; int get wins; int get losses;
/// Create a copy of StageResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StageResultCopyWith<StageResult> get copyWith => _$StageResultCopyWithImpl<StageResult>(this as StageResult, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as StageResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StageResult&&(identical(other.time, _this.time) || other.time == _this.time)&&(identical(other.wins, _this.wins) || other.wins == _this.wins)&&(identical(other.losses, _this.losses) || other.losses == _this.losses));
}


@override
int get hashCode {
  final _this = this as StageResult;
  return Object.hash(runtimeType,_this.time,_this.wins,_this.losses);
}

@override
String toString() {
  final _this = this as StageResult;
  return 'StageResult(time: ${_this.time}, wins: ${_this.wins}, losses: ${_this.losses})';
}


}

/// @nodoc
abstract mixin class $StageResultCopyWith<$Res>  {
  factory $StageResultCopyWith(StageResult value, $Res Function(StageResult) _then) = _$StageResultCopyWithImpl;
@useResult
$Res call({
 Duration time, int wins, int losses
});




}
/// @nodoc
class _$StageResultCopyWithImpl<$Res>
    implements $StageResultCopyWith<$Res> {
  _$StageResultCopyWithImpl(this._self, this._then);

  final StageResult _self;
  final $Res Function(StageResult) _then;

/// Create a copy of StageResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? time = null,Object? wins = null,Object? losses = null,}) {
  return _then(StageResult(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as Duration,wins: null == wins ? _self.wins : wins // ignore: cast_nullable_to_non_nullable
as int,losses: null == losses ? _self.losses : losses // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StageResult].
extension StageResultPatterns on StageResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StageResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StageResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StageResult value)  $default,){
final _that = this;
switch (_that) {
case _StageResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StageResult value)?  $default,){
final _that = this;
switch (_that) {
case _StageResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Duration time,  int wins,  int losses)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StageResult() when $default != null:
return $default(_that.time,_that.wins,_that.losses);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Duration time,  int wins,  int losses)  $default,) {final _that = this;
switch (_that) {
case _StageResult():
return $default(_that.time,_that.wins,_that.losses);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Duration time,  int wins,  int losses)?  $default,) {final _that = this;
switch (_that) {
case _StageResult() when $default != null:
return $default(_that.time,_that.wins,_that.losses);case _:
  return null;

}
}

}

/// @nodoc


class _StageResult extends StageResult {
  const _StageResult({required this.time, required this.wins, required this.losses}): super._();
  

/// O tempo que o relógio do jogador gastou na etapa, somando as partidas
/// perdidas.
@override final  Duration time;
@override final  int wins;
@override final  int losses;

/// Create a copy of StageResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StageResultCopyWith<_StageResult> get copyWith => __$StageResultCopyWithImpl<_StageResult>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StageResult&&(identical(other.time, time) || other.time == time)&&(identical(other.wins, wins) || other.wins == wins)&&(identical(other.losses, losses) || other.losses == losses));
}


@override
int get hashCode {
    return Object.hash(runtimeType,time,wins,losses);
}

@override
String toString() {
    return 'StageResult(time: $time, wins: $wins, losses: $losses)';
}


}

/// @nodoc
abstract mixin class _$StageResultCopyWith<$Res> implements $StageResultCopyWith<$Res> {
  factory _$StageResultCopyWith(_StageResult value, $Res Function(_StageResult) _then) = __$StageResultCopyWithImpl;
@override @useResult
$Res call({
 Duration time, int wins, int losses
});




}
/// @nodoc
class __$StageResultCopyWithImpl<$Res>
    implements _$StageResultCopyWith<$Res> {
  __$StageResultCopyWithImpl(this._self, this._then);

  final _StageResult _self;
  final $Res Function(_StageResult) _then;

/// Create a copy of StageResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? time = null,Object? wins = null,Object? losses = null,}) {
  return _then(_StageResult(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as Duration,wins: null == wins ? _self.wins : wins // ignore: cast_nullable_to_non_nullable
as int,losses: null == losses ? _self.losses : losses // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$SpeedrunRun {

 SpeedrunAttempt get attempt;/// Uma por etapa do speedrun, na ordem.
 List<StageResult> get stages;
/// Create a copy of SpeedrunRun
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpeedrunRunCopyWith<SpeedrunRun> get copyWith => _$SpeedrunRunCopyWithImpl<SpeedrunRun>(this as SpeedrunRun, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SpeedrunRun;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpeedrunRun&&(identical(other.attempt, _this.attempt) || other.attempt == _this.attempt)&&const DeepCollectionEquality().equals(other.stages, _this.stages));
}


@override
int get hashCode {
  final _this = this as SpeedrunRun;
  return Object.hash(runtimeType,_this.attempt,const DeepCollectionEquality().hash(_this.stages));
}

@override
String toString() {
  final _this = this as SpeedrunRun;
  return 'SpeedrunRun(attempt: ${_this.attempt}, stages: ${_this.stages})';
}


}

/// @nodoc
abstract mixin class $SpeedrunRunCopyWith<$Res>  {
  factory $SpeedrunRunCopyWith(SpeedrunRun value, $Res Function(SpeedrunRun) _then) = _$SpeedrunRunCopyWithImpl;
@useResult
$Res call({
 SpeedrunAttempt attempt, List<StageResult> stages
});


$SpeedrunAttemptCopyWith<$Res> get attempt;

}
/// @nodoc
class _$SpeedrunRunCopyWithImpl<$Res>
    implements $SpeedrunRunCopyWith<$Res> {
  _$SpeedrunRunCopyWithImpl(this._self, this._then);

  final SpeedrunRun _self;
  final $Res Function(SpeedrunRun) _then;

/// Create a copy of SpeedrunRun
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? attempt = null,Object? stages = null,}) {
  return _then(SpeedrunRun(
attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as SpeedrunAttempt,stages: null == stages ? _self.stages : stages // ignore: cast_nullable_to_non_nullable
as List<StageResult>,
  ));
}
/// Create a copy of SpeedrunRun
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpeedrunAttemptCopyWith<$Res> get attempt {
  
  return $SpeedrunAttemptCopyWith<$Res>(_self.attempt, (value) {
    return _then(_self.copyWith(attempt: value));
  });
}
}


/// Adds pattern-matching-related methods to [SpeedrunRun].
extension SpeedrunRunPatterns on SpeedrunRun {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpeedrunRun value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpeedrunRun() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpeedrunRun value)  $default,){
final _that = this;
switch (_that) {
case _SpeedrunRun():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpeedrunRun value)?  $default,){
final _that = this;
switch (_that) {
case _SpeedrunRun() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SpeedrunAttempt attempt,  List<StageResult> stages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpeedrunRun() when $default != null:
return $default(_that.attempt,_that.stages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SpeedrunAttempt attempt,  List<StageResult> stages)  $default,) {final _that = this;
switch (_that) {
case _SpeedrunRun():
return $default(_that.attempt,_that.stages);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SpeedrunAttempt attempt,  List<StageResult> stages)?  $default,) {final _that = this;
switch (_that) {
case _SpeedrunRun() when $default != null:
return $default(_that.attempt,_that.stages);case _:
  return null;

}
}

}

/// @nodoc


class _SpeedrunRun extends SpeedrunRun {
  const _SpeedrunRun({required this.attempt, required  List<StageResult> stages}): _stages = stages,super._();
  

@override final  SpeedrunAttempt attempt;
/// Uma por etapa do speedrun, na ordem.
 final  List<StageResult> _stages;
/// Uma por etapa do speedrun, na ordem.
@override List<StageResult> get stages {
  if (_stages is EqualUnmodifiableListView) return _stages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stages);
}


/// Create a copy of SpeedrunRun
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpeedrunRunCopyWith<_SpeedrunRun> get copyWith => __$SpeedrunRunCopyWithImpl<_SpeedrunRun>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpeedrunRun&&(identical(other.attempt, attempt) || other.attempt == attempt)&&const DeepCollectionEquality().equals(other.stages, _stages));
}


@override
int get hashCode {
    return Object.hash(runtimeType,attempt,const DeepCollectionEquality().hash(_stages));
}

@override
String toString() {
    return 'SpeedrunRun(attempt: $attempt, stages: $stages)';
}


}

/// @nodoc
abstract mixin class _$SpeedrunRunCopyWith<$Res> implements $SpeedrunRunCopyWith<$Res> {
  factory _$SpeedrunRunCopyWith(_SpeedrunRun value, $Res Function(_SpeedrunRun) _then) = __$SpeedrunRunCopyWithImpl;
@override @useResult
$Res call({
 SpeedrunAttempt attempt, List<StageResult> stages
});


@override $SpeedrunAttemptCopyWith<$Res> get attempt;

}
/// @nodoc
class __$SpeedrunRunCopyWithImpl<$Res>
    implements _$SpeedrunRunCopyWith<$Res> {
  __$SpeedrunRunCopyWithImpl(this._self, this._then);

  final _SpeedrunRun _self;
  final $Res Function(_SpeedrunRun) _then;

/// Create a copy of SpeedrunRun
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? attempt = null,Object? stages = null,}) {
  return _then(_SpeedrunRun(
attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as SpeedrunAttempt,stages: null == stages ? _self._stages : stages // ignore: cast_nullable_to_non_nullable
as List<StageResult>,
  ));
}

/// Create a copy of SpeedrunRun
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpeedrunAttemptCopyWith<$Res> get attempt {
  
  return $SpeedrunAttemptCopyWith<$Res>(_self.attempt, (value) {
    return _then(_self.copyWith(attempt: value));
  });
}
}

/// @nodoc
mixin _$SpeedrunRecords {

/// O melhor tempo total. Nulo sem tentativa concluída.
 Duration? get best;/// O melhor tempo de cada etapa (por adversário), em qualquer tentativa
/// concluída. Nulo na etapa sem tempo.
 List<Duration?> get bestStages;/// As tentativas concluídas, da mais recente para a mais antiga.
 List<SpeedrunRun> get completed;
/// Create a copy of SpeedrunRecords
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpeedrunRecordsCopyWith<SpeedrunRecords> get copyWith => _$SpeedrunRecordsCopyWithImpl<SpeedrunRecords>(this as SpeedrunRecords, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SpeedrunRecords;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpeedrunRecords&&(identical(other.best, _this.best) || other.best == _this.best)&&const DeepCollectionEquality().equals(other.bestStages, _this.bestStages)&&const DeepCollectionEquality().equals(other.completed, _this.completed));
}


@override
int get hashCode {
  final _this = this as SpeedrunRecords;
  return Object.hash(runtimeType,_this.best,const DeepCollectionEquality().hash(_this.bestStages),const DeepCollectionEquality().hash(_this.completed));
}

@override
String toString() {
  final _this = this as SpeedrunRecords;
  return 'SpeedrunRecords(best: ${_this.best}, bestStages: ${_this.bestStages}, completed: ${_this.completed})';
}


}

/// @nodoc
abstract mixin class $SpeedrunRecordsCopyWith<$Res>  {
  factory $SpeedrunRecordsCopyWith(SpeedrunRecords value, $Res Function(SpeedrunRecords) _then) = _$SpeedrunRecordsCopyWithImpl;
@useResult
$Res call({
 Duration? best, List<Duration?> bestStages, List<SpeedrunRun> completed
});




}
/// @nodoc
class _$SpeedrunRecordsCopyWithImpl<$Res>
    implements $SpeedrunRecordsCopyWith<$Res> {
  _$SpeedrunRecordsCopyWithImpl(this._self, this._then);

  final SpeedrunRecords _self;
  final $Res Function(SpeedrunRecords) _then;

/// Create a copy of SpeedrunRecords
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? best = freezed,Object? bestStages = null,Object? completed = null,}) {
  return _then(SpeedrunRecords(
best: freezed == best ? _self.best : best // ignore: cast_nullable_to_non_nullable
as Duration?,bestStages: null == bestStages ? _self.bestStages : bestStages // ignore: cast_nullable_to_non_nullable
as List<Duration?>,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as List<SpeedrunRun>,
  ));
}

}


/// Adds pattern-matching-related methods to [SpeedrunRecords].
extension SpeedrunRecordsPatterns on SpeedrunRecords {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpeedrunRecords value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpeedrunRecords() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpeedrunRecords value)  $default,){
final _that = this;
switch (_that) {
case _SpeedrunRecords():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpeedrunRecords value)?  $default,){
final _that = this;
switch (_that) {
case _SpeedrunRecords() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Duration? best,  List<Duration?> bestStages,  List<SpeedrunRun> completed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpeedrunRecords() when $default != null:
return $default(_that.best,_that.bestStages,_that.completed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Duration? best,  List<Duration?> bestStages,  List<SpeedrunRun> completed)  $default,) {final _that = this;
switch (_that) {
case _SpeedrunRecords():
return $default(_that.best,_that.bestStages,_that.completed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Duration? best,  List<Duration?> bestStages,  List<SpeedrunRun> completed)?  $default,) {final _that = this;
switch (_that) {
case _SpeedrunRecords() when $default != null:
return $default(_that.best,_that.bestStages,_that.completed);case _:
  return null;

}
}

}

/// @nodoc


class _SpeedrunRecords implements SpeedrunRecords {
  const _SpeedrunRecords({this.best, required  List<Duration?> bestStages, required  List<SpeedrunRun> completed}): _bestStages = bestStages,_completed = completed;
  

/// O melhor tempo total. Nulo sem tentativa concluída.
@override final  Duration? best;
/// O melhor tempo de cada etapa (por adversário), em qualquer tentativa
/// concluída. Nulo na etapa sem tempo.
 final  List<Duration?> _bestStages;
/// O melhor tempo de cada etapa (por adversário), em qualquer tentativa
/// concluída. Nulo na etapa sem tempo.
@override List<Duration?> get bestStages {
  if (_bestStages is EqualUnmodifiableListView) return _bestStages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bestStages);
}

/// As tentativas concluídas, da mais recente para a mais antiga.
 final  List<SpeedrunRun> _completed;
/// As tentativas concluídas, da mais recente para a mais antiga.
@override List<SpeedrunRun> get completed {
  if (_completed is EqualUnmodifiableListView) return _completed;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_completed);
}


/// Create a copy of SpeedrunRecords
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpeedrunRecordsCopyWith<_SpeedrunRecords> get copyWith => __$SpeedrunRecordsCopyWithImpl<_SpeedrunRecords>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpeedrunRecords&&(identical(other.best, best) || other.best == best)&&const DeepCollectionEquality().equals(other.bestStages, _bestStages)&&const DeepCollectionEquality().equals(other.completed, _completed));
}


@override
int get hashCode {
    return Object.hash(runtimeType,best,const DeepCollectionEquality().hash(_bestStages),const DeepCollectionEquality().hash(_completed));
}

@override
String toString() {
    return 'SpeedrunRecords(best: $best, bestStages: $bestStages, completed: $completed)';
}


}

/// @nodoc
abstract mixin class _$SpeedrunRecordsCopyWith<$Res> implements $SpeedrunRecordsCopyWith<$Res> {
  factory _$SpeedrunRecordsCopyWith(_SpeedrunRecords value, $Res Function(_SpeedrunRecords) _then) = __$SpeedrunRecordsCopyWithImpl;
@override @useResult
$Res call({
 Duration? best, List<Duration?> bestStages, List<SpeedrunRun> completed
});




}
/// @nodoc
class __$SpeedrunRecordsCopyWithImpl<$Res>
    implements _$SpeedrunRecordsCopyWith<$Res> {
  __$SpeedrunRecordsCopyWithImpl(this._self, this._then);

  final _SpeedrunRecords _self;
  final $Res Function(_SpeedrunRecords) _then;

/// Create a copy of SpeedrunRecords
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? best = freezed,Object? bestStages = null,Object? completed = null,}) {
  return _then(_SpeedrunRecords(
best: freezed == best ? _self.best : best // ignore: cast_nullable_to_non_nullable
as Duration?,bestStages: null == bestStages ? _self._bestStages : bestStages // ignore: cast_nullable_to_non_nullable
as List<Duration?>,completed: null == completed ? _self._completed : completed // ignore: cast_nullable_to_non_nullable
as List<SpeedrunRun>,
  ));
}


}

// dart format on
