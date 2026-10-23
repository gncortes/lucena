// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'survey.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SurveyAnswers {

/// A nota, de 1 a 5.
 int? get rating; Set<String> get improve; String? get improveText; SurveyInterest? get interest; bool? get reReview; String? get wishText; Set<String> get topics; Set<String> get difficulties; String? get difficultyText;
/// Create a copy of SurveyAnswers
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SurveyAnswersCopyWith<SurveyAnswers> get copyWith => _$SurveyAnswersCopyWithImpl<SurveyAnswers>(this as SurveyAnswers, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SurveyAnswers;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SurveyAnswers&&(identical(other.rating, _this.rating) || other.rating == _this.rating)&&const DeepCollectionEquality().equals(other.improve, _this.improve)&&(identical(other.improveText, _this.improveText) || other.improveText == _this.improveText)&&(identical(other.interest, _this.interest) || other.interest == _this.interest)&&(identical(other.reReview, _this.reReview) || other.reReview == _this.reReview)&&(identical(other.wishText, _this.wishText) || other.wishText == _this.wishText)&&const DeepCollectionEquality().equals(other.topics, _this.topics)&&const DeepCollectionEquality().equals(other.difficulties, _this.difficulties)&&(identical(other.difficultyText, _this.difficultyText) || other.difficultyText == _this.difficultyText));
}


@override
int get hashCode {
  final _this = this as SurveyAnswers;
  return Object.hash(runtimeType,_this.rating,const DeepCollectionEquality().hash(_this.improve),_this.improveText,_this.interest,_this.reReview,_this.wishText,const DeepCollectionEquality().hash(_this.topics),const DeepCollectionEquality().hash(_this.difficulties),_this.difficultyText);
}

@override
String toString() {
  final _this = this as SurveyAnswers;
  return 'SurveyAnswers(rating: ${_this.rating}, improve: ${_this.improve}, improveText: ${_this.improveText}, interest: ${_this.interest}, reReview: ${_this.reReview}, wishText: ${_this.wishText}, topics: ${_this.topics}, difficulties: ${_this.difficulties}, difficultyText: ${_this.difficultyText})';
}


}

/// @nodoc
abstract mixin class $SurveyAnswersCopyWith<$Res>  {
  factory $SurveyAnswersCopyWith(SurveyAnswers value, $Res Function(SurveyAnswers) _then) = _$SurveyAnswersCopyWithImpl;
@useResult
$Res call({
 int? rating, Set<String> improve, String? improveText, SurveyInterest? interest, bool? reReview, String? wishText, Set<String> topics, Set<String> difficulties, String? difficultyText
});




}
/// @nodoc
class _$SurveyAnswersCopyWithImpl<$Res>
    implements $SurveyAnswersCopyWith<$Res> {
  _$SurveyAnswersCopyWithImpl(this._self, this._then);

  final SurveyAnswers _self;
  final $Res Function(SurveyAnswers) _then;

/// Create a copy of SurveyAnswers
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rating = freezed,Object? improve = null,Object? improveText = freezed,Object? interest = freezed,Object? reReview = freezed,Object? wishText = freezed,Object? topics = null,Object? difficulties = null,Object? difficultyText = freezed,}) {
  return _then(SurveyAnswers(
rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int?,improve: null == improve ? _self.improve : improve // ignore: cast_nullable_to_non_nullable
as Set<String>,improveText: freezed == improveText ? _self.improveText : improveText // ignore: cast_nullable_to_non_nullable
as String?,interest: freezed == interest ? _self.interest : interest // ignore: cast_nullable_to_non_nullable
as SurveyInterest?,reReview: freezed == reReview ? _self.reReview : reReview // ignore: cast_nullable_to_non_nullable
as bool?,wishText: freezed == wishText ? _self.wishText : wishText // ignore: cast_nullable_to_non_nullable
as String?,topics: null == topics ? _self.topics : topics // ignore: cast_nullable_to_non_nullable
as Set<String>,difficulties: null == difficulties ? _self.difficulties : difficulties // ignore: cast_nullable_to_non_nullable
as Set<String>,difficultyText: freezed == difficultyText ? _self.difficultyText : difficultyText // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SurveyAnswers].
extension SurveyAnswersPatterns on SurveyAnswers {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SurveyAnswers value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SurveyAnswers() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SurveyAnswers value)  $default,){
final _that = this;
switch (_that) {
case _SurveyAnswers():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SurveyAnswers value)?  $default,){
final _that = this;
switch (_that) {
case _SurveyAnswers() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? rating,  Set<String> improve,  String? improveText,  SurveyInterest? interest,  bool? reReview,  String? wishText,  Set<String> topics,  Set<String> difficulties,  String? difficultyText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SurveyAnswers() when $default != null:
return $default(_that.rating,_that.improve,_that.improveText,_that.interest,_that.reReview,_that.wishText,_that.topics,_that.difficulties,_that.difficultyText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? rating,  Set<String> improve,  String? improveText,  SurveyInterest? interest,  bool? reReview,  String? wishText,  Set<String> topics,  Set<String> difficulties,  String? difficultyText)  $default,) {final _that = this;
switch (_that) {
case _SurveyAnswers():
return $default(_that.rating,_that.improve,_that.improveText,_that.interest,_that.reReview,_that.wishText,_that.topics,_that.difficulties,_that.difficultyText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? rating,  Set<String> improve,  String? improveText,  SurveyInterest? interest,  bool? reReview,  String? wishText,  Set<String> topics,  Set<String> difficulties,  String? difficultyText)?  $default,) {final _that = this;
switch (_that) {
case _SurveyAnswers() when $default != null:
return $default(_that.rating,_that.improve,_that.improveText,_that.interest,_that.reReview,_that.wishText,_that.topics,_that.difficulties,_that.difficultyText);case _:
  return null;

}
}

}

/// @nodoc


class _SurveyAnswers extends SurveyAnswers {
  const _SurveyAnswers({this.rating,  Set<String> improve = const <String>{}, this.improveText, this.interest, this.reReview, this.wishText,  Set<String> topics = const <String>{},  Set<String> difficulties = const <String>{}, this.difficultyText}): _improve = improve,_topics = topics,_difficulties = difficulties,super._();
  

/// A nota, de 1 a 5.
@override final  int? rating;
 final  Set<String> _improve;
@override@JsonKey() Set<String> get improve {
  if (_improve is EqualUnmodifiableSetView) return _improve;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_improve);
}

@override final  String? improveText;
@override final  SurveyInterest? interest;
@override final  bool? reReview;
@override final  String? wishText;
 final  Set<String> _topics;
@override@JsonKey() Set<String> get topics {
  if (_topics is EqualUnmodifiableSetView) return _topics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_topics);
}

 final  Set<String> _difficulties;
@override@JsonKey() Set<String> get difficulties {
  if (_difficulties is EqualUnmodifiableSetView) return _difficulties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_difficulties);
}

@override final  String? difficultyText;

/// Create a copy of SurveyAnswers
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SurveyAnswersCopyWith<_SurveyAnswers> get copyWith => __$SurveyAnswersCopyWithImpl<_SurveyAnswers>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SurveyAnswers&&(identical(other.rating, rating) || other.rating == rating)&&const DeepCollectionEquality().equals(other.improve, _improve)&&(identical(other.improveText, improveText) || other.improveText == improveText)&&(identical(other.interest, interest) || other.interest == interest)&&(identical(other.reReview, reReview) || other.reReview == reReview)&&(identical(other.wishText, wishText) || other.wishText == wishText)&&const DeepCollectionEquality().equals(other.topics, _topics)&&const DeepCollectionEquality().equals(other.difficulties, _difficulties)&&(identical(other.difficultyText, difficultyText) || other.difficultyText == difficultyText));
}


@override
int get hashCode {
    return Object.hash(runtimeType,rating,const DeepCollectionEquality().hash(_improve),improveText,interest,reReview,wishText,const DeepCollectionEquality().hash(_topics),const DeepCollectionEquality().hash(_difficulties),difficultyText);
}

@override
String toString() {
    return 'SurveyAnswers(rating: $rating, improve: $improve, improveText: $improveText, interest: $interest, reReview: $reReview, wishText: $wishText, topics: $topics, difficulties: $difficulties, difficultyText: $difficultyText)';
}


}

/// @nodoc
abstract mixin class _$SurveyAnswersCopyWith<$Res> implements $SurveyAnswersCopyWith<$Res> {
  factory _$SurveyAnswersCopyWith(_SurveyAnswers value, $Res Function(_SurveyAnswers) _then) = __$SurveyAnswersCopyWithImpl;
@override @useResult
$Res call({
 int? rating, Set<String> improve, String? improveText, SurveyInterest? interest, bool? reReview, String? wishText, Set<String> topics, Set<String> difficulties, String? difficultyText
});




}
/// @nodoc
class __$SurveyAnswersCopyWithImpl<$Res>
    implements _$SurveyAnswersCopyWith<$Res> {
  __$SurveyAnswersCopyWithImpl(this._self, this._then);

  final _SurveyAnswers _self;
  final $Res Function(_SurveyAnswers) _then;

/// Create a copy of SurveyAnswers
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rating = freezed,Object? improve = null,Object? improveText = freezed,Object? interest = freezed,Object? reReview = freezed,Object? wishText = freezed,Object? topics = null,Object? difficulties = null,Object? difficultyText = freezed,}) {
  return _then(_SurveyAnswers(
rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int?,improve: null == improve ? _self._improve : improve // ignore: cast_nullable_to_non_nullable
as Set<String>,improveText: freezed == improveText ? _self.improveText : improveText // ignore: cast_nullable_to_non_nullable
as String?,interest: freezed == interest ? _self.interest : interest // ignore: cast_nullable_to_non_nullable
as SurveyInterest?,reReview: freezed == reReview ? _self.reReview : reReview // ignore: cast_nullable_to_non_nullable
as bool?,wishText: freezed == wishText ? _self.wishText : wishText // ignore: cast_nullable_to_non_nullable
as String?,topics: null == topics ? _self._topics : topics // ignore: cast_nullable_to_non_nullable
as Set<String>,difficulties: null == difficulties ? _self._difficulties : difficulties // ignore: cast_nullable_to_non_nullable
as Set<String>,difficultyText: freezed == difficultyText ? _self.difficultyText : difficultyText // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
