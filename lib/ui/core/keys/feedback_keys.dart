import 'package:flutter/widgets.dart';

import '../../../domain/models/feedback_entry.dart';

/// O "Enviar feedback" do Perfil (E1.26).
abstract final class FeedbackKeys {
  static const screen = Key('feedback.screen');
  static Key kindChip(FeedbackType kind) => Key('feedback.kind.${kind.code}');
  static const text = Key('feedback.text');
  static const counter = Key('feedback.counter');
  static const send = Key('feedback.send');
  static const close = Key('feedback.close');

  /// O agradecimento do Viktor e o "Voltar ao perfil".
  static const thanks = Key('feedback.thanks');
  static const thanksBack = Key('feedback.thanksBack');
}
