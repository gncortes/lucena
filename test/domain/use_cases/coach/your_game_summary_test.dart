import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/models/coach/coach.dart';
import 'package:lucena/domain/use_cases/coach/opening_in_course.dart';
import 'package:lucena/domain/use_cases/coach/opening_in_pilares.dart';
import 'package:lucena/domain/use_cases/coach/your_game_summary.dart';

import '../../../../testing/coach_fixtures.dart';
import '../../../../testing/coach_your_game_fixtures.dart';

void main() {
  YourGameSummary summary({int n = 60, TimeControl? timeControl}) =>
      summarizeYourGame(
        games: YourGameFixtures.games(n),
        stats: YourGameFixtures.stats(),
        currentTime: YourGameFixtures.currentTime,
        timeControl: timeControl,
      );

  group('resumirSeuJogo', () {
    test('60 partidas: precisão, aproveitamento e variação', () {
      final r = summary();
      expect(r.games, 60);
      expect(r.few, isFalse);
      expect(r.accuracy, 75);
      expect(r.accuracyChange, 0);
      expect(r.scoreRate.wins, 30);
      expect(r.scoreRate.draws, 15);
      expect(r.scoreRate.losses, 15);
      expect(r.scoreRate.percent, 63);
      expect(r.white.games, 30);
      expect(r.black.games, 30);
    });

    test('erros por fase contam só os lances dele', () {
      final r = summary();
      expect(r.errorsByPhase[GamePhase.opening], 60);
      expect(r.errorsByPhase[GamePhase.ending], 15);
      expect(r.errorsByPhase[GamePhase.middlegame], 0);
      expect(r.phaseMostErrors, GamePhase.opening);
    });

    test('filtro de ritmo vale para todos os números', () {
      final r = summary(timeControl: TimeControl.blitz);
      expect(r.games, 20);
      expect(r.timeControls.keys, [TimeControl.blitz]);
      expect(summary().timeControls[TimeControl.bullet]?.games, 20);
    });

    test('temas ordenados pelo número de posições, da mais recente', () {
      final r = summary();
      expect(r.motifs.map((t) => t.motif), ['garfo', 'final_torres']);
      expect(r.motifs.first.positions.first.game.id, YourGameFixtures.id(0));
    });

    test('tema com partida fora do filtro some', () {
      // garfo está nas partidas 0, 2, 4, 6 e 8; bullet são as de i % 3 == 2.
      final r = summary(timeControl: TimeControl.bullet);
      expect(r.motifs.map((t) => t.motif), ['garfo', 'final_torres']);
      expect(r.motifs.first.positions.map((p) => p.game.id), [
        YourGameFixtures.id(2),
        YourGameFixtures.id(8),
      ]);
    });

    test('foco na abertura: a saída repetida em metade das partidas', () {
      final focus = summary().focus;
      expect(focus, isA<OpeningFocus>());
      final a = (focus! as OpeningFocus).opening;
      expect(a.name, 'Defesa Caro-Kann');
      expect(a.course?.part, 2);
      final s = a.exit!;
      expect((s.chessMove, s.san, s.black, s.times), (5, 'c5', true, 20));
      expect(s.recentGame, YourGameFixtures.id(1));
    });

    test('sem saída repetida, o foco vai ao tema com 3 posições', () {
      final games = [
        for (final p in YourGameFixtures.games())
          if (p.color == GameColor.white) p,
      ];
      final r = summarizeYourGame(
        games: games,
        stats: YourGameFixtures.stats(),
        currentTime: YourGameFixtures.currentTime,
      );
      expect((r.focus! as MotifFocus).motif.motif, 'garfo');
    });

    test('8 semanas, a atual sem partida', () {
      final weeks = summary().weeksAccuracy;
      expect(weeks, hasLength(8));
      expect(weeks.last, isNull);
      expect(weeks[6], isNotNull);
    });

    test('poucas partidas abaixo de 10', () {
      expect(summary(n: 9).few, isTrue);
      expect(summary(n: 10).few, isFalse);
    });

    test('nenhuma partida pronta: sem precisão e sem foco', () {
      final r = summarizeYourGame(
        games: [CoachFixtures.tiago(status: 'analisando')],
        stats: CoachStats.blank,
        currentTime: YourGameFixtures.currentTime,
      );
      expect(r.games, 0);
      expect(r.accuracy, isNull);
      expect(r.focus, isNull);
      expect(r.phaseMostErrors, isNull);
    });
  });

  group('faseDoLance', () {
    test('final com até 6 peças, abertura até o lance 12', () {
      expect(phaseOfMove(80, CoachFixtures.fenEnding), GamePhase.ending);
      expect(phaseOfMove(22, YourGameFixtures.fenOpening), GamePhase.opening);
      expect(
        phaseOfMove(24, YourGameFixtures.fenOpening),
        GamePhase.middlegame,
      );
    });
  });

  group('slotDaAbertura', () {
    test('o curso ligado pelo servidor vence', () {
      expect(
        openingSlot(
          eco: 'A00',
          name: 'Qualquer',
          color: GameColor.white,
          course: const LinkedCourse(id: 'pilares.ab3.slav3', part: 3),
        ),
        'slav',
      );
    });

    test('pela faixa de ECO e pela cor', () {
      String? slot(String eco, GameColor color, [String name = '']) =>
          openingSlot(eco: eco, name: name, color: color);
      expect(slot('B12', GameColor.black), 'caroKann');
      expect(slot('D15', GameColor.black), 'slav');
      expect(slot('B35', GameColor.black), 'dragon');
      expect(slot('E97', GameColor.black), 'kingsIndian');
      expect(slot('B12', GameColor.white), isNull);
      expect(slot('D02', GameColor.white, 'Sistema Londres'), 'london');
      expect(slot('C50', GameColor.white, 'Giuoco Piano'), isNull);
    });
  });

  group('aberturaNoPilares', () {
    TrainingLesson lessonEntry(String id) =>
        TrainingLesson(id: id, kind: TrainingLessonKind.opening, title: id);
    final resources = TrainingResources(
      lessons: [
        lessonEntry('pilares.ab1.caroKann1'),
        lessonEntry('pilares.ab1.slav1'),
        lessonEntry('pilares.ab2.caroKann2'),
        lessonEntry('pilares.ab3.caroKann3'),
      ],
    );

    test('partes na ordem do curso, destaque na primeira por fazer', () {
      final a = openingInPilares(
        slot: 'caroKann',
        resources: resources,
        state: TrainingState(
          course: TrainingCourse.pilares,
          installSeed: 'teste',
          completedLessons: const {'pilares.ab1.caroKann1': '2026-11-01'},
        ),
      )!;
      expect(a.parts.map((p) => p.number), [1, 2, 3]);
      expect(a.highlight.lessonEntry.id, 'pilares.ab2.caroKann2');
      expect(a.perfil, 'solido');
      expect(a.allDone, isFalse);
    });

    test('a parte do servidor vence a primeira por fazer', () {
      final a = openingInPilares(
        slot: 'caroKann',
        resources: resources,
        serverPart: 3,
      )!;
      expect(a.highlight.number, 3);
    });

    test('abertura fora do curso: null', () {
      expect(openingInPilares(slot: 'dragon', resources: resources), isNull);
    });
  });
}
