import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/endgames_robot.dart';
import 'robots/home_robot.dart';
import 'robots/tour_robot.dart';
import 'robots/variant.dart';
import 'robots/voice_robot.dart';

const _english = Locale('en', 'US');

/// As vozes falsas do idioma do cenário (em árabe na variante dela).
String _voice(int index) =>
    (e2eTranslated ? ['ar-x-a', 'ar-x-b'] : ['en-us-x-a', 'en-us-x-b'])[index];

void main() {
  patrolTest('tour: escolher a voz do Viktor e a de um adversário; a escolha '
      'fica nas configurações', ($) async {
    final app = AppRobot($);
    final tour = TourRobot($);
    final voice = VoiceRobot($);
    await app.open(systemLocale: _english, tour: true);
    // A voz é o primeiro passo.
    await tour.expectStep(TourStep.voice);

    // Tocar numa voz liga a voz e o Viktor fala nela.
    await voice.choose(_voice(1));
    expect(voice.lastSpoken.$2, _voice(1));

    await tour.next();
    await tour.expectStep(TourStep.characterVoices);
    await voice.openCharacter('beachgoer');
    await voice.choose(_voice(0));
    expect(voice.lastSpoken.$1, contains('Coco'));
    expect(voice.lastSpoken.$2, _voice(0));
    await voice.closeSheet();
    await tour.next();
    await tour.expectStep(TourStep.goal);

    // Fechar à força: a escolha continua.
    await app.restart();
    await tour.skip();
    await HomeRobot($).openSettings();
    await voice.openSettings();
    voice.expectEnabled(enabled: true);
    voice.expectChosen(_voice(1));
  });

  patrolTest('tour: "sem voz" desliga a voz e pula as vozes dos adversários', (
    $,
  ) async {
    final tour = TourRobot($);
    final voice = VoiceRobot($);
    await AppRobot($).open(systemLocale: _english, tour: true);
    await tour.expectStep(TourStep.voice);
    await voice.chooseNone();
    await tour.next();
    await tour.expectStep(TourStep.goal);
  });

  patrolTest('lição: o botão de som liga a voz e fala, e cala de novo; '
      'ligada, a fala sai sozinha', ($) async {
    final app = AppRobot($);
    final voice = VoiceRobot($);
    final endgames = EndgamesRobot($);
    await app.open(systemLocale: _english);
    await endgames.openFromHome();
    await endgames.openLesson('rook.philidor');
    await endgames.openSteps();

    // A voz começa desligada: nada sai sozinho. O botão liga e já fala; de
    // novo, cala.
    expect(voice.spokenCount, 0);
    await voice.tapSpeak();
    expect(voice.spokenCount, 1);
    var stops = voice.stops;
    await voice.tapSpeak();
    expect(voice.stops, greaterThan(stops));

    // Sair da lição no meio da fala para a voz.
    await voice.tapSpeak();
    stops = voice.stops;
    await endgames.back();
    expect(voice.stops, greaterThan(stops));

    // O botão deixou a voz ligada: o passo seguinte fala sozinho.
    await app.restart();
    var before = voice.spokenCount;
    await endgames.openFromHome();
    await endgames.openLesson('rook.philidor');
    await endgames.openSteps();
    await endgames.nextStep();
    expect(voice.spokenCount, greaterThan(before));
    await endgames.back();

    // Desligada nas configurações, nada sai sozinho.
    await app.restart();
    await HomeRobot($).openSettings();
    await voice.openSettings();
    await voice.toggleEnabled();
    await app.restart();
    before = voice.spokenCount;
    await endgames.openFromHome();
    await endgames.openLesson('rook.philidor');
    await endgames.openSteps();
    await $.pump(const Duration(seconds: 1));
    expect(voice.spokenCount, before);
  });
}
