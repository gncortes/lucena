import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/game_sound.dart';
import 'package:lucena/domain/use_cases/sound_rules.dart';

void main() {
  test('lance comum, roque e promoção fazem o som de lance', () {
    for (final san in ['Nf3', 'e4', 'O-O', 'O-O-O', 'e8=Q']) {
      expect(SoundRules.ofMove(san), GameSound.move, reason: san);
    }
  });

  test('captura faz o som de captura', () {
    for (final san in ['exd5', 'Rxa1', 'bxa8=Q']) {
      expect(SoundRules.ofMove(san), GameSound.capture, reason: san);
    }
  });

  test('xeque e mate fazem o som de xeque, mesmo capturando', () {
    for (final san in ['Qh5+', 'Rxb7#', 'Qxf7+', 'O-O+']) {
      expect(SoundRules.ofMove(san), GameSound.check, reason: san);
    }
  });
}
