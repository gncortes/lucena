// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'speedrun_history_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SpeedrunHistoryRun {

 SpeedrunRun get run; SpeedrunRunEnd get end;/// A última partida (concluída) ou a desistência.
 DateTime get endedAt;/// A tentativa do recorde.
 bool get record;/// O rating que a conclusão deu: só na primeira, a que gerou o bônus.
 int? get bonus;
/// Create a copy of SpeedrunHistoryRun
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpeedrunHistoryRunCopyWith<SpeedrunHistoryRun> get copyWith => _$SpeedrunHistoryRunCopyWithImpl<SpeedrunHistoryRun>(this as SpeedrunHistoryRun, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SpeedrunHistoryRun;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpeedrunHistoryRun&&(identical(other.run, _this.run) || other.run == _this.run)&&(identical(other.end, _this.end) || other.end == _this.end)&&(identical(other.endedAt, _this.endedAt) || other.endedAt == _this.endedAt)&&(identical(other.record, _this.record) || other.record == _this.record)&&(identical(other.bonus, _this.bonus) || other.bonus == _this.bonus));
}


@override
int get hashCode {
  final _this = this as SpeedrunHistoryRun;
  return Object.hash(runtimeType,_this.run,_this.end,_this.endedAt,_this.record,_this.bonus);
}

@override
String toString() {
  final _this = this as SpeedrunHistoryRun;
  return 'SpeedrunHistoryRun(run: ${_this.run}, end: ${_this.end}, endedAt: ${_this.endedAt}, record: ${_this.record}, bonus: ${_this.bonus})';
}


}

/// @nodoc
abstract mixin class $SpeedrunHistoryRunCopyWith<$Res>  {
  factory $SpeedrunHistoryRunCopyWith(SpeedrunHistoryRun value, $Res Function(SpeedrunHistoryRun) _then) = _$SpeedrunHistoryRunCopyWithImpl;
@useResult
$Res call({
 SpeedrunRun run, SpeedrunRunEnd end, DateTime endedAt, bool record, int? bonus
});


$SpeedrunRunCopyWith<$Res> get run;

}
/// @nodoc
class _$SpeedrunHistoryRunCopyWithImpl<$Res>
    implements $SpeedrunHistoryRunCopyWith<$Res> {
  _$SpeedrunHistoryRunCopyWithImpl(this._self, this._then);

  final SpeedrunHistoryRun _self;
  final $Res Function(SpeedrunHistoryRun) _then;

/// Create a copy of SpeedrunHistoryRun
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? run = null,Object? end = null,Object? endedAt = null,Object? record = null,Object? bonus = freezed,}) {
  return _then(SpeedrunHistoryRun(
run: null == run ? _self.run : run // ignore: cast_nullable_to_non_nullable
as SpeedrunRun,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as SpeedrunRunEnd,endedAt: null == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime,record: null == record ? _self.record : record // ignore: cast_nullable_to_non_nullable
as bool,bonus: freezed == bonus ? _self.bonus : bonus // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of SpeedrunHistoryRun
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpeedrunRunCopyWith<$Res> get run {
  
  return $SpeedrunRunCopyWith<$Res>(_self.run, (value) {
    return _then(_self.copyWith(run: value));
  });
}
}


/// Adds pattern-matching-related methods to [SpeedrunHistoryRun].
extension SpeedrunHistoryRunPatterns on SpeedrunHistoryRun {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpeedrunHistoryRun value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpeedrunHistoryRun() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpeedrunHistoryRun value)  $default,){
final _that = this;
switch (_that) {
case _SpeedrunHistoryRun():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpeedrunHistoryRun value)?  $default,){
final _that = this;
switch (_that) {
case _SpeedrunHistoryRun() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SpeedrunRun run,  SpeedrunRunEnd end,  DateTime endedAt,  bool record,  int? bonus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpeedrunHistoryRun() when $default != null:
return $default(_that.run,_that.end,_that.endedAt,_that.record,_that.bonus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SpeedrunRun run,  SpeedrunRunEnd end,  DateTime endedAt,  bool record,  int? bonus)  $default,) {final _that = this;
switch (_that) {
case _SpeedrunHistoryRun():
return $default(_that.run,_that.end,_that.endedAt,_that.record,_that.bonus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SpeedrunRun run,  SpeedrunRunEnd end,  DateTime endedAt,  bool record,  int? bonus)?  $default,) {final _that = this;
switch (_that) {
case _SpeedrunHistoryRun() when $default != null:
return $default(_that.run,_that.end,_that.endedAt,_that.record,_that.bonus);case _:
  return null;

}
}

}

/// @nodoc


class _SpeedrunHistoryRun extends SpeedrunHistoryRun {
  const _SpeedrunHistoryRun({required this.run, required this.end, required this.endedAt, this.record = false, this.bonus}): super._();
  

@override final  SpeedrunRun run;
@override final  SpeedrunRunEnd end;
/// A última partida (concluída) ou a desistência.
@override final  DateTime endedAt;
/// A tentativa do recorde.
@override@JsonKey() final  bool record;
/// O rating que a conclusão deu: só na primeira, a que gerou o bônus.
@override final  int? bonus;

/// Create a copy of SpeedrunHistoryRun
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpeedrunHistoryRunCopyWith<_SpeedrunHistoryRun> get copyWith => __$SpeedrunHistoryRunCopyWithImpl<_SpeedrunHistoryRun>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpeedrunHistoryRun&&(identical(other.run, run) || other.run == run)&&(identical(other.end, end) || other.end == end)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.record, record) || other.record == record)&&(identical(other.bonus, bonus) || other.bonus == bonus));
}


@override
int get hashCode {
    return Object.hash(runtimeType,run,end,endedAt,record,bonus);
}

@override
String toString() {
    return 'SpeedrunHistoryRun(run: $run, end: $end, endedAt: $endedAt, record: $record, bonus: $bonus)';
}


}

/// @nodoc
abstract mixin class _$SpeedrunHistoryRunCopyWith<$Res> implements $SpeedrunHistoryRunCopyWith<$Res> {
  factory _$SpeedrunHistoryRunCopyWith(_SpeedrunHistoryRun value, $Res Function(_SpeedrunHistoryRun) _then) = __$SpeedrunHistoryRunCopyWithImpl;
@override @useResult
$Res call({
 SpeedrunRun run, SpeedrunRunEnd end, DateTime endedAt, bool record, int? bonus
});


@override $SpeedrunRunCopyWith<$Res> get run;

}
/// @nodoc
class __$SpeedrunHistoryRunCopyWithImpl<$Res>
    implements _$SpeedrunHistoryRunCopyWith<$Res> {
  __$SpeedrunHistoryRunCopyWithImpl(this._self, this._then);

  final _SpeedrunHistoryRun _self;
  final $Res Function(_SpeedrunHistoryRun) _then;

/// Create a copy of SpeedrunHistoryRun
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? run = null,Object? end = null,Object? endedAt = null,Object? record = null,Object? bonus = freezed,}) {
  return _then(_SpeedrunHistoryRun(
run: null == run ? _self.run : run // ignore: cast_nullable_to_non_nullable
as SpeedrunRun,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as SpeedrunRunEnd,endedAt: null == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime,record: null == record ? _self.record : record // ignore: cast_nullable_to_non_nullable
as bool,bonus: freezed == bonus ? _self.bonus : bonus // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of SpeedrunHistoryRun
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpeedrunRunCopyWith<$Res> get run {
  
  return $SpeedrunRunCopyWith<$Res>(_self.run, (value) {
    return _then(_self.copyWith(run: value));
  });
}
}

/// @nodoc
mixin _$SpeedrunHistoryState {

/// O speedrun, já no ritmo. Nulo enquanto é lido ou se o id não existe.
 Speedrun? get speedrun;/// O melhor tempo e quando foi feito. Nulos sem conclusão.
 Duration? get best; DateTime? get bestAt;/// As tentativas terminadas, da mais recente para a mais antiga. A em
/// andamento fica só no detalhe.
 List<SpeedrunHistoryRun> get runs;/// Os personagens, para a foto e o nome do speedrun.
 List<Character> get characters; bool get loaded;/// O ano de hoje: a data do recorde só mostra o ano fora dele.
 int? get year;
/// Create a copy of SpeedrunHistoryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpeedrunHistoryStateCopyWith<SpeedrunHistoryState> get copyWith => _$SpeedrunHistoryStateCopyWithImpl<SpeedrunHistoryState>(this as SpeedrunHistoryState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SpeedrunHistoryState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpeedrunHistoryState&&(identical(other.speedrun, _this.speedrun) || other.speedrun == _this.speedrun)&&(identical(other.best, _this.best) || other.best == _this.best)&&(identical(other.bestAt, _this.bestAt) || other.bestAt == _this.bestAt)&&const DeepCollectionEquality().equals(other.runs, _this.runs)&&const DeepCollectionEquality().equals(other.characters, _this.characters)&&(identical(other.loaded, _this.loaded) || other.loaded == _this.loaded)&&(identical(other.year, _this.year) || other.year == _this.year));
}


@override
int get hashCode {
  final _this = this as SpeedrunHistoryState;
  return Object.hash(runtimeType,_this.speedrun,_this.best,_this.bestAt,const DeepCollectionEquality().hash(_this.runs),const DeepCollectionEquality().hash(_this.characters),_this.loaded,_this.year);
}

@override
String toString() {
  final _this = this as SpeedrunHistoryState;
  return 'SpeedrunHistoryState(speedrun: ${_this.speedrun}, best: ${_this.best}, bestAt: ${_this.bestAt}, runs: ${_this.runs}, characters: ${_this.characters}, loaded: ${_this.loaded}, year: ${_this.year})';
}


}

/// @nodoc
abstract mixin class $SpeedrunHistoryStateCopyWith<$Res>  {
  factory $SpeedrunHistoryStateCopyWith(SpeedrunHistoryState value, $Res Function(SpeedrunHistoryState) _then) = _$SpeedrunHistoryStateCopyWithImpl;
@useResult
$Res call({
 Speedrun? speedrun, Duration? best, DateTime? bestAt, List<SpeedrunHistoryRun> runs, List<Character> characters, bool loaded, int? year
});


$SpeedrunCopyWith<$Res>? get speedrun;

}
/// @nodoc
class _$SpeedrunHistoryStateCopyWithImpl<$Res>
    implements $SpeedrunHistoryStateCopyWith<$Res> {
  _$SpeedrunHistoryStateCopyWithImpl(this._self, this._then);

  final SpeedrunHistoryState _self;
  final $Res Function(SpeedrunHistoryState) _then;

/// Create a copy of SpeedrunHistoryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? speedrun = freezed,Object? best = freezed,Object? bestAt = freezed,Object? runs = null,Object? characters = null,Object? loaded = null,Object? year = freezed,}) {
  return _then(SpeedrunHistoryState(
speedrun: freezed == speedrun ? _self.speedrun : speedrun // ignore: cast_nullable_to_non_nullable
as Speedrun?,best: freezed == best ? _self.best : best // ignore: cast_nullable_to_non_nullable
as Duration?,bestAt: freezed == bestAt ? _self.bestAt : bestAt // ignore: cast_nullable_to_non_nullable
as DateTime?,runs: null == runs ? _self.runs : runs // ignore: cast_nullable_to_non_nullable
as List<SpeedrunHistoryRun>,characters: null == characters ? _self.characters : characters // ignore: cast_nullable_to_non_nullable
as List<Character>,loaded: null == loaded ? _self.loaded : loaded // ignore: cast_nullable_to_non_nullable
as bool,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of SpeedrunHistoryState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpeedrunCopyWith<$Res>? get speedrun {
    if (_self.speedrun == null) {
    return null;
  }

  return $SpeedrunCopyWith<$Res>(_self.speedrun!, (value) {
    return _then(_self.copyWith(speedrun: value));
  });
}
}


/// Adds pattern-matching-related methods to [SpeedrunHistoryState].
extension SpeedrunHistoryStatePatterns on SpeedrunHistoryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpeedrunHistoryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpeedrunHistoryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpeedrunHistoryState value)  $default,){
final _that = this;
switch (_that) {
case _SpeedrunHistoryState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpeedrunHistoryState value)?  $default,){
final _that = this;
switch (_that) {
case _SpeedrunHistoryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Speedrun? speedrun,  Duration? best,  DateTime? bestAt,  List<SpeedrunHistoryRun> runs,  List<Character> characters,  bool loaded,  int? year)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpeedrunHistoryState() when $default != null:
return $default(_that.speedrun,_that.best,_that.bestAt,_that.runs,_that.characters,_that.loaded,_that.year);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Speedrun? speedrun,  Duration? best,  DateTime? bestAt,  List<SpeedrunHistoryRun> runs,  List<Character> characters,  bool loaded,  int? year)  $default,) {final _that = this;
switch (_that) {
case _SpeedrunHistoryState():
return $default(_that.speedrun,_that.best,_that.bestAt,_that.runs,_that.characters,_that.loaded,_that.year);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Speedrun? speedrun,  Duration? best,  DateTime? bestAt,  List<SpeedrunHistoryRun> runs,  List<Character> characters,  bool loaded,  int? year)?  $default,) {final _that = this;
switch (_that) {
case _SpeedrunHistoryState() when $default != null:
return $default(_that.speedrun,_that.best,_that.bestAt,_that.runs,_that.characters,_that.loaded,_that.year);case _:
  return null;

}
}

}

/// @nodoc


class _SpeedrunHistoryState extends SpeedrunHistoryState {
  const _SpeedrunHistoryState({this.speedrun, this.best, this.bestAt,  List<SpeedrunHistoryRun> runs = const <SpeedrunHistoryRun>[],  List<Character> characters = const <Character>[], this.loaded = false, this.year}): _runs = runs,_characters = characters,super._();
  

/// O speedrun, já no ritmo. Nulo enquanto é lido ou se o id não existe.
@override final  Speedrun? speedrun;
/// O melhor tempo e quando foi feito. Nulos sem conclusão.
@override final  Duration? best;
@override final  DateTime? bestAt;
/// As tentativas terminadas, da mais recente para a mais antiga. A em
/// andamento fica só no detalhe.
 final  List<SpeedrunHistoryRun> _runs;
/// As tentativas terminadas, da mais recente para a mais antiga. A em
/// andamento fica só no detalhe.
@override@JsonKey() List<SpeedrunHistoryRun> get runs {
  if (_runs is EqualUnmodifiableListView) return _runs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_runs);
}

/// Os personagens, para a foto e o nome do speedrun.
 final  List<Character> _characters;
/// Os personagens, para a foto e o nome do speedrun.
@override@JsonKey() List<Character> get characters {
  if (_characters is EqualUnmodifiableListView) return _characters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_characters);
}

@override@JsonKey() final  bool loaded;
/// O ano de hoje: a data do recorde só mostra o ano fora dele.
@override final  int? year;

/// Create a copy of SpeedrunHistoryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpeedrunHistoryStateCopyWith<_SpeedrunHistoryState> get copyWith => __$SpeedrunHistoryStateCopyWithImpl<_SpeedrunHistoryState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpeedrunHistoryState&&(identical(other.speedrun, speedrun) || other.speedrun == speedrun)&&(identical(other.best, best) || other.best == best)&&(identical(other.bestAt, bestAt) || other.bestAt == bestAt)&&const DeepCollectionEquality().equals(other.runs, _runs)&&const DeepCollectionEquality().equals(other.characters, _characters)&&(identical(other.loaded, loaded) || other.loaded == loaded)&&(identical(other.year, year) || other.year == year));
}


@override
int get hashCode {
    return Object.hash(runtimeType,speedrun,best,bestAt,const DeepCollectionEquality().hash(_runs),const DeepCollectionEquality().hash(_characters),loaded,year);
}

@override
String toString() {
    return 'SpeedrunHistoryState(speedrun: $speedrun, best: $best, bestAt: $bestAt, runs: $runs, characters: $characters, loaded: $loaded, year: $year)';
}


}

/// @nodoc
abstract mixin class _$SpeedrunHistoryStateCopyWith<$Res> implements $SpeedrunHistoryStateCopyWith<$Res> {
  factory _$SpeedrunHistoryStateCopyWith(_SpeedrunHistoryState value, $Res Function(_SpeedrunHistoryState) _then) = __$SpeedrunHistoryStateCopyWithImpl;
@override @useResult
$Res call({
 Speedrun? speedrun, Duration? best, DateTime? bestAt, List<SpeedrunHistoryRun> runs, List<Character> characters, bool loaded, int? year
});


@override $SpeedrunCopyWith<$Res>? get speedrun;

}
/// @nodoc
class __$SpeedrunHistoryStateCopyWithImpl<$Res>
    implements _$SpeedrunHistoryStateCopyWith<$Res> {
  __$SpeedrunHistoryStateCopyWithImpl(this._self, this._then);

  final _SpeedrunHistoryState _self;
  final $Res Function(_SpeedrunHistoryState) _then;

/// Create a copy of SpeedrunHistoryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? speedrun = freezed,Object? best = freezed,Object? bestAt = freezed,Object? runs = null,Object? characters = null,Object? loaded = null,Object? year = freezed,}) {
  return _then(_SpeedrunHistoryState(
speedrun: freezed == speedrun ? _self.speedrun : speedrun // ignore: cast_nullable_to_non_nullable
as Speedrun?,best: freezed == best ? _self.best : best // ignore: cast_nullable_to_non_nullable
as Duration?,bestAt: freezed == bestAt ? _self.bestAt : bestAt // ignore: cast_nullable_to_non_nullable
as DateTime?,runs: null == runs ? _self._runs : runs // ignore: cast_nullable_to_non_nullable
as List<SpeedrunHistoryRun>,characters: null == characters ? _self._characters : characters // ignore: cast_nullable_to_non_nullable
as List<Character>,loaded: null == loaded ? _self.loaded : loaded // ignore: cast_nullable_to_non_nullable
as bool,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of SpeedrunHistoryState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpeedrunCopyWith<$Res>? get speedrun {
    if (_self.speedrun == null) {
    return null;
  }

  return $SpeedrunCopyWith<$Res>(_self.speedrun!, (value) {
    return _then(_self.copyWith(speedrun: value));
  });
}
}

// dart format on
