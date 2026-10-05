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

 Speedrun get speedrun; SpeedrunRecords get records;/// A tentativa em andamento, se há.
 SpeedrunRun? get ongoing;
/// Create a copy of SpeedrunSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpeedrunSummaryCopyWith<SpeedrunSummary> get copyWith => _$SpeedrunSummaryCopyWithImpl<SpeedrunSummary>(this as SpeedrunSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SpeedrunSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpeedrunSummary&&(identical(other.speedrun, _this.speedrun) || other.speedrun == _this.speedrun)&&(identical(other.records, _this.records) || other.records == _this.records)&&(identical(other.ongoing, _this.ongoing) || other.ongoing == _this.ongoing));
}


@override
int get hashCode {
  final _this = this as SpeedrunSummary;
  return Object.hash(runtimeType,_this.speedrun,_this.records,_this.ongoing);
}

@override
String toString() {
  final _this = this as SpeedrunSummary;
  return 'SpeedrunSummary(speedrun: ${_this.speedrun}, records: ${_this.records}, ongoing: ${_this.ongoing})';
}


}

/// @nodoc
abstract mixin class $SpeedrunSummaryCopyWith<$Res>  {
  factory $SpeedrunSummaryCopyWith(SpeedrunSummary value, $Res Function(SpeedrunSummary) _then) = _$SpeedrunSummaryCopyWithImpl;
@useResult
$Res call({
 Speedrun speedrun, SpeedrunRecords records, SpeedrunRun? ongoing
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
@pragma('vm:prefer-inline') @override $Res call({Object? speedrun = null,Object? records = null,Object? ongoing = freezed,}) {
  return _then(SpeedrunSummary(
speedrun: null == speedrun ? _self.speedrun : speedrun // ignore: cast_nullable_to_non_nullable
as Speedrun,records: null == records ? _self.records : records // ignore: cast_nullable_to_non_nullable
as SpeedrunRecords,ongoing: freezed == ongoing ? _self.ongoing : ongoing // ignore: cast_nullable_to_non_nullable
as SpeedrunRun?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Speedrun speedrun,  SpeedrunRecords records,  SpeedrunRun? ongoing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpeedrunSummary() when $default != null:
return $default(_that.speedrun,_that.records,_that.ongoing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Speedrun speedrun,  SpeedrunRecords records,  SpeedrunRun? ongoing)  $default,) {final _that = this;
switch (_that) {
case _SpeedrunSummary():
return $default(_that.speedrun,_that.records,_that.ongoing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Speedrun speedrun,  SpeedrunRecords records,  SpeedrunRun? ongoing)?  $default,) {final _that = this;
switch (_that) {
case _SpeedrunSummary() when $default != null:
return $default(_that.speedrun,_that.records,_that.ongoing);case _:
  return null;

}
}

}

/// @nodoc


class _SpeedrunSummary implements SpeedrunSummary {
  const _SpeedrunSummary({required this.speedrun, required this.records, this.ongoing});
  

@override final  Speedrun speedrun;
@override final  SpeedrunRecords records;
/// A tentativa em andamento, se há.
@override final  SpeedrunRun? ongoing;

/// Create a copy of SpeedrunSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpeedrunSummaryCopyWith<_SpeedrunSummary> get copyWith => __$SpeedrunSummaryCopyWithImpl<_SpeedrunSummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpeedrunSummary&&(identical(other.speedrun, speedrun) || other.speedrun == speedrun)&&(identical(other.records, records) || other.records == records)&&(identical(other.ongoing, ongoing) || other.ongoing == ongoing));
}


@override
int get hashCode {
    return Object.hash(runtimeType,speedrun,records,ongoing);
}

@override
String toString() {
    return 'SpeedrunSummary(speedrun: $speedrun, records: $records, ongoing: $ongoing)';
}


}

/// @nodoc
abstract mixin class _$SpeedrunSummaryCopyWith<$Res> implements $SpeedrunSummaryCopyWith<$Res> {
  factory _$SpeedrunSummaryCopyWith(_SpeedrunSummary value, $Res Function(_SpeedrunSummary) _then) = __$SpeedrunSummaryCopyWithImpl;
@override @useResult
$Res call({
 Speedrun speedrun, SpeedrunRecords records, SpeedrunRun? ongoing
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
@override @pragma('vm:prefer-inline') $Res call({Object? speedrun = null,Object? records = null,Object? ongoing = freezed,}) {
  return _then(_SpeedrunSummary(
speedrun: null == speedrun ? _self.speedrun : speedrun // ignore: cast_nullable_to_non_nullable
as Speedrun,records: null == records ? _self.records : records // ignore: cast_nullable_to_non_nullable
as SpeedrunRecords,ongoing: freezed == ongoing ? _self.ongoing : ongoing // ignore: cast_nullable_to_non_nullable
as SpeedrunRun?,
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
 Duration? get previousBest;/// A partida em andamento é uma etapa de [run]: jogar continua ela.
 bool get gameOngoing;
/// Create a copy of SpeedrunState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpeedrunStateCopyWith<SpeedrunState> get copyWith => _$SpeedrunStateCopyWithImpl<SpeedrunState>(this as SpeedrunState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SpeedrunState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpeedrunState&&const DeepCollectionEquality().equals(other.all, _this.all)&&(identical(other.selected, _this.selected) || other.selected == _this.selected)&&(identical(other.run, _this.run) || other.run == _this.run)&&(identical(other.previousBest, _this.previousBest) || other.previousBest == _this.previousBest)&&(identical(other.gameOngoing, _this.gameOngoing) || other.gameOngoing == _this.gameOngoing));
}


@override
int get hashCode {
  final _this = this as SpeedrunState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.all),_this.selected,_this.run,_this.previousBest,_this.gameOngoing);
}

@override
String toString() {
  final _this = this as SpeedrunState;
  return 'SpeedrunState(all: ${_this.all}, selected: ${_this.selected}, run: ${_this.run}, previousBest: ${_this.previousBest}, gameOngoing: ${_this.gameOngoing})';
}


}

/// @nodoc
abstract mixin class $SpeedrunStateCopyWith<$Res>  {
  factory $SpeedrunStateCopyWith(SpeedrunState value, $Res Function(SpeedrunState) _then) = _$SpeedrunStateCopyWithImpl;
@useResult
$Res call({
 List<SpeedrunSummary>? all, SpeedrunSummary? selected, SpeedrunRun? run, Duration? previousBest, bool gameOngoing
});


$SpeedrunSummaryCopyWith<$Res>? get selected;$SpeedrunRunCopyWith<$Res>? get run;

}
/// @nodoc
class _$SpeedrunStateCopyWithImpl<$Res>
    implements $SpeedrunStateCopyWith<$Res> {
  _$SpeedrunStateCopyWithImpl(this._self, this._then);

  final SpeedrunState _self;
  final $Res Function(SpeedrunState) _then;

/// Create a copy of SpeedrunState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? all = freezed,Object? selected = freezed,Object? run = freezed,Object? previousBest = freezed,Object? gameOngoing = null,}) {
  return _then(SpeedrunState(
all: freezed == all ? _self.all : all // ignore: cast_nullable_to_non_nullable
as List<SpeedrunSummary>?,selected: freezed == selected ? _self.selected : selected // ignore: cast_nullable_to_non_nullable
as SpeedrunSummary?,run: freezed == run ? _self.run : run // ignore: cast_nullable_to_non_nullable
as SpeedrunRun?,previousBest: freezed == previousBest ? _self.previousBest : previousBest // ignore: cast_nullable_to_non_nullable
as Duration?,gameOngoing: null == gameOngoing ? _self.gameOngoing : gameOngoing // ignore: cast_nullable_to_non_nullable
as bool,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SpeedrunSummary>? all,  SpeedrunSummary? selected,  SpeedrunRun? run,  Duration? previousBest,  bool gameOngoing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpeedrunState() when $default != null:
return $default(_that.all,_that.selected,_that.run,_that.previousBest,_that.gameOngoing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SpeedrunSummary>? all,  SpeedrunSummary? selected,  SpeedrunRun? run,  Duration? previousBest,  bool gameOngoing)  $default,) {final _that = this;
switch (_that) {
case _SpeedrunState():
return $default(_that.all,_that.selected,_that.run,_that.previousBest,_that.gameOngoing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SpeedrunSummary>? all,  SpeedrunSummary? selected,  SpeedrunRun? run,  Duration? previousBest,  bool gameOngoing)?  $default,) {final _that = this;
switch (_that) {
case _SpeedrunState() when $default != null:
return $default(_that.all,_that.selected,_that.run,_that.previousBest,_that.gameOngoing);case _:
  return null;

}
}

}

/// @nodoc


class _SpeedrunState implements SpeedrunState {
  const _SpeedrunState({ List<SpeedrunSummary>? all, this.selected, this.run, this.previousBest, this.gameOngoing = false}): _all = all;
  

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
/// A partida em andamento é uma etapa de [run]: jogar continua ela.
@override@JsonKey() final  bool gameOngoing;

/// Create a copy of SpeedrunState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpeedrunStateCopyWith<_SpeedrunState> get copyWith => __$SpeedrunStateCopyWithImpl<_SpeedrunState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpeedrunState&&const DeepCollectionEquality().equals(other.all, _all)&&(identical(other.selected, selected) || other.selected == selected)&&(identical(other.run, run) || other.run == run)&&(identical(other.previousBest, previousBest) || other.previousBest == previousBest)&&(identical(other.gameOngoing, gameOngoing) || other.gameOngoing == gameOngoing));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_all),selected,run,previousBest,gameOngoing);
}

@override
String toString() {
    return 'SpeedrunState(all: $all, selected: $selected, run: $run, previousBest: $previousBest, gameOngoing: $gameOngoing)';
}


}

/// @nodoc
abstract mixin class _$SpeedrunStateCopyWith<$Res> implements $SpeedrunStateCopyWith<$Res> {
  factory _$SpeedrunStateCopyWith(_SpeedrunState value, $Res Function(_SpeedrunState) _then) = __$SpeedrunStateCopyWithImpl;
@override @useResult
$Res call({
 List<SpeedrunSummary>? all, SpeedrunSummary? selected, SpeedrunRun? run, Duration? previousBest, bool gameOngoing
});


@override $SpeedrunSummaryCopyWith<$Res>? get selected;@override $SpeedrunRunCopyWith<$Res>? get run;

}
/// @nodoc
class __$SpeedrunStateCopyWithImpl<$Res>
    implements _$SpeedrunStateCopyWith<$Res> {
  __$SpeedrunStateCopyWithImpl(this._self, this._then);

  final _SpeedrunState _self;
  final $Res Function(_SpeedrunState) _then;

/// Create a copy of SpeedrunState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? all = freezed,Object? selected = freezed,Object? run = freezed,Object? previousBest = freezed,Object? gameOngoing = null,}) {
  return _then(_SpeedrunState(
all: freezed == all ? _self._all : all // ignore: cast_nullable_to_non_nullable
as List<SpeedrunSummary>?,selected: freezed == selected ? _self.selected : selected // ignore: cast_nullable_to_non_nullable
as SpeedrunSummary?,run: freezed == run ? _self.run : run // ignore: cast_nullable_to_non_nullable
as SpeedrunRun?,previousBest: freezed == previousBest ? _self.previousBest : previousBest // ignore: cast_nullable_to_non_nullable
as Duration?,gameOngoing: null == gameOngoing ? _self.gameOngoing : gameOngoing // ignore: cast_nullable_to_non_nullable
as bool,
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
}
}

// dart format on
