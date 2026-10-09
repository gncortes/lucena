// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppSettings {

/// Código do idioma escolhido (`es`, `pt_PT`...). Nulo segue o sistema.
 String? get languageCode;/// Tema claro, escuro ou o do aparelho.
 AppThemeMode get themeMode;/// Cor predominante do app. Nula: a de fábrica de cada tema (azul no
/// claro, verde no escuro).
 AppAccent? get accent;/// Aparência e comportamento do tabuleiro.
 BoardSettings get board;/// Onde o relógio aparece e como ele avisa.
 ClockSettings get clock;/// Os personagens comentam a partida num balão de fala.
 bool get characterTalk;/// Os sons do jogo: o das peças a cada lance e o aviso do relógio.
 bool get sound;/// O retorno tátil: lances, vitórias, conquistas e o aviso do relógio.
 bool get vibration;/// Quanto tempo o aluno pensa sozinho numa posição da aula antes da
/// explicação: 1, 3 ou 5 minutos, ou 0, o recomendado por cada posição
/// (5 nas posições-chave, 1 ou 3 nas de passagem) (T51).
 int get thinkMinutes;/// O aluno já escolheu o tempo de pensar (na primeira aula com passo de
/// pensar ou nas Configurações). Sem isso, a aula pergunta antes.
 bool get thinkChosen;/// A barra de avaliação da engine na revisão da partida.
 bool get evalBar;/// Nas aulas de finais, com o teste de nível feito: a trilha inteira
/// ("Todos") em vez do roteiro ("Para você") (T52).
 bool get endgamesAll;
 bool get endgamesHideDone;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.languageCode, _this.languageCode) || other.languageCode == _this.languageCode)&&(identical(other.themeMode, _this.themeMode) || other.themeMode == _this.themeMode)&&(identical(other.accent, _this.accent) || other.accent == _this.accent)&&(identical(other.board, _this.board) || other.board == _this.board)&&(identical(other.clock, _this.clock) || other.clock == _this.clock)&&(identical(other.characterTalk, _this.characterTalk) || other.characterTalk == _this.characterTalk)&&(identical(other.sound, _this.sound) || other.sound == _this.sound)&&(identical(other.vibration, _this.vibration) || other.vibration == _this.vibration)&&(identical(other.thinkMinutes, _this.thinkMinutes) || other.thinkMinutes == _this.thinkMinutes)&&(identical(other.thinkChosen, _this.thinkChosen) || other.thinkChosen == _this.thinkChosen)&&(identical(other.evalBar, _this.evalBar) || other.evalBar == _this.evalBar)&&(identical(other.endgamesAll, _this.endgamesAll) || other.endgamesAll == _this.endgamesAll)&&(identical(other.endgamesHideDone, _this.endgamesHideDone) || other.endgamesHideDone == _this.endgamesHideDone));
}


@override
int get hashCode {
  final _this = this as AppSettings;
  return Object.hash(runtimeType,_this.languageCode,_this.themeMode,_this.accent,_this.board,_this.clock,_this.characterTalk,_this.sound,_this.vibration,_this.thinkMinutes,_this.thinkChosen,_this.evalBar,_this.endgamesAll,_this.endgamesHideDone);
}

@override
String toString() {
  final _this = this as AppSettings;
  return 'AppSettings(languageCode: ${_this.languageCode}, themeMode: ${_this.themeMode}, accent: ${_this.accent}, board: ${_this.board}, clock: ${_this.clock}, characterTalk: ${_this.characterTalk}, sound: ${_this.sound}, vibration: ${_this.vibration}, thinkMinutes: ${_this.thinkMinutes}, thinkChosen: ${_this.thinkChosen}, evalBar: ${_this.evalBar}, endgamesAll: ${_this.endgamesAll}, endgamesHideDone: ${_this.endgamesHideDone})';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 String? languageCode, AppThemeMode themeMode, AppAccent? accent, BoardSettings board, ClockSettings clock, bool characterTalk, bool sound, bool vibration, int thinkMinutes, bool thinkChosen, bool evalBar, bool endgamesAll, bool endgamesHideDone
});


$BoardSettingsCopyWith<$Res> get board;$ClockSettingsCopyWith<$Res> get clock;

}
/// @nodoc
class _$AppSettingsCopyWithImpl<$Res>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? languageCode = freezed,Object? themeMode = null,Object? accent = freezed,Object? board = null,Object? clock = null,Object? characterTalk = null,Object? sound = null,Object? vibration = null,Object? thinkMinutes = null,Object? thinkChosen = null,Object? evalBar = null,Object? endgamesAll = null,Object? endgamesHideDone = null,}) {
  return _then(AppSettings(
languageCode: freezed == languageCode ? _self.languageCode : languageCode // ignore: cast_nullable_to_non_nullable
as String?,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as AppThemeMode,accent: freezed == accent ? _self.accent : accent // ignore: cast_nullable_to_non_nullable
as AppAccent?,board: null == board ? _self.board : board // ignore: cast_nullable_to_non_nullable
as BoardSettings,clock: null == clock ? _self.clock : clock // ignore: cast_nullable_to_non_nullable
as ClockSettings,characterTalk: null == characterTalk ? _self.characterTalk : characterTalk // ignore: cast_nullable_to_non_nullable
as bool,sound: null == sound ? _self.sound : sound // ignore: cast_nullable_to_non_nullable
as bool,vibration: null == vibration ? _self.vibration : vibration // ignore: cast_nullable_to_non_nullable
as bool,thinkMinutes: null == thinkMinutes ? _self.thinkMinutes : thinkMinutes // ignore: cast_nullable_to_non_nullable
as int,thinkChosen: null == thinkChosen ? _self.thinkChosen : thinkChosen // ignore: cast_nullable_to_non_nullable
as bool,evalBar: null == evalBar ? _self.evalBar : evalBar // ignore: cast_nullable_to_non_nullable
as bool,endgamesAll: null == endgamesAll ? _self.endgamesAll : endgamesAll // ignore: cast_nullable_to_non_nullable
as bool,endgamesHideDone: null == endgamesHideDone ? _self.endgamesHideDone : endgamesHideDone // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoardSettingsCopyWith<$Res> get board {
  
  return $BoardSettingsCopyWith<$Res>(_self.board, (value) {
    return _then(_self.copyWith(board: value));
  });
}/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClockSettingsCopyWith<$Res> get clock {
  
  return $ClockSettingsCopyWith<$Res>(_self.clock, (value) {
    return _then(_self.copyWith(clock: value));
  });
}
}


/// Adds pattern-matching-related methods to [AppSettings].
extension AppSettingsPatterns on AppSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSettings value)  $default,){
final _that = this;
switch (_that) {
case _AppSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? languageCode,  AppThemeMode themeMode,  AppAccent? accent,  BoardSettings board,  ClockSettings clock,  bool characterTalk,  bool sound,  bool vibration,  int thinkMinutes,  bool thinkChosen,  bool evalBar,  bool endgamesAll,  bool endgamesHideDone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.languageCode,_that.themeMode,_that.accent,_that.board,_that.clock,_that.characterTalk,_that.sound,_that.vibration,_that.thinkMinutes,_that.thinkChosen,_that.evalBar,_that.endgamesAll,_that.endgamesHideDone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? languageCode,  AppThemeMode themeMode,  AppAccent? accent,  BoardSettings board,  ClockSettings clock,  bool characterTalk,  bool sound,  bool vibration,  int thinkMinutes,  bool thinkChosen,  bool evalBar,  bool endgamesAll,  bool endgamesHideDone)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.languageCode,_that.themeMode,_that.accent,_that.board,_that.clock,_that.characterTalk,_that.sound,_that.vibration,_that.thinkMinutes,_that.thinkChosen,_that.evalBar,_that.endgamesAll,_that.endgamesHideDone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? languageCode,  AppThemeMode themeMode,  AppAccent? accent,  BoardSettings board,  ClockSettings clock,  bool characterTalk,  bool sound,  bool vibration,  int thinkMinutes,  bool thinkChosen,  bool evalBar,  bool endgamesAll,  bool endgamesHideDone)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.languageCode,_that.themeMode,_that.accent,_that.board,_that.clock,_that.characterTalk,_that.sound,_that.vibration,_that.thinkMinutes,_that.thinkChosen,_that.evalBar,_that.endgamesAll,_that.endgamesHideDone);case _:
  return null;

}
}

}

/// @nodoc


class _AppSettings implements AppSettings {
  const _AppSettings({this.languageCode, this.themeMode = AppThemeMode.system, this.accent, this.board = const BoardSettings(), this.clock = const ClockSettings(), this.characterTalk = true, this.sound = true, this.vibration = true, this.thinkMinutes = 0, this.thinkChosen = false, this.evalBar = true, this.endgamesAll = false, this.endgamesHideDone = false});
  

/// Código do idioma escolhido (`es`, `pt_PT`...). Nulo segue o sistema.
@override final  String? languageCode;
/// Tema claro, escuro ou o do aparelho.
@override@JsonKey() final  AppThemeMode themeMode;
/// Cor predominante do app. Nula: a de fábrica de cada tema (azul no
/// claro, verde no escuro).
@override final  AppAccent? accent;
/// Aparência e comportamento do tabuleiro.
@override@JsonKey() final  BoardSettings board;
/// Onde o relógio aparece e como ele avisa.
@override@JsonKey() final  ClockSettings clock;
/// Os personagens comentam a partida num balão de fala.
@override@JsonKey() final  bool characterTalk;
/// Os sons do jogo: o das peças a cada lance e o aviso do relógio.
@override@JsonKey() final  bool sound;
/// O retorno tátil: lances, vitórias, conquistas e o aviso do relógio.
@override@JsonKey() final  bool vibration;
/// Quanto tempo o aluno pensa sozinho numa posição da aula antes da
/// explicação: 1, 3 ou 5 minutos, ou 0, o recomendado por cada posição
/// (5 nas posições-chave, 1 ou 3 nas de passagem) (T51).
@override@JsonKey() final  int thinkMinutes;
/// O aluno já escolheu o tempo de pensar (na primeira aula com passo de
/// pensar ou nas Configurações). Sem isso, a aula pergunta antes.
@override@JsonKey() final  bool thinkChosen;
/// A barra de avaliação da engine na revisão da partida.
@override@JsonKey() final  bool evalBar;
/// Nas aulas de finais, com o teste de nível feito: a trilha inteira
/// ("Todos") em vez do roteiro ("Para você") (T52).
@override@JsonKey() final  bool endgamesAll;
@override@JsonKey() final  bool endgamesHideDone;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsCopyWith<_AppSettings> get copyWith => __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.languageCode, languageCode) || other.languageCode == languageCode)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.accent, accent) || other.accent == accent)&&(identical(other.board, board) || other.board == board)&&(identical(other.clock, clock) || other.clock == clock)&&(identical(other.characterTalk, characterTalk) || other.characterTalk == characterTalk)&&(identical(other.sound, sound) || other.sound == sound)&&(identical(other.vibration, vibration) || other.vibration == vibration)&&(identical(other.thinkMinutes, thinkMinutes) || other.thinkMinutes == thinkMinutes)&&(identical(other.thinkChosen, thinkChosen) || other.thinkChosen == thinkChosen)&&(identical(other.evalBar, evalBar) || other.evalBar == evalBar)&&(identical(other.endgamesAll, endgamesAll) || other.endgamesAll == endgamesAll)&&(identical(other.endgamesHideDone, endgamesHideDone) || other.endgamesHideDone == endgamesHideDone));
}


@override
int get hashCode {
    return Object.hash(runtimeType,languageCode,themeMode,accent,board,clock,characterTalk,sound,vibration,thinkMinutes,thinkChosen,evalBar,endgamesAll,endgamesHideDone);
}

@override
String toString() {
    return 'AppSettings(languageCode: $languageCode, themeMode: $themeMode, accent: $accent, board: $board, clock: $clock, characterTalk: $characterTalk, sound: $sound, vibration: $vibration, thinkMinutes: $thinkMinutes, thinkChosen: $thinkChosen, evalBar: $evalBar, endgamesAll: $endgamesAll, endgamesHideDone: $endgamesHideDone)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 String? languageCode, AppThemeMode themeMode, AppAccent? accent, BoardSettings board, ClockSettings clock, bool characterTalk, bool sound, bool vibration, int thinkMinutes, bool thinkChosen, bool evalBar, bool endgamesAll, bool endgamesHideDone
});


@override $BoardSettingsCopyWith<$Res> get board;@override $ClockSettingsCopyWith<$Res> get clock;

}
/// @nodoc
class __$AppSettingsCopyWithImpl<$Res>
    implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? languageCode = freezed,Object? themeMode = null,Object? accent = freezed,Object? board = null,Object? clock = null,Object? characterTalk = null,Object? sound = null,Object? vibration = null,Object? thinkMinutes = null,Object? thinkChosen = null,Object? evalBar = null,Object? endgamesAll = null,Object? endgamesHideDone = null,}) {
  return _then(_AppSettings(
languageCode: freezed == languageCode ? _self.languageCode : languageCode // ignore: cast_nullable_to_non_nullable
as String?,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as AppThemeMode,accent: freezed == accent ? _self.accent : accent // ignore: cast_nullable_to_non_nullable
as AppAccent?,board: null == board ? _self.board : board // ignore: cast_nullable_to_non_nullable
as BoardSettings,clock: null == clock ? _self.clock : clock // ignore: cast_nullable_to_non_nullable
as ClockSettings,characterTalk: null == characterTalk ? _self.characterTalk : characterTalk // ignore: cast_nullable_to_non_nullable
as bool,sound: null == sound ? _self.sound : sound // ignore: cast_nullable_to_non_nullable
as bool,vibration: null == vibration ? _self.vibration : vibration // ignore: cast_nullable_to_non_nullable
as bool,thinkMinutes: null == thinkMinutes ? _self.thinkMinutes : thinkMinutes // ignore: cast_nullable_to_non_nullable
as int,thinkChosen: null == thinkChosen ? _self.thinkChosen : thinkChosen // ignore: cast_nullable_to_non_nullable
as bool,evalBar: null == evalBar ? _self.evalBar : evalBar // ignore: cast_nullable_to_non_nullable
as bool,endgamesAll: null == endgamesAll ? _self.endgamesAll : endgamesAll // ignore: cast_nullable_to_non_nullable
as bool,endgamesHideDone: null == endgamesHideDone ? _self.endgamesHideDone : endgamesHideDone // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoardSettingsCopyWith<$Res> get board {
  
  return $BoardSettingsCopyWith<$Res>(_self.board, (value) {
    return _then(_self.copyWith(board: value));
  });
}/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClockSettingsCopyWith<$Res> get clock {
  
  return $ClockSettingsCopyWith<$Res>(_self.clock, (value) {
    return _then(_self.copyWith(clock: value));
  });
}
}

// dart format on
