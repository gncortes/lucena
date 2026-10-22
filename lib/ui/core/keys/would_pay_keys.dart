import 'package:flutter/widgets.dart';

/// O cartão de convite e os 3 passos do "Você pagaria?" (E1.26). Os [code]
/// são os estáveis do domínio (`would_pay.dart`).
abstract final class WouldPayKeys {
  static const invite = Key('wouldPay.invite');
  static const inviteYes = Key('wouldPay.invite.yes');
  static const inviteNo = Key('wouldPay.invite.no');

  static const screen = Key('wouldPay.screen');
  static const progress = Key('wouldPay.progress');

  static Key courseAnswer(String code) => Key('wouldPay.course.$code');
  static Key coursePrice(String code) => Key('wouldPay.coursePrice.$code');
  static Key coachAnswer(String code) => Key('wouldPay.coach.$code');
  static Key coachPrice(String code) => Key('wouldPay.coachPrice.$code');
  static Key learnAnswer(String code) => Key('wouldPay.learn.$code');
  static const nextText = Key('wouldPay.nextText');
  static Key whyChip(String code) => Key('wouldPay.why.$code');
  static Key levelChip(String code) => Key('wouldPay.level.$code');

  static const next = Key('wouldPay.next');
  static const back = Key('wouldPay.back');
  static const send = Key('wouldPay.send');
  static const close = Key('wouldPay.close');

  /// O agradecimento do Viktor e o botão que volta às aulas.
  static const thanks = Key('wouldPay.thanks');
  static const thanksBack = Key('wouldPay.thanksBack');
}
