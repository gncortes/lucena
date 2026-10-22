// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserProfile {

/// Apelido escolhido. Vazio usa o apelido padrão, traduzido na tela.
 String get nickname;/// Rating aproximado: o da faixa que o jogador escolheu.
 int get rating;/// O objetivo escolhido na primeira abertura. Nulo: quem já usava o app
/// antes da pergunta (a tela inicial fica como era).
 GoalPreference? get goal;/// De onde veio o [rating]. Nulo: quem já usava o app antes de "Seu
/// nível".
 LevelSource? get levelSource;/// O usuário do Lichess conectado (o token fica só no armazenamento
/// seguro do aparelho, nunca aqui).
 String? get lichessUser;/// O usuário do Chess.com informado em "Seu nível".
 String? get chessComUser;/// A cor do avatar (índice em [avatarColors]), com a inicial do nome.
 int get avatarColor;/// O avatar é a foto da conta do Google, no lugar da inicial.
 bool get googlePhoto;/// O país (código ISO, como `BR`): vem da região do celular, sem
/// seletor. Nulo: o celular não informou.
 String? get country;
/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProfileCopyWith<UserProfile> get copyWith => _$UserProfileCopyWithImpl<UserProfile>(this as UserProfile, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UserProfile;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProfile&&(identical(other.nickname, _this.nickname) || other.nickname == _this.nickname)&&(identical(other.rating, _this.rating) || other.rating == _this.rating)&&(identical(other.goal, _this.goal) || other.goal == _this.goal)&&(identical(other.levelSource, _this.levelSource) || other.levelSource == _this.levelSource)&&(identical(other.lichessUser, _this.lichessUser) || other.lichessUser == _this.lichessUser)&&(identical(other.chessComUser, _this.chessComUser) || other.chessComUser == _this.chessComUser)&&(identical(other.avatarColor, _this.avatarColor) || other.avatarColor == _this.avatarColor)&&(identical(other.googlePhoto, _this.googlePhoto) || other.googlePhoto == _this.googlePhoto)&&(identical(other.country, _this.country) || other.country == _this.country));
}


@override
int get hashCode {
  final _this = this as UserProfile;
  return Object.hash(runtimeType,_this.nickname,_this.rating,_this.goal,_this.levelSource,_this.lichessUser,_this.chessComUser,_this.avatarColor,_this.googlePhoto,_this.country);
}

@override
String toString() {
  final _this = this as UserProfile;
  return 'UserProfile(nickname: ${_this.nickname}, rating: ${_this.rating}, goal: ${_this.goal}, levelSource: ${_this.levelSource}, lichessUser: ${_this.lichessUser}, chessComUser: ${_this.chessComUser}, avatarColor: ${_this.avatarColor}, googlePhoto: ${_this.googlePhoto}, country: ${_this.country})';
}


}

/// @nodoc
abstract mixin class $UserProfileCopyWith<$Res>  {
  factory $UserProfileCopyWith(UserProfile value, $Res Function(UserProfile) _then) = _$UserProfileCopyWithImpl;
@useResult
$Res call({
 String nickname, int rating, GoalPreference? goal, LevelSource? levelSource, String? lichessUser, String? chessComUser, int avatarColor, bool googlePhoto, String? country
});




}
/// @nodoc
class _$UserProfileCopyWithImpl<$Res>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._self, this._then);

  final UserProfile _self;
  final $Res Function(UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nickname = null,Object? rating = null,Object? goal = freezed,Object? levelSource = freezed,Object? lichessUser = freezed,Object? chessComUser = freezed,Object? avatarColor = null,Object? googlePhoto = null,Object? country = freezed,}) {
  return _then(UserProfile(
nickname: null == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int,goal: freezed == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as GoalPreference?,levelSource: freezed == levelSource ? _self.levelSource : levelSource // ignore: cast_nullable_to_non_nullable
as LevelSource?,lichessUser: freezed == lichessUser ? _self.lichessUser : lichessUser // ignore: cast_nullable_to_non_nullable
as String?,chessComUser: freezed == chessComUser ? _self.chessComUser : chessComUser // ignore: cast_nullable_to_non_nullable
as String?,avatarColor: null == avatarColor ? _self.avatarColor : avatarColor // ignore: cast_nullable_to_non_nullable
as int,googlePhoto: null == googlePhoto ? _self.googlePhoto : googlePhoto // ignore: cast_nullable_to_non_nullable
as bool,country: freezed == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserProfile].
extension UserProfilePatterns on UserProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserProfile value)  $default,){
final _that = this;
switch (_that) {
case _UserProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserProfile value)?  $default,){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String nickname,  int rating,  GoalPreference? goal,  LevelSource? levelSource,  String? lichessUser,  String? chessComUser,  int avatarColor,  bool googlePhoto,  String? country)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.nickname,_that.rating,_that.goal,_that.levelSource,_that.lichessUser,_that.chessComUser,_that.avatarColor,_that.googlePhoto,_that.country);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String nickname,  int rating,  GoalPreference? goal,  LevelSource? levelSource,  String? lichessUser,  String? chessComUser,  int avatarColor,  bool googlePhoto,  String? country)  $default,) {final _that = this;
switch (_that) {
case _UserProfile():
return $default(_that.nickname,_that.rating,_that.goal,_that.levelSource,_that.lichessUser,_that.chessComUser,_that.avatarColor,_that.googlePhoto,_that.country);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String nickname,  int rating,  GoalPreference? goal,  LevelSource? levelSource,  String? lichessUser,  String? chessComUser,  int avatarColor,  bool googlePhoto,  String? country)?  $default,) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.nickname,_that.rating,_that.goal,_that.levelSource,_that.lichessUser,_that.chessComUser,_that.avatarColor,_that.googlePhoto,_that.country);case _:
  return null;

}
}

}

/// @nodoc


class _UserProfile extends UserProfile {
  const _UserProfile({this.nickname = '', this.rating = UserProfile.defaultRating, this.goal, this.levelSource, this.lichessUser, this.chessComUser, this.avatarColor = 0, this.googlePhoto = false, this.country}): super._();
  

/// Apelido escolhido. Vazio usa o apelido padrão, traduzido na tela.
@override@JsonKey() final  String nickname;
/// Rating aproximado: o da faixa que o jogador escolheu.
@override@JsonKey() final  int rating;
/// O objetivo escolhido na primeira abertura. Nulo: quem já usava o app
/// antes da pergunta (a tela inicial fica como era).
@override final  GoalPreference? goal;
/// De onde veio o [rating]. Nulo: quem já usava o app antes de "Seu
/// nível".
@override final  LevelSource? levelSource;
/// O usuário do Lichess conectado (o token fica só no armazenamento
/// seguro do aparelho, nunca aqui).
@override final  String? lichessUser;
/// O usuário do Chess.com informado em "Seu nível".
@override final  String? chessComUser;
/// A cor do avatar (índice em [avatarColors]), com a inicial do nome.
@override@JsonKey() final  int avatarColor;
/// O avatar é a foto da conta do Google, no lugar da inicial.
@override@JsonKey() final  bool googlePhoto;
/// O país (código ISO, como `BR`): vem da região do celular, sem
/// seletor. Nulo: o celular não informou.
@override final  String? country;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserProfileCopyWith<_UserProfile> get copyWith => __$UserProfileCopyWithImpl<_UserProfile>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProfile&&(identical(other.nickname, nickname) || other.nickname == nickname)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.levelSource, levelSource) || other.levelSource == levelSource)&&(identical(other.lichessUser, lichessUser) || other.lichessUser == lichessUser)&&(identical(other.chessComUser, chessComUser) || other.chessComUser == chessComUser)&&(identical(other.avatarColor, avatarColor) || other.avatarColor == avatarColor)&&(identical(other.googlePhoto, googlePhoto) || other.googlePhoto == googlePhoto)&&(identical(other.country, country) || other.country == country));
}


@override
int get hashCode {
    return Object.hash(runtimeType,nickname,rating,goal,levelSource,lichessUser,chessComUser,avatarColor,googlePhoto,country);
}

@override
String toString() {
    return 'UserProfile(nickname: $nickname, rating: $rating, goal: $goal, levelSource: $levelSource, lichessUser: $lichessUser, chessComUser: $chessComUser, avatarColor: $avatarColor, googlePhoto: $googlePhoto, country: $country)';
}


}

/// @nodoc
abstract mixin class _$UserProfileCopyWith<$Res> implements $UserProfileCopyWith<$Res> {
  factory _$UserProfileCopyWith(_UserProfile value, $Res Function(_UserProfile) _then) = __$UserProfileCopyWithImpl;
@override @useResult
$Res call({
 String nickname, int rating, GoalPreference? goal, LevelSource? levelSource, String? lichessUser, String? chessComUser, int avatarColor, bool googlePhoto, String? country
});




}
/// @nodoc
class __$UserProfileCopyWithImpl<$Res>
    implements _$UserProfileCopyWith<$Res> {
  __$UserProfileCopyWithImpl(this._self, this._then);

  final _UserProfile _self;
  final $Res Function(_UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nickname = null,Object? rating = null,Object? goal = freezed,Object? levelSource = freezed,Object? lichessUser = freezed,Object? chessComUser = freezed,Object? avatarColor = null,Object? googlePhoto = null,Object? country = freezed,}) {
  return _then(_UserProfile(
nickname: null == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int,goal: freezed == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as GoalPreference?,levelSource: freezed == levelSource ? _self.levelSource : levelSource // ignore: cast_nullable_to_non_nullable
as LevelSource?,lichessUser: freezed == lichessUser ? _self.lichessUser : lichessUser // ignore: cast_nullable_to_non_nullable
as String?,chessComUser: freezed == chessComUser ? _self.chessComUser : chessComUser // ignore: cast_nullable_to_non_nullable
as String?,avatarColor: null == avatarColor ? _self.avatarColor : avatarColor // ignore: cast_nullable_to_non_nullable
as int,googlePhoto: null == googlePhoto ? _self.googlePhoto : googlePhoto // ignore: cast_nullable_to_non_nullable
as bool,country: freezed == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
