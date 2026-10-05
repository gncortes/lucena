// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'speedrun_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SpeedrunSummary {

 Speedrun get speedrun; SpeedrunRecords get records;/// A tentativa em andamento: só existe com a etapa dela no tabuleiro (o
/// app foi fechado no meio da partida).
 SpeedrunRun? get ongoing;/// As tentativas de que o jogador desistiu, da mais recente para a mais
/// antiga: o histórico mostra até onde cada uma foi.
 List<SpeedrunRun> get abandoned;
/// Create a copy of SpeedrunSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpeedrunSummaryCopyWith<SpeedrunSummary> get copyWith => _$SpeedrunSummaryCopyWithImpl<SpeedrunSummary>(this as SpeedrunSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SpeedrunSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpeedrunSummary&&(identical(other.speedrun, _this.speedrun) || other.speedrun == _this.speedrun)&&(identical(other.records, _this.records) || other.records == _this.records)&&(identical(other.ongoing, _this.ongoing) || other.ongoing == _this.ongoing)&&const DeepCollectionEquality().equals(other.abandoned, _this.abandoned));
}


@override
int get hashCode {
  final _this = this as SpeedrunSummary;
  return Object.hash(runtimeType,_this.speedrun,_this.records,_this.ongoing,const DeepCollectionEquality().hash(_this.abandoned));
}

@override
String toString() {
  final _this = this as SpeedrunSummary;
  return 'SpeedrunSummary(speedrun: ${_this.speedrun}, records: ${_this.records}, ongoing: ${_this.ongoing}, abandoned: ${_this.abandoned})';
}


}

/// @nodoc
abstract mixin class $SpeedrunSummaryCopyWith<$Res>  {
  factory $SpeedrunSummaryCopyWith(SpeedrunSummary value, $Res Function(SpeedrunSummary) _then) = _$SpeedrunSummaryCopyWithImpl;
@useResult
$Res call({
 Speedrun speedrun, SpeedrunRecords records, SpeedrunRun? ongoing, List<SpeedrunRun> abandoned
});


$SpeedrunCopyWith<$Res> get speedrun;$SpeedrunRecordsCopyWith<$Res> get records;$SpeedrunRunCopyWith<$Res>? get ongoing;

}
/// @nodoc
class _$SpeedrunSummaryCopyWithImpl<$Res>
    implements $SpeedrunSummaryCopyWith<$Res> {
  _$SpeedrunSummaryCopyWithImpl(this._self, this._then);

  final SpeedrunSummary _self;
  final $Res Function(SpeedrunSummary) _then;

/// Create a copy of SpeedrunSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? speedrun = null,Object? records = null,Object? ongoing = freezed,Object? abandoned = null,}) {
  return _then(SpeedrunSummary(
speedrun: null == speedrun ? _self.speedrun : speedrun // ignore: cast_nullable_to_non_nullable
as Speedrun,records: null == records ? _self.records : records // ignore: cast_nullable_to_non_nullable
as SpeedrunRecords,ongoing: freezed == ongoing ? _self.ongoing : ongoing // ignore: cast_nullable_to_non_nullable
as SpeedrunRun?,abandoned: null == abandoned ? _self.abandoned : abandoned // ignore: cast_nullable_to_non_nullable
as List<SpeedrunRun>,
  ));
}
/// Create a copy of SpeedrunSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpeedrunCopyWith<$Res> get speedrun {
  
  return $SpeedrunCopyWith<$Res>(_self.speedrun, (value) {
    return _then(_self.copyWith(speedrun: value));
  });
}/// Create a copy of SpeedrunSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpeedrunRecordsCopyWith<$Res> get records {
  
  return $SpeedrunRecordsCopyWith<$Res>(_self.records, (value) {
    return _then(_self.copyWith(records: value));
  });
}/// Create a copy of SpeedrunSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpeedrunRunCopyWith<$Res>? get ongoing {
    if (_self.ongoing == null) {
    return null;
  }

  return $SpeedrunRunCopyWith<$Res>(_self.ongoing!, (value) {
    return _then(_self.copyWith(ongoing: value));
  });
}
}


/// Adds pattern-matching-related methods to [SpeedrunSummary].
extension SpeedrunSummaryPatterns on SpeedrunSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpeedrunSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpeedrunSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpeedrunSummary value)  $default,){
final _that = this;
switch (_that) {
case _SpeedrunSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpeedrunSummary value)?  $default,){
final _that = this;
switch (_that) {
case _SpeedrunSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Speedrun speedrun,  SpeedrunRecords records,  SpeedrunRun? ongoing,  List<SpeedrunRun> abandoned)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpeedrunSummary() when $default != null:
return $default(_that.speedrun,_that.records,_that.ongoing,_that.abandoned);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Speedrun speedrun,  SpeedrunRecords records,  SpeedrunRun? ongoing,  List<SpeedrunRun> abandoned)  $default,) {final _that = this;
switch (_that) {
case _SpeedrunSummary():
return $default(_that.speedrun,_that.records,_that.ongoing,_that.abandoned);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Speedrun speedrun,  SpeedrunRecords records,  SpeedrunRun? ongoing,  List<SpeedrunRun> abandoned)?  $default,) {final _that = this;
switch (_that) {
case _SpeedrunSummary() when $default != null:
return $default(_that.speedrun,_that.records,_that.ongoing,_that.abandoned);case _:
  return null;

}
}

}

/// @nodoc


class _SpeedrunSummary implements SpeedrunSummary {
  const _SpeedrunSummary({required this.speedrun, required this.records, this.ongoing,  List<SpeedrunRun> abandoned = const <SpeedrunRun>[]}): _abandoned = abandoned;
  

@override final  Speedrun speedrun;
@override final  SpeedrunRecords records;
/// A tentativa em andamento: só existe com a etapa dela no tabuleiro (o
/// app foi fechado no meio da partida).
@override final  SpeedrunRun? ongoing;
/// As tentativas de que o jogador desistiu, da mais recente para a mais
/// antiga: o histórico mostra até onde cada uma foi.
 final  List<SpeedrunRun> _abandoned;
/// As tentativas de que o jogador desistiu, da mais recente para a mais
/// antiga: o histórico mostra até onde cada uma foi.
@override@JsonKey() List<SpeedrunRun> get abandoned {
  if (_abandoned is EqualUnmodifiableListView) return _abandoned;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_abandoned);
}


/// Create a copy of SpeedrunSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpeedrunSummaryCopyWith<_SpeedrunSummary> get copyWith => __$SpeedrunSummaryCopyWithImpl<_SpeedrunSummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpeedrunSummary&&(identical(other.speedrun, speedrun) || other.speedrun == speedrun)&&(identical(other.records, records) || other.records == records)&&(identical(other.ongoing, ongoing) || other.ongoing == ongoing)&&const DeepCollectionEquality().equals(other.abandoned, _abandoned));
}


@override
int get hashCode {
    return Object.hash(runtimeType,speedrun,records,ongoing,const DeepCollectionEquality().hash(_abandoned));
}

@override
String toString() {
    return 'SpeedrunSummary(speedrun: $speedrun, records: $records, ongoing: $ongoing, abandoned: $abandoned)';
}


}

/// @nodoc
abstract mixin class _$SpeedrunSummaryCopyWith<$Res> implements $SpeedrunSummaryCopyWith<$Res> {
  factory _$SpeedrunSummaryCopyWith(_SpeedrunSummary value, $Res Function(_SpeedrunSummary) _then) = __$SpeedrunSummaryCopyWithImpl;
@override @useResult
$Res call({
 Speedrun speedrun, SpeedrunRecords records, SpeedrunRun? ongoing, List<SpeedrunRun> abandoned
});


@override $SpeedrunCopyWith<$Res> get speedrun;@override $SpeedrunRecordsCopyWith<$Res> get records;@override $SpeedrunRunCopyWith<$Res>? get ongoing;

}
/// @nodoc
class __$SpeedrunSummaryCopyWithImpl<$Res>
    implements _$SpeedrunSummaryCopyWith<$Res> {
  __$SpeedrunSummaryCopyWithImpl(this._self, this._then);

  final _SpeedrunSummary _self;
  final $Res Function(_SpeedrunSummary) _then;

/// Create a copy of SpeedrunSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? speedrun = null,Object? records = null,Object? ongoing = freezed,Object? abandoned = null,}) {
  return _then(_SpeedrunSummary(
speedrun: null == speedrun ? _self.speedrun : speedrun // ignore: cast_nullable_to_non_nullable
as Speedrun,records: null == records ? _self.records : records // ignore: cast_nullable_to_non_nullable
as SpeedrunRecords,ongoing: freezed == ongoing ? _self.ongoing : ongoing // ignore: cast_nullable_to_non_nullable
as SpeedrunRun?,abandoned: null == abandoned ? _self._abandoned : abandoned // ignore: cast_nullable_to_non_nullable
as List<SpeedrunRun>,
  ));
}

/// Create a copy of SpeedrunSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpeedrunCopyWith<$Res> get speedrun {
  
  return $SpeedrunCopyWith<$Res>(_self.speedrun, (value) {
    return _then(_self.copyWith(speedrun: value));
  });
}/// Create a copy of SpeedrunSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpeedrunRecordsCopyWith<$Res> get records {
  
  return $SpeedrunRecordsCopyWith<$Res>(_self.records, (value) {
    return _then(_self.copyWith(records: value));
  });
}/// Create a copy of SpeedrunSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpeedrunRunCopyWith<$Res>? get ongoing {
    if (_self.ongoing == null) {
    return null;
  }

  return $SpeedrunRunCopyWith<$Res>(_self.ongoing!, (value) {
    return _then(_self.copyWith(ongoing: value));
  });
}
}

/// @nodoc
mixin _$SpeedrunState {

/// Todos os speedruns. Nulo enquanto são lidos.
 List<SpeedrunSummary>? get all;/// O speedrun aberto (tela dele ou de uma tentativa).
 SpeedrunSummary? get selected;/// A tentativa aberta, já contada.
 SpeedrunRun? get run;/// O recorde de antes de [run] terminar. Nulo se não havia.
 Duration? get previousBest;/// O ritmo da lista: cada ritmo tem os seus speedruns e recordes.
 TimeControl get pace;/// Os personagens, um por nível do Maia.
 List<Character> get characters;
/// Create a copy of SpeedrunState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpeedrunStateCopyWith<SpeedrunState> get copyWith => _$SpeedrunStateCopyWithImpl<SpeedrunState>(this as SpeedrunState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SpeedrunState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpeedrunState&&const DeepCollectionEquality().equals(other.all, _this.all)&&(identical(other.selected, _this.selected) || other.selected == _this.selected)&&(identical(other.run, _this.run) || other.run == _this.run)&&(identical(other.previousBest, _this.previousBest) || other.previousBest == _this.previousBest)&&(identical(other.pace, _this.pace) || other.pace == _this.pace)&&const DeepCollectionEquality().equals(other.characters, _this.characters));
}


@override
int get hashCode {
  final _this = this as SpeedrunState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.all),_this.selected,_this.run,_this.previousBest,_this.pace,const DeepCollectionEquality().hash(_this.characters));
}

@override
String toString() {
  final _this = this as SpeedrunState;
  return 'SpeedrunState(all: ${_this.all}, selected: ${_this.selected}, run: ${_this.run}, previousBest: ${_this.previousBest}, pace: ${_this.pace}, characters: ${_this.characters})';
}


}

/// @nodoc
abstract mixin class $SpeedrunStateCopyWith<$Res>  {
  factory $SpeedrunStateCopyWith(SpeedrunState value, $Res Function(SpeedrunState) _then) = _$SpeedrunStateCopyWithImpl;
@useResult
$Res call({
 List<SpeedrunSummary>? all, SpeedrunSummary? selected, SpeedrunRun? run, Duration? previousBest, TimeControl pace, List<Character> characters
});


$SpeedrunSummaryCopyWith<$Res>? get selected;$SpeedrunRunCopyWith<$Res>? get run;$TimeControlCopyWith<$Res> get pace;

}
/// @nodoc
class _$SpeedrunStateCopyWithImpl<$Res>
    implements $SpeedrunStateCopyWith<$Res> {
  _$SpeedrunStateCopyWithImpl(this._self, this._then);

  final SpeedrunState _self;
  final $Res Function(SpeedrunState) _then;

/// Create a copy of SpeedrunState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? all = freezed,Object? selected = freezed,Object? run = freezed,Object? previousBest = freezed,Object? pace = null,Object? characters = null,}) {
  return _then(SpeedrunState(
all: freezed == all ? _self.all : all // ignore: cast_nullable_to_non_nullable
as List<SpeedrunSummary>?,selected: freezed == selected ? _self.selected : selected // ignore: cast_nullable_to_non_nullable
as SpeedrunSummary?,run: freezed == run ? _self.run : run // ignore: cast_nullable_to_non_nullable
as SpeedrunRun?,previousBest: freezed == previousBest ? _self.previousBest : previousBest // ignore: cast_nullable_to_non_nullable
as Duration?,pace: null == pace ? _self.pace : pace // ignore: cast_nullable_to_non_nullable
as TimeControl,characters: null == characters ? _self.characters : characters // ignore: cast_nullable_to_non_nullable
as List<Character>,
  ));
}
/// Create a copy of SpeedrunState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpeedrunSummaryCopyWith<$Res>? get selected {
    if (_self.selected == null) {
    return null;
  }

  return $SpeedrunSummaryCopyWith<$Res>(_self.selected!, (value) {
    return _then(_self.copyWith(selected: value));
  });
}/// Create a copy of SpeedrunState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpeedrunRunCopyWith<$Res>? get run {
    if (_self.run == null) {
    return null;
  }

  return $SpeedrunRunCopyWith<$Res>(_self.run!, (value) {
    return _then(_self.copyWith(run: value));
  });
}/// Create a copy of SpeedrunState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeControlCopyWith<$Res> get pace {
  
  return $TimeControlCopyWith<$Res>(_self.pace, (value) {
    return _then(_self.copyWith(pace: value));
  });
}
}


/// Adds pattern-matching-related methods to [SpeedrunState].
extension SpeedrunStatePatterns on SpeedrunState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpeedrunState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpeedrunState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpeedrunState value)  $default,){
final _that = this;
switch (_that) {
case _SpeedrunState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpeedrunState value)?  $default,){
final _that = this;
switch (_that) {
case _SpeedrunState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SpeedrunSummary>? all,  SpeedrunSummary? selected,  SpeedrunRun? run,  Duration? previousBest,  TimeControl pace,  List<Character> characters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpeedrunState() when $default != null:
return $default(_that.all,_that.selected,_that.run,_that.previousBest,_that.pace,_that.characters);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SpeedrunSummary>? all,  SpeedrunSummary? selected,  SpeedrunRun? run,  Duration? previousBest,  TimeControl pace,  List<Character> characters)  $default,) {final _that = this;
switch (_that) {
case _SpeedrunState():
return $default(_that.all,_that.selected,_that.run,_that.previousBest,_that.pace,_that.characters);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SpeedrunSummary>? all,  SpeedrunSummary? selected,  SpeedrunRun? run,  Duration? previousBest,  TimeControl pace,  List<Character> characters)?  $default,) {final _that = this;
switch (_that) {
case _SpeedrunState() when $default != null:
return $default(_that.all,_that.selected,_that.run,_that.previousBest,_that.pace,_that.characters);case _:
  return null;

}
}

}

/// @nodoc


class _SpeedrunState implements SpeedrunState {
  const _SpeedrunState({ List<SpeedrunSummary>? all, this.selected, this.run, this.previousBest, this.pace = SpeedrunPaces.standard,  List<Character> characters = const <Character>[]}): _all = all,_characters = characters;
  

/// Todos os speedruns. Nulo enquanto são lidos.
 final  List<SpeedrunSummary>? _all;
/// Todos os speedruns. Nulo enquanto são lidos.
@override List<SpeedrunSummary>? get all {
  final value = _all;
  if (value == null) return null;
  if (_all is EqualUnmodifiableListView) return _all;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// O speedrun aberto (tela dele ou de uma tentativa).
@override final  SpeedrunSummary? selected;
/// A tentativa aberta, já contada.
@override final  SpeedrunRun? run;
/// O recorde de antes de [run] terminar. Nulo se não havia.
@override final  Duration? previousBest;
/// O ritmo da lista: cada ritmo tem os seus speedruns e recordes.
@override@JsonKey() final  TimeControl pace;
/// Os personagens, um por nível do Maia.
 final  List<Character> _characters;
/// Os personagens, um por nível do Maia.
@override@JsonKey() List<Character> get characters {
  if (_characters is EqualUnmodifiableListView) return _characters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_characters);
}


/// Create a copy of SpeedrunState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpeedrunStateCopyWith<_SpeedrunState> get copyWith => __$SpeedrunStateCopyWithImpl<_SpeedrunState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpeedrunState&&const DeepCollectionEquality().equals(other.all, _all)&&(identical(other.selected, selected) || other.selected == selected)&&(identical(other.run, run) || other.run == run)&&(identical(other.previousBest, previousBest) || other.previousBest == previousBest)&&(identical(other.pace, pace) || other.pace == pace)&&const DeepCollectionEquality().equals(other.characters, _characters));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_all),selected,run,previousBest,pace,const DeepCollectionEquality().hash(_characters));
}

@override
String toString() {
    return 'SpeedrunState(all: $all, selected: $selected, run: $run, previousBest: $previousBest, pace: $pace, characters: $characters)';
}


}

/// @nodoc
abstract mixin class _$SpeedrunStateCopyWith<$Res> implements $SpeedrunStateCopyWith<$Res> {
  factory _$SpeedrunStateCopyWith(_SpeedrunState value, $Res Function(_SpeedrunState) _then) = __$SpeedrunStateCopyWithImpl;
@override @useResult
$Res call({
 List<SpeedrunSummary>? all, SpeedrunSummary? selected, SpeedrunRun? run, Duration? previousBest, TimeControl pace, List<Character> characters
});


@override $SpeedrunSummaryCopyWith<$Res>? get selected;@override $SpeedrunRunCopyWith<$Res>? get run;@override $TimeControlCopyWith<$Res> get pace;

}
/// @nodoc
class __$SpeedrunStateCopyWithImpl<$Res>
    implements _$SpeedrunStateCopyWith<$Res> {
  __$SpeedrunStateCopyWithImpl(this._self, this._then);

  final _SpeedrunState _self;
  final $Res Function(_SpeedrunState) _then;

/// Create a copy of SpeedrunState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? all = freezed,Object? selected = freezed,Object? run = freezed,Object? previousBest = freezed,Object? pace = null,Object? characters = null,}) {
  return _then(_SpeedrunState(
all: freezed == all ? _self._all : all // ignore: cast_nullable_to_non_nullable
as List<SpeedrunSummary>?,selected: freezed == selected ? _self.selected : selected // ignore: cast_nullable_to_non_nullable
as SpeedrunSummary?,run: freezed == run ? _self.run : run // ignore: cast_nullable_to_non_nullable
as SpeedrunRun?,previousBest: freezed == previousBest ? _self.previousBest : previousBest // ignore: cast_nullable_to_non_nullable
as Duration?,pace: null == pace ? _self.pace : pace // ignore: cast_nullable_to_non_nullable
as TimeControl,characters: null == characters ? _self._characters : characters // ignore: cast_nullable_to_non_nullable
as List<Character>,
  ));
}

/// Create a copy of SpeedrunState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpeedrunSummaryCopyWith<$Res>? get selected {
    if (_self.selected == null) {
    return null;
  }

  return $SpeedrunSummaryCopyWith<$Res>(_self.selected!, (value) {
    return _then(_self.copyWith(selected: value));
  });
}/// Create a copy of SpeedrunState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpeedrunRunCopyWith<$Res>? get run {
    if (_self.run == null) {
    return null;
  }

  return $SpeedrunRunCopyWith<$Res>(_self.run!, (value) {
    return _then(_self.copyWith(run: value));
  });
}/// Create a copy of SpeedrunState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeControlCopyWith<$Res> get pace {
  
  return $TimeControlCopyWith<$Res>(_self.pace, (value) {
    return _then(_self.copyWith(pace: value));
  });
}
}

// dart format on
