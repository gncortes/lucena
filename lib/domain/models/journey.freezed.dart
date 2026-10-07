// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'journey.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OpponentRef {

 OpponentKind get kind; int? get level;
/// Create a copy of OpponentRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpponentRefCopyWith<OpponentRef> get copyWith => _$OpponentRefCopyWithImpl<OpponentRef>(this as OpponentRef, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OpponentRef;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpponentRef&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.level, _this.level) || other.level == _this.level));
}


@override
int get hashCode {
  final _this = this as OpponentRef;
  return Object.hash(runtimeType,_this.kind,_this.level);
}

@override
String toString() {
  final _this = this as OpponentRef;
  return 'OpponentRef(kind: ${_this.kind}, level: ${_this.level})';
}


}

/// @nodoc
abstract mixin class $OpponentRefCopyWith<$Res>  {
  factory $OpponentRefCopyWith(OpponentRef value, $Res Function(OpponentRef) _then) = _$OpponentRefCopyWithImpl;
@useResult
$Res call({
 OpponentKind kind, int? level
});




}
/// @nodoc
class _$OpponentRefCopyWithImpl<$Res>
    implements $OpponentRefCopyWith<$Res> {
  _$OpponentRefCopyWithImpl(this._self, this._then);

  final OpponentRef _self;
  final $Res Function(OpponentRef) _then;

/// Create a copy of OpponentRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? level = freezed,}) {
  return _then(OpponentRef(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as OpponentKind,level: freezed == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [OpponentRef].
extension OpponentRefPatterns on OpponentRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpponentRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpponentRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpponentRef value)  $default,){
final _that = this;
switch (_that) {
case _OpponentRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpponentRef value)?  $default,){
final _that = this;
switch (_that) {
case _OpponentRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OpponentKind kind,  int? level)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpponentRef() when $default != null:
return $default(_that.kind,_that.level);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OpponentKind kind,  int? level)  $default,) {final _that = this;
switch (_that) {
case _OpponentRef():
return $default(_that.kind,_that.level);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OpponentKind kind,  int? level)?  $default,) {final _that = this;
switch (_that) {
case _OpponentRef() when $default != null:
return $default(_that.kind,_that.level);case _:
  return null;

}
}

}

/// @nodoc


class _OpponentRef extends OpponentRef {
  const _OpponentRef({required this.kind, this.level}): super._();
  

@override final  OpponentKind kind;
@override final  int? level;

/// Create a copy of OpponentRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpponentRefCopyWith<_OpponentRef> get copyWith => __$OpponentRefCopyWithImpl<_OpponentRef>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpponentRef&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.level, level) || other.level == level));
}


@override
int get hashCode {
    return Object.hash(runtimeType,kind,level);
}

@override
String toString() {
    return 'OpponentRef(kind: $kind, level: $level)';
}


}

/// @nodoc
abstract mixin class _$OpponentRefCopyWith<$Res> implements $OpponentRefCopyWith<$Res> {
  factory _$OpponentRefCopyWith(_OpponentRef value, $Res Function(_OpponentRef) _then) = __$OpponentRefCopyWithImpl;
@override @useResult
$Res call({
 OpponentKind kind, int? level
});




}
/// @nodoc
class __$OpponentRefCopyWithImpl<$Res>
    implements _$OpponentRefCopyWith<$Res> {
  __$OpponentRefCopyWithImpl(this._self, this._then);

  final _OpponentRef _self;
  final $Res Function(_OpponentRef) _then;

/// Create a copy of OpponentRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? level = freezed,}) {
  return _then(_OpponentRef(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as OpponentKind,level: freezed == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$Challenge {

/// Estável entre versões: o histórico e o domínio são gravados por ele.
 String get id; EndgamePosition get position; OpponentRef get opponent;/// O tempo de cada lado. Nulo: sem relógio.
 TimeControl? get time;/// Como se joga: normal ou às cegas (os desafios especiais do degrau).
 ChallengeMode get mode;/// Às cegas, o que o tabuleiro mostra no começo: só as casas ou nada.
 bool get hideBoard;/// No speedrun ou na Maratona curtos: o speedrun (com o ritmo no id).
 String? get speedrunId;
/// Create a copy of Challenge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChallengeCopyWith<Challenge> get copyWith => _$ChallengeCopyWithImpl<Challenge>(this as Challenge, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Challenge;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Challenge&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.position, _this.position) || other.position == _this.position)&&(identical(other.opponent, _this.opponent) || other.opponent == _this.opponent)&&(identical(other.time, _this.time) || other.time == _this.time)&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.hideBoard, _this.hideBoard) || other.hideBoard == _this.hideBoard)&&(identical(other.speedrunId, _this.speedrunId) || other.speedrunId == _this.speedrunId));
}


@override
int get hashCode {
  final _this = this as Challenge;
  return Object.hash(runtimeType,_this.id,_this.position,_this.opponent,_this.time,_this.mode,_this.hideBoard,_this.speedrunId);
}

@override
String toString() {
  final _this = this as Challenge;
  return 'Challenge(id: ${_this.id}, position: ${_this.position}, opponent: ${_this.opponent}, time: ${_this.time}, mode: ${_this.mode}, hideBoard: ${_this.hideBoard}, speedrunId: ${_this.speedrunId})';
}


}

/// @nodoc
abstract mixin class $ChallengeCopyWith<$Res>  {
  factory $ChallengeCopyWith(Challenge value, $Res Function(Challenge) _then) = _$ChallengeCopyWithImpl;
@useResult
$Res call({
 String id, EndgamePosition position, OpponentRef opponent, TimeControl? time, ChallengeMode mode, bool hideBoard, String? speedrunId
});


$EndgamePositionCopyWith<$Res> get position;$OpponentRefCopyWith<$Res> get opponent;$TimeControlCopyWith<$Res>? get time;

}
/// @nodoc
class _$ChallengeCopyWithImpl<$Res>
    implements $ChallengeCopyWith<$Res> {
  _$ChallengeCopyWithImpl(this._self, this._then);

  final Challenge _self;
  final $Res Function(Challenge) _then;

/// Create a copy of Challenge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? position = null,Object? opponent = null,Object? time = freezed,Object? mode = null,Object? hideBoard = null,Object? speedrunId = freezed,}) {
  return _then(Challenge(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as EndgamePosition,opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as OpponentRef,time: freezed == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as TimeControl?,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as ChallengeMode,hideBoard: null == hideBoard ? _self.hideBoard : hideBoard // ignore: cast_nullable_to_non_nullable
as bool,speedrunId: freezed == speedrunId ? _self.speedrunId : speedrunId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Challenge
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EndgamePositionCopyWith<$Res> get position {
  
  return $EndgamePositionCopyWith<$Res>(_self.position, (value) {
    return _then(_self.copyWith(position: value));
  });
}/// Create a copy of Challenge
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OpponentRefCopyWith<$Res> get opponent {
  
  return $OpponentRefCopyWith<$Res>(_self.opponent, (value) {
    return _then(_self.copyWith(opponent: value));
  });
}/// Create a copy of Challenge
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeControlCopyWith<$Res>? get time {
    if (_self.time == null) {
    return null;
  }

  return $TimeControlCopyWith<$Res>(_self.time!, (value) {
    return _then(_self.copyWith(time: value));
  });
}
}


/// Adds pattern-matching-related methods to [Challenge].
extension ChallengePatterns on Challenge {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Challenge value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Challenge() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Challenge value)  $default,){
final _that = this;
switch (_that) {
case _Challenge():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Challenge value)?  $default,){
final _that = this;
switch (_that) {
case _Challenge() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  EndgamePosition position,  OpponentRef opponent,  TimeControl? time,  ChallengeMode mode,  bool hideBoard,  String? speedrunId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Challenge() when $default != null:
return $default(_that.id,_that.position,_that.opponent,_that.time,_that.mode,_that.hideBoard,_that.speedrunId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  EndgamePosition position,  OpponentRef opponent,  TimeControl? time,  ChallengeMode mode,  bool hideBoard,  String? speedrunId)  $default,) {final _that = this;
switch (_that) {
case _Challenge():
return $default(_that.id,_that.position,_that.opponent,_that.time,_that.mode,_that.hideBoard,_that.speedrunId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  EndgamePosition position,  OpponentRef opponent,  TimeControl? time,  ChallengeMode mode,  bool hideBoard,  String? speedrunId)?  $default,) {final _that = this;
switch (_that) {
case _Challenge() when $default != null:
return $default(_that.id,_that.position,_that.opponent,_that.time,_that.mode,_that.hideBoard,_that.speedrunId);case _:
  return null;

}
}

}

/// @nodoc


class _Challenge extends Challenge {
  const _Challenge({required this.id, required this.position, required this.opponent, this.time, this.mode = ChallengeMode.normal, this.hideBoard = false, this.speedrunId}): super._();
  

/// Estável entre versões: o histórico e o domínio são gravados por ele.
@override final  String id;
@override final  EndgamePosition position;
@override final  OpponentRef opponent;
/// O tempo de cada lado. Nulo: sem relógio.
@override final  TimeControl? time;
/// Como se joga: normal ou às cegas (os desafios especiais do degrau).
@override@JsonKey() final  ChallengeMode mode;
/// Às cegas, o que o tabuleiro mostra no começo: só as casas ou nada.
@override@JsonKey() final  bool hideBoard;
/// No speedrun ou na Maratona curtos: o speedrun (com o ritmo no id).
@override final  String? speedrunId;

/// Create a copy of Challenge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChallengeCopyWith<_Challenge> get copyWith => __$ChallengeCopyWithImpl<_Challenge>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Challenge&&(identical(other.id, id) || other.id == id)&&(identical(other.position, position) || other.position == position)&&(identical(other.opponent, opponent) || other.opponent == opponent)&&(identical(other.time, time) || other.time == time)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.hideBoard, hideBoard) || other.hideBoard == hideBoard)&&(identical(other.speedrunId, speedrunId) || other.speedrunId == speedrunId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,position,opponent,time,mode,hideBoard,speedrunId);
}

@override
String toString() {
    return 'Challenge(id: $id, position: $position, opponent: $opponent, time: $time, mode: $mode, hideBoard: $hideBoard, speedrunId: $speedrunId)';
}


}

/// @nodoc
abstract mixin class _$ChallengeCopyWith<$Res> implements $ChallengeCopyWith<$Res> {
  factory _$ChallengeCopyWith(_Challenge value, $Res Function(_Challenge) _then) = __$ChallengeCopyWithImpl;
@override @useResult
$Res call({
 String id, EndgamePosition position, OpponentRef opponent, TimeControl? time, ChallengeMode mode, bool hideBoard, String? speedrunId
});


@override $EndgamePositionCopyWith<$Res> get position;@override $OpponentRefCopyWith<$Res> get opponent;@override $TimeControlCopyWith<$Res>? get time;

}
/// @nodoc
class __$ChallengeCopyWithImpl<$Res>
    implements _$ChallengeCopyWith<$Res> {
  __$ChallengeCopyWithImpl(this._self, this._then);

  final _Challenge _self;
  final $Res Function(_Challenge) _then;

/// Create a copy of Challenge
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? position = null,Object? opponent = null,Object? time = freezed,Object? mode = null,Object? hideBoard = null,Object? speedrunId = freezed,}) {
  return _then(_Challenge(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as EndgamePosition,opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as OpponentRef,time: freezed == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as TimeControl?,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as ChallengeMode,hideBoard: null == hideBoard ? _self.hideBoard : hideBoard // ignore: cast_nullable_to_non_nullable
as bool,speedrunId: freezed == speedrunId ? _self.speedrunId : speedrunId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Challenge
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EndgamePositionCopyWith<$Res> get position {
  
  return $EndgamePositionCopyWith<$Res>(_self.position, (value) {
    return _then(_self.copyWith(position: value));
  });
}/// Create a copy of Challenge
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OpponentRefCopyWith<$Res> get opponent {
  
  return $OpponentRefCopyWith<$Res>(_self.opponent, (value) {
    return _then(_self.copyWith(opponent: value));
  });
}/// Create a copy of Challenge
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeControlCopyWith<$Res>? get time {
    if (_self.time == null) {
    return null;
  }

  return $TimeControlCopyWith<$Res>(_self.time!, (value) {
    return _then(_self.copyWith(time: value));
  });
}
}

/// @nodoc
mixin _$Rung {

/// `1000`, `1200`... e `stockfish`.
 String get id; OpponentRef get opponent; List<Challenge> get challenges;/// Os desafios especiais (às cegas): valem como extra e não contam para
/// concluir o degrau.
 List<Challenge> get specials;
/// Create a copy of Rung
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RungCopyWith<Rung> get copyWith => _$RungCopyWithImpl<Rung>(this as Rung, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Rung;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Rung&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.opponent, _this.opponent) || other.opponent == _this.opponent)&&const DeepCollectionEquality().equals(other.challenges, _this.challenges)&&const DeepCollectionEquality().equals(other.specials, _this.specials));
}


@override
int get hashCode {
  final _this = this as Rung;
  return Object.hash(runtimeType,_this.id,_this.opponent,const DeepCollectionEquality().hash(_this.challenges),const DeepCollectionEquality().hash(_this.specials));
}

@override
String toString() {
  final _this = this as Rung;
  return 'Rung(id: ${_this.id}, opponent: ${_this.opponent}, challenges: ${_this.challenges}, specials: ${_this.specials})';
}


}

/// @nodoc
abstract mixin class $RungCopyWith<$Res>  {
  factory $RungCopyWith(Rung value, $Res Function(Rung) _then) = _$RungCopyWithImpl;
@useResult
$Res call({
 String id, OpponentRef opponent, List<Challenge> challenges, List<Challenge> specials
});


$OpponentRefCopyWith<$Res> get opponent;

}
/// @nodoc
class _$RungCopyWithImpl<$Res>
    implements $RungCopyWith<$Res> {
  _$RungCopyWithImpl(this._self, this._then);

  final Rung _self;
  final $Res Function(Rung) _then;

/// Create a copy of Rung
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? opponent = null,Object? challenges = null,Object? specials = null,}) {
  return _then(Rung(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as OpponentRef,challenges: null == challenges ? _self.challenges : challenges // ignore: cast_nullable_to_non_nullable
as List<Challenge>,specials: null == specials ? _self.specials : specials // ignore: cast_nullable_to_non_nullable
as List<Challenge>,
  ));
}
/// Create a copy of Rung
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OpponentRefCopyWith<$Res> get opponent {
  
  return $OpponentRefCopyWith<$Res>(_self.opponent, (value) {
    return _then(_self.copyWith(opponent: value));
  });
}
}


/// Adds pattern-matching-related methods to [Rung].
extension RungPatterns on Rung {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Rung value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Rung() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Rung value)  $default,){
final _that = this;
switch (_that) {
case _Rung():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Rung value)?  $default,){
final _that = this;
switch (_that) {
case _Rung() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  OpponentRef opponent,  List<Challenge> challenges,  List<Challenge> specials)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Rung() when $default != null:
return $default(_that.id,_that.opponent,_that.challenges,_that.specials);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  OpponentRef opponent,  List<Challenge> challenges,  List<Challenge> specials)  $default,) {final _that = this;
switch (_that) {
case _Rung():
return $default(_that.id,_that.opponent,_that.challenges,_that.specials);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  OpponentRef opponent,  List<Challenge> challenges,  List<Challenge> specials)?  $default,) {final _that = this;
switch (_that) {
case _Rung() when $default != null:
return $default(_that.id,_that.opponent,_that.challenges,_that.specials);case _:
  return null;

}
}

}

/// @nodoc


class _Rung implements Rung {
  const _Rung({required this.id, required this.opponent, required  List<Challenge> challenges,  List<Challenge> specials = const <Challenge>[]}): _challenges = challenges,_specials = specials;
  

/// `1000`, `1200`... e `stockfish`.
@override final  String id;
@override final  OpponentRef opponent;
 final  List<Challenge> _challenges;
@override List<Challenge> get challenges {
  if (_challenges is EqualUnmodifiableListView) return _challenges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_challenges);
}

/// Os desafios especiais (às cegas): valem como extra e não contam para
/// concluir o degrau.
 final  List<Challenge> _specials;
/// Os desafios especiais (às cegas): valem como extra e não contam para
/// concluir o degrau.
@override@JsonKey() List<Challenge> get specials {
  if (_specials is EqualUnmodifiableListView) return _specials;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_specials);
}


/// Create a copy of Rung
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RungCopyWith<_Rung> get copyWith => __$RungCopyWithImpl<_Rung>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Rung&&(identical(other.id, id) || other.id == id)&&(identical(other.opponent, opponent) || other.opponent == opponent)&&const DeepCollectionEquality().equals(other.challenges, _challenges)&&const DeepCollectionEquality().equals(other.specials, _specials));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,opponent,const DeepCollectionEquality().hash(_challenges),const DeepCollectionEquality().hash(_specials));
}

@override
String toString() {
    return 'Rung(id: $id, opponent: $opponent, challenges: $challenges, specials: $specials)';
}


}

/// @nodoc
abstract mixin class _$RungCopyWith<$Res> implements $RungCopyWith<$Res> {
  factory _$RungCopyWith(_Rung value, $Res Function(_Rung) _then) = __$RungCopyWithImpl;
@override @useResult
$Res call({
 String id, OpponentRef opponent, List<Challenge> challenges, List<Challenge> specials
});


@override $OpponentRefCopyWith<$Res> get opponent;

}
/// @nodoc
class __$RungCopyWithImpl<$Res>
    implements _$RungCopyWith<$Res> {
  __$RungCopyWithImpl(this._self, this._then);

  final _Rung _self;
  final $Res Function(_Rung) _then;

/// Create a copy of Rung
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? opponent = null,Object? challenges = null,Object? specials = null,}) {
  return _then(_Rung(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as OpponentRef,challenges: null == challenges ? _self._challenges : challenges // ignore: cast_nullable_to_non_nullable
as List<Challenge>,specials: null == specials ? _self._specials : specials // ignore: cast_nullable_to_non_nullable
as List<Challenge>,
  ));
}

/// Create a copy of Rung
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OpponentRefCopyWith<$Res> get opponent {
  
  return $OpponentRefCopyWith<$Res>(_self.opponent, (value) {
    return _then(_self.copyWith(opponent: value));
  });
}
}

/// @nodoc
mixin _$RungProgress {

 Rung get rung; RungStatus get status;/// Os desafios concluídos deste degrau.
 Set<String> get completed;/// Os desafios especiais (às cegas) já vencidos.
 Set<String> get specialsDone;
/// Create a copy of RungProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RungProgressCopyWith<RungProgress> get copyWith => _$RungProgressCopyWithImpl<RungProgress>(this as RungProgress, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RungProgress;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RungProgress&&(identical(other.rung, _this.rung) || other.rung == _this.rung)&&(identical(other.status, _this.status) || other.status == _this.status)&&const DeepCollectionEquality().equals(other.completed, _this.completed)&&const DeepCollectionEquality().equals(other.specialsDone, _this.specialsDone));
}


@override
int get hashCode {
  final _this = this as RungProgress;
  return Object.hash(runtimeType,_this.rung,_this.status,const DeepCollectionEquality().hash(_this.completed),const DeepCollectionEquality().hash(_this.specialsDone));
}

@override
String toString() {
  final _this = this as RungProgress;
  return 'RungProgress(rung: ${_this.rung}, status: ${_this.status}, completed: ${_this.completed}, specialsDone: ${_this.specialsDone})';
}


}

/// @nodoc
abstract mixin class $RungProgressCopyWith<$Res>  {
  factory $RungProgressCopyWith(RungProgress value, $Res Function(RungProgress) _then) = _$RungProgressCopyWithImpl;
@useResult
$Res call({
 Rung rung, RungStatus status, Set<String> completed, Set<String> specialsDone
});


$RungCopyWith<$Res> get rung;

}
/// @nodoc
class _$RungProgressCopyWithImpl<$Res>
    implements $RungProgressCopyWith<$Res> {
  _$RungProgressCopyWithImpl(this._self, this._then);

  final RungProgress _self;
  final $Res Function(RungProgress) _then;

/// Create a copy of RungProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rung = null,Object? status = null,Object? completed = null,Object? specialsDone = null,}) {
  return _then(RungProgress(
rung: null == rung ? _self.rung : rung // ignore: cast_nullable_to_non_nullable
as Rung,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RungStatus,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as Set<String>,specialsDone: null == specialsDone ? _self.specialsDone : specialsDone // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}
/// Create a copy of RungProgress
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RungCopyWith<$Res> get rung {
  
  return $RungCopyWith<$Res>(_self.rung, (value) {
    return _then(_self.copyWith(rung: value));
  });
}
}


/// Adds pattern-matching-related methods to [RungProgress].
extension RungProgressPatterns on RungProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RungProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RungProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RungProgress value)  $default,){
final _that = this;
switch (_that) {
case _RungProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RungProgress value)?  $default,){
final _that = this;
switch (_that) {
case _RungProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Rung rung,  RungStatus status,  Set<String> completed,  Set<String> specialsDone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RungProgress() when $default != null:
return $default(_that.rung,_that.status,_that.completed,_that.specialsDone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Rung rung,  RungStatus status,  Set<String> completed,  Set<String> specialsDone)  $default,) {final _that = this;
switch (_that) {
case _RungProgress():
return $default(_that.rung,_that.status,_that.completed,_that.specialsDone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Rung rung,  RungStatus status,  Set<String> completed,  Set<String> specialsDone)?  $default,) {final _that = this;
switch (_that) {
case _RungProgress() when $default != null:
return $default(_that.rung,_that.status,_that.completed,_that.specialsDone);case _:
  return null;

}
}

}

/// @nodoc


class _RungProgress extends RungProgress {
  const _RungProgress({required this.rung, required this.status, required  Set<String> completed,  Set<String> specialsDone = const <String>{}}): _completed = completed,_specialsDone = specialsDone,super._();
  

@override final  Rung rung;
@override final  RungStatus status;
/// Os desafios concluídos deste degrau.
 final  Set<String> _completed;
/// Os desafios concluídos deste degrau.
@override Set<String> get completed {
  if (_completed is EqualUnmodifiableSetView) return _completed;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_completed);
}

/// Os desafios especiais (às cegas) já vencidos.
 final  Set<String> _specialsDone;
/// Os desafios especiais (às cegas) já vencidos.
@override@JsonKey() Set<String> get specialsDone {
  if (_specialsDone is EqualUnmodifiableSetView) return _specialsDone;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_specialsDone);
}


/// Create a copy of RungProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RungProgressCopyWith<_RungProgress> get copyWith => __$RungProgressCopyWithImpl<_RungProgress>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RungProgress&&(identical(other.rung, rung) || other.rung == rung)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.completed, _completed)&&const DeepCollectionEquality().equals(other.specialsDone, _specialsDone));
}


@override
int get hashCode {
    return Object.hash(runtimeType,rung,status,const DeepCollectionEquality().hash(_completed),const DeepCollectionEquality().hash(_specialsDone));
}

@override
String toString() {
    return 'RungProgress(rung: $rung, status: $status, completed: $completed, specialsDone: $specialsDone)';
}


}

/// @nodoc
abstract mixin class _$RungProgressCopyWith<$Res> implements $RungProgressCopyWith<$Res> {
  factory _$RungProgressCopyWith(_RungProgress value, $Res Function(_RungProgress) _then) = __$RungProgressCopyWithImpl;
@override @useResult
$Res call({
 Rung rung, RungStatus status, Set<String> completed, Set<String> specialsDone
});


@override $RungCopyWith<$Res> get rung;

}
/// @nodoc
class __$RungProgressCopyWithImpl<$Res>
    implements _$RungProgressCopyWith<$Res> {
  __$RungProgressCopyWithImpl(this._self, this._then);

  final _RungProgress _self;
  final $Res Function(_RungProgress) _then;

/// Create a copy of RungProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rung = null,Object? status = null,Object? completed = null,Object? specialsDone = null,}) {
  return _then(_RungProgress(
rung: null == rung ? _self.rung : rung // ignore: cast_nullable_to_non_nullable
as Rung,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RungStatus,completed: null == completed ? _self._completed : completed // ignore: cast_nullable_to_non_nullable
as Set<String>,specialsDone: null == specialsDone ? _self._specialsDone : specialsDone // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

/// Create a copy of RungProgress
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RungCopyWith<$Res> get rung {
  
  return $RungCopyWith<$Res>(_self.rung, (value) {
    return _then(_self.copyWith(rung: value));
  });
}
}

/// @nodoc
mixin _$JourneyProgress {

 List<RungProgress> get rungs;/// O degrau por onde o jogador começou (o escolhido no tour).
 int get start;
/// Create a copy of JourneyProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JourneyProgressCopyWith<JourneyProgress> get copyWith => _$JourneyProgressCopyWithImpl<JourneyProgress>(this as JourneyProgress, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as JourneyProgress;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JourneyProgress&&const DeepCollectionEquality().equals(other.rungs, _this.rungs)&&(identical(other.start, _this.start) || other.start == _this.start));
}


@override
int get hashCode {
  final _this = this as JourneyProgress;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.rungs),_this.start);
}

@override
String toString() {
  final _this = this as JourneyProgress;
  return 'JourneyProgress(rungs: ${_this.rungs}, start: ${_this.start})';
}


}

/// @nodoc
abstract mixin class $JourneyProgressCopyWith<$Res>  {
  factory $JourneyProgressCopyWith(JourneyProgress value, $Res Function(JourneyProgress) _then) = _$JourneyProgressCopyWithImpl;
@useResult
$Res call({
 List<RungProgress> rungs, int start
});




}
/// @nodoc
class _$JourneyProgressCopyWithImpl<$Res>
    implements $JourneyProgressCopyWith<$Res> {
  _$JourneyProgressCopyWithImpl(this._self, this._then);

  final JourneyProgress _self;
  final $Res Function(JourneyProgress) _then;

/// Create a copy of JourneyProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rungs = null,Object? start = null,}) {
  return _then(JourneyProgress(
rungs: null == rungs ? _self.rungs : rungs // ignore: cast_nullable_to_non_nullable
as List<RungProgress>,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [JourneyProgress].
extension JourneyProgressPatterns on JourneyProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JourneyProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JourneyProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JourneyProgress value)  $default,){
final _that = this;
switch (_that) {
case _JourneyProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JourneyProgress value)?  $default,){
final _that = this;
switch (_that) {
case _JourneyProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<RungProgress> rungs,  int start)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JourneyProgress() when $default != null:
return $default(_that.rungs,_that.start);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<RungProgress> rungs,  int start)  $default,) {final _that = this;
switch (_that) {
case _JourneyProgress():
return $default(_that.rungs,_that.start);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<RungProgress> rungs,  int start)?  $default,) {final _that = this;
switch (_that) {
case _JourneyProgress() when $default != null:
return $default(_that.rungs,_that.start);case _:
  return null;

}
}

}

/// @nodoc


class _JourneyProgress extends JourneyProgress {
  const _JourneyProgress({required  List<RungProgress> rungs, this.start = 0}): _rungs = rungs,super._();
  

 final  List<RungProgress> _rungs;
@override List<RungProgress> get rungs {
  if (_rungs is EqualUnmodifiableListView) return _rungs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rungs);
}

/// O degrau por onde o jogador começou (o escolhido no tour).
@override@JsonKey() final  int start;

/// Create a copy of JourneyProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JourneyProgressCopyWith<_JourneyProgress> get copyWith => __$JourneyProgressCopyWithImpl<_JourneyProgress>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _JourneyProgress&&const DeepCollectionEquality().equals(other.rungs, _rungs)&&(identical(other.start, start) || other.start == start));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_rungs),start);
}

@override
String toString() {
    return 'JourneyProgress(rungs: $rungs, start: $start)';
}


}

/// @nodoc
abstract mixin class _$JourneyProgressCopyWith<$Res> implements $JourneyProgressCopyWith<$Res> {
  factory _$JourneyProgressCopyWith(_JourneyProgress value, $Res Function(_JourneyProgress) _then) = __$JourneyProgressCopyWithImpl;
@override @useResult
$Res call({
 List<RungProgress> rungs, int start
});




}
/// @nodoc
class __$JourneyProgressCopyWithImpl<$Res>
    implements _$JourneyProgressCopyWith<$Res> {
  __$JourneyProgressCopyWithImpl(this._self, this._then);

  final _JourneyProgress _self;
  final $Res Function(_JourneyProgress) _then;

/// Create a copy of JourneyProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rungs = null,Object? start = null,}) {
  return _then(_JourneyProgress(
rungs: null == rungs ? _self._rungs : rungs // ignore: cast_nullable_to_non_nullable
as List<RungProgress>,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
