import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/visible_lessons.dart';
import 'package:lucena/ui/core/keys/lesson_sound_keys.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/core/keys/voice_keys.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/endgames_robot.dart';
import 'robots/home_robot.dart';
import 'robots/sheet_robot.dart';
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
    // A voz é o segundo passo, depois do tabuleiro.
    await tour.openVoice();

    // Tocar numa voz liga a voz e o Viktor fala nela.
    await voice.choose(_voice(1));
    expect(voice.lastSpoken.$2, _voice(1));

    await tour.next();
    await tour.expectStep(TourStep.school);

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
    await tour.openVoice();
    await voice.chooseNone();
    await tour.next();
    await tour.expectStep(TourStep.school);
  });

  patrolTest('Configurações > Voz: sem a seção das vozes dos adversários; '
      'cada adversário recebe uma voz sozinho, diferente da do Viktor', (
    $,
  ) async {
    final app = AppRobot($);
    final voice = VoiceRobot($);
    await app.open(systemLocale: _english);
    await HomeRobot($).openSettings();
    await voice.openSettings();

    // Só a voz do professor: nada de lista de vozes por adversário.
    await $(VoiceKeys.voice(_voice(0))).scrollTo();
    // Controle: o idioma é mesmo o inglês (o título que fica aparece), então
    // a ausência dos textos antigos, abaixo, prova alguma coisa.
    final l10n = $.tester.element(find.byKey(VoiceKeys.settingsSection)).l10n;
    expect(find.text(l10n.voiceTeacher), findsOneWidget);
    expect(l10n.voiceTeacher, "Teacher's voice");
    expect(find.text("Opponents' voices"), findsNothing);
    expect(find.text('Chosen by the app'), findsNothing);
    expect(find.byKey(VoiceKeys.keep), findsNothing);

    // A atribuição é automática: todos os adversários têm voz, e nenhum fala
    // com a do Viktor (há mais de uma voz no idioma).
    final speech = $.tester
        .element(find.byKey(VoiceKeys.settingsSection))
        .read<SpeechCubit>();
    final state = speech.state;
    final teacher = state.voiceOf(SpeechCubit.teacherId, 'en');
    expect(teacher, isNotNull);
    expect(state.characters, isNotEmpty);
    for (final character in state.characters) {
      final assigned = state.voiceOf(character.id, 'en');
      expect(assigned, isNotNull, reason: character.id);
      expect(
        assigned!.voice.id,
        isNot(teacher!.voice.id),
        reason: character.id,
      );
    }

    // Trocar a voz do Viktor muda a dele sem deixar um adversário com ela.
    await voice.choose(_voice(1));
    final changed = speech.state.voiceOf(SpeechCubit.teacherId, 'en')!;
    expect(changed.voice.id, _voice(1));
    for (final character in speech.state.characters) {
      expect(
        speech.state.voiceOf(character.id, 'en')!.voice.id,
        isNot(changed.voice.id),
        reason: character.id,
      );
    }
  });

  // Aula escondida (VisibleLessons): o cenário volta quando ela for liberada.
  patrolTest('lição: o botão de som abre o som da lição; ligar a voz ali faz '
      'a fala sair sozinha', ($) async {
    final app = AppRobot($);
    final voice = VoiceRobot($);
    final endgames = EndgamesRobot($);
    await app.open(systemLocale: _english);
    await endgames.openFromHome();
    await endgames.openLesson('rook.philidor');
    await endgames.openSteps();

    // A voz começa desligada: nada sai sozinho. No V2 o botão de som abre o
    // diálogo do som da lição (Canvas V2), onde a voz do Viktor liga.
    expect(voice.spokenCount, 0);
    await voice.tapSpeak();
    final sheet = SheetRobot(
      $,
      surface: LessonSoundKeys.dialog,
      close: LessonSoundKeys.close,
    );
    await sheet.expectOpen();
    expect(voice.spokenCount, 0);
    // O ✕ fecha a folha sem ligar nada; a lição segue.
    await sheet.closeWithX();
    expect(voice.spokenCount, 0);
    await voice.tapSpeak();
    await sheet.expectOpen();
    await $(LessonSoundKeys.teacherVoice).tap();
    await $.pumpAndSettle();
    await $(LessonSoundKeys.close).tap();
    await $.pumpAndSettle();

    // Ligada: o passo seguinte fala sozinho; sair da lição cala.
    var before = voice.spokenCount;
    await endgames.nextStep();
    expect(voice.spokenCount, greaterThan(before));
    final stops = voice.stops;
    await endgames.back();
    expect(voice.stops, greaterThan(stops));

    // A escolha persiste: reaberto o app, o passo fala sozinho.
    await app.restart();
    before = voice.spokenCount;
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
  }, skip: !VisibleLessons.endgameLessonIds.contains('rook.philidor'));
}
