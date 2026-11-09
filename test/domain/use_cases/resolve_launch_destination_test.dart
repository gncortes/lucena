import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/challenge_link.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/push_alert.dart';
import 'package:lucena/domain/use_cases/resolve_launch_destination.dart';

/// Para onde o app abre, a partir do que foi lido na abertura.
void main() {
  const resolve = ResolveLaunchDestination();
  const desafio = ChallengeLink(
    fen: '8/8/8/8/8/8/8/K6k w - - 0 1',
    userSide: Side.white,
  );
  const doAviso = ChallengeLink(
    fen: '8/8/8/8/8/8/8/k6K w - - 0 1',
    userSide: Side.white,
  );
  final link = Uri.https('playlucenachess.com', '/dia');
  final linkDoAviso = Uri.https('playlucenachess.com', '/torneio');
  const aulaAberta = SchoolProgress(
    ongoing: LessonCheckpoint(lessonId: 'oposicao', step: 2),
  );
  const finalAberto = EndgameProgress(
    ongoing: LessonCheckpoint(lessonId: 'e1', step: 1),
  );
  const exercicioAberto = EndgameProgress(
    lessons: {
      'e2': EndgameLessonProgress(
        exercise: ExerciseCheckpoint(exerciseId: 'x1'),
      ),
    },
  );
  const presente = PushOpening(kind: PushKind.gift, course: 'pilares');

  group('referrer da instalação (T84)', () {
    test('só na 1ª abertura sem link nem aviso', () {
      bool le({bool opened = false, bool pushed = false, bool done = false}) =>
          resolve.readsReferrer(
            opened: opened,
            pushed: pushed,
            onboardingDone: done,
          );
      expect(le(), isTrue);
      expect(le(opened: true), isFalse);
      expect(le(pushed: true), isFalse);
      expect(le(done: true), isFalse);
    });
  });

  group('desafio que abre', () {
    test('o do link válido', () {
      final facts = LaunchFacts(opened: link, openedChallenge: desafio);
      expect(resolve.link(facts), desafio);
      expect(resolve(facts).link, desafio);
    });

    test('link inválido não abre desafio, nem o do aviso', () {
      final facts = LaunchFacts(
        opened: link,
        openedInvalid: true,
        openedChallenge: desafio,
        pushOpening: PushOpening(link: linkDoAviso),
        pushedChallenge: doAviso,
      );
      expect(resolve.link(facts), isNull);
    });

    test('sem link, o do aviso', () {
      final facts = LaunchFacts(
        pushOpening: PushOpening(link: linkDoAviso),
        pushedChallenge: doAviso,
      );
      expect(resolve.link(facts), doAviso);
      expect(resolve.pushed(facts), isTrue);
      expect(resolve.fromLink(facts), isTrue);
    });

    test('link sem desafio ainda conta como vindo de link', () {
      final facts = LaunchFacts(opened: link);
      expect(resolve.link(facts), isNull);
      expect(resolve.fromLink(facts), isTrue);
      expect(resolve.pushed(facts), isFalse);
    });

    test('sem link nem aviso', () {
      const facts = LaunchFacts();
      expect(resolve.link(facts), isNull);
      expect(resolve.fromLink(facts), isFalse);
      expect(resolve.pushed(facts), isFalse);
    });

    test('aviso com link aberto junto: não conta como aberto pelo aviso', () {
      final facts = LaunchFacts(
        opened: link,
        pushOpening: PushOpening(link: linkDoAviso),
      );
      expect(resolve.pushed(facts), isFalse);
    });
  });

  group('conferir o pacote da retomada', () {
    test('aula da Escola aberta e nada antes dela', () {
      expect(
        resolve.checksSchoolLesson(const LaunchFacts(school: aulaAberta)),
        isTrue,
      );
    });

    test('sem aula aberta, ou Escola escondida, não confere', () {
      expect(resolve.checksSchoolLesson(const LaunchFacts()), isFalse);
      expect(
        resolve.checksSchoolLesson(
          const LaunchFacts(
            school: SchoolProgress(
              ongoing: LessonCheckpoint(
                lessonId: 'oposicao',
                step: 2,
                open: false,
              ),
            ),
          ),
        ),
        isFalse,
      );
      expect(
        resolve.checksSchoolLesson(
          const LaunchFacts(school: aulaAberta, showSchool: false),
        ),
        isFalse,
      );
    });

    test('o que vem antes da retomada dispensa a conferência', () {
      final antes = [
        const LaunchFacts(conclusion: 3),
        const LaunchFacts(resumeGame: true),
        LaunchFacts(opened: link),
        const LaunchFacts(boardControlsOpen: true),
        LaunchFacts(
          pushOpening: PushOpening(link: linkDoAviso),
          pushedChallenge: doAviso,
        ),
      ];
      for (final facts in antes) {
        final comAulas = LaunchFacts(
          conclusion: facts.conclusion,
          resumeGame: facts.resumeGame,
          opened: facts.opened,
          boardControlsOpen: facts.boardControlsOpen,
          pushOpening: facts.pushOpening,
          pushedChallenge: facts.pushedChallenge,
          school: aulaAberta,
          endgames: finalAberto,
        );
        expect(resolve.checksSchoolLesson(comAulas), isFalse);
        expect(resolve.checksEndgameLessons(comAulas), isFalse);
      }
    });

    test('às cegas não dispensa a conferência', () {
      expect(
        resolve.checksSchoolLesson(
          const LaunchFacts(school: aulaAberta, resumeBlind: true),
        ),
        isTrue,
      );
    });

    test('aula de final ou exercício abertos', () {
      expect(
        resolve.checksEndgameLessons(const LaunchFacts(endgames: finalAberto)),
        isTrue,
      );
      expect(
        resolve.checksEndgameLessons(
          const LaunchFacts(endgames: exercicioAberto),
        ),
        isTrue,
      );
      expect(resolve.checksEndgameLessons(const LaunchFacts()), isFalse);
    });
  });

  group('destino', () {
    test('link válido abre a tela dele; inválido entra por cima', () {
      final valido = resolve(LaunchFacts(opened: link));
      expect(valido.uri, link);
      expect(valido.invalidLinkOnTop, isFalse);

      final invalido = resolve(LaunchFacts(opened: link, openedInvalid: true));
      expect(invalido.uri, isNull);
      expect(invalido.invalidLinkOnTop, isTrue);

      final semLink = resolve(const LaunchFacts());
      expect(semLink.uri, isNull);
      expect(semLink.invalidLinkOnTop, isFalse);
    });

    test('aceite dos Termos pendente só para a conta conectada', () {
      expect(
        resolve(const LaunchFacts(consentUid: 'u1', accountUid: 'u1'))
            .consentPending,
        isTrue,
      );
      expect(
        resolve(const LaunchFacts(consentUid: 'u1', accountUid: 'u2'))
            .consentPending,
        isFalse,
      );
      expect(
        resolve(const LaunchFacts(consentUid: 'u1')).consentPending,
        isFalse,
      );
      expect(resolve(const LaunchFacts()).consentPending, isFalse);
    });

    test('aula da Escola que sumiu do pacote não reabre', () {
      const facts = LaunchFacts(school: aulaAberta);
      expect(resolve(facts).showSchool, isTrue);
      expect(
        resolve(facts.withContent(schoolLessonFound: false)).showSchool,
        isFalse,
      );
      expect(
        resolve(facts.withContent(schoolLessonFound: true)).showSchool,
        isTrue,
      );
      expect(resolve(const LaunchFacts(showSchool: false)).showSchool, isFalse);
    });

    test('aulas de final: só as visíveis que o pacote tem', () {
      const facts = LaunchFacts(
        endgames: finalAberto,
        visibleEndgameLessons: {'e1', 'e2', 'e3'},
      );
      expect(resolve(facts).visibleEndgameLessons, {'e1', 'e2', 'e3'});
      expect(
        resolve(facts.withContent(trailLessons: {'e3', 'e1', 'e9'}))
            .visibleEndgameLessons,
        {'e3', 'e1'},
      );
      // Pacote indisponível: nenhuma reabre.
      expect(
        resolve(facts.withContent(trailLessons: {})).visibleEndgameLessons,
        isEmpty,
      );
    });

    test('withContent mantém o resto do que foi lido', () {
      final facts = LaunchFacts(
        conclusion: 2,
        opened: link,
        fromReferrer: true,
        goalAnswered: true,
        onboardingDone: true,
        schoolLessonFound: false,
      ).withContent(trailLessons: {'e1'});
      expect(facts.conclusion, 2);
      expect(facts.opened, link);
      expect(facts.fromReferrer, isTrue);
      expect(facts.goalAnswered, isTrue);
      expect(facts.onboardingDone, isTrue);
      expect(facts.schoolLessonFound, isFalse);
      expect(facts.trailLessons, {'e1'});
    });
  });

  group('depois da primeira tela', () {
    test('aviso do presente: "Abrindo o seu presente…"', () {
      expect(
        resolve(const LaunchFacts(pushOpening: presente)).followUp,
        LaunchFollowUp.gift,
      );
    });

    test('presente com link aberto junto: vale o link', () {
      expect(
        resolve(LaunchFacts(opened: link, pushOpening: presente)).followUp,
        LaunchFollowUp.none,
      );
    });

    test('aviso com link de tela abre a tela por cima', () {
      expect(
        resolve(LaunchFacts(pushOpening: PushOpening(link: linkDoAviso)))
            .followUp,
        LaunchFollowUp.pushedScreen,
      );
    });

    test('aviso com desafio: o desafio já é o destino', () {
      expect(
        resolve(
          LaunchFacts(
            pushOpening: PushOpening(link: linkDoAviso),
            pushedChallenge: doAviso,
          ),
        ).followUp,
        LaunchFollowUp.none,
      );
    });

    test('aviso sem link, ou link aberto junto: nada', () {
      expect(
        resolve(const LaunchFacts(pushOpening: PushOpening())).followUp,
        LaunchFollowUp.none,
      );
      expect(
        resolve(
          LaunchFacts(
            opened: link,
            pushOpening: PushOpening(link: linkDoAviso),
          ),
        ).followUp,
        LaunchFollowUp.none,
      );
      expect(resolve(const LaunchFacts()).followUp, LaunchFollowUp.none);
    });
  });
}
