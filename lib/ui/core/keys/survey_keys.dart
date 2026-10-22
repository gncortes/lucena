import 'package:flutter/widgets.dart';

import '../../../domain/models/survey.dart';

/// O cartão de convite e o questionário "Sua opinião" (E1.05).
abstract final class SurveyKeys {
  /// O cartão de convite de [kind] e o botão "Responder" dele.
  static Key invite(SurveyKind kind) => Key('survey.invite.${kind.code}');
  static Key inviteAction(SurveyKind kind) =>
      Key('survey.invite.${kind.code}.action');

  static const screen = Key('survey.screen');
  static const progress = Key('survey.progress');

  /// O rosto da nota [n] (1 a 5).
  static Key face(int n) => Key('survey.face.$n');

  /// Os chips; o [id] é o estável do domínio (`SurveyOptions`).
  static Key improveChip(String id) => Key('survey.improve.$id');
  static Key topicChip(String id) => Key('survey.topic.$id');
  static Key difficultyChip(String id) => Key('survey.difficulty.$id');

  static const improveText = Key('survey.improveText');
  static const wishText = Key('survey.wishText');
  static const difficultyText = Key('survey.difficultyText');

  static Key interest(SurveyInterest interest) =>
      Key('survey.interest.${interest.name}');

  /// "Rever e opinar de novo": sim (`true`) ou não.
  static Key reReview({required bool yes}) =>
      Key('survey.reReview.${yes ? 'yes' : 'no'}');

  static const next = Key('survey.next');
  static const send = Key('survey.send');
  static const back = Key('survey.back');
  static const close = Key('survey.close');

  /// O agradecimento e o botão que volta à origem.
  static const thanks = Key('survey.thanks');
  static const thanksBack = Key('survey.thanksBack');
}
