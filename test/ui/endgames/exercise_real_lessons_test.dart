import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository_asset.dart';
import 'package:lucena/data/repositories/endgames/exercise_feedback_repository_asset.dart';
import 'package:lucena/data/repositories/school/lesson_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/use_cases/exercise_review.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/widgets/character_avatar.dart';
import 'package:lucena/ui/endgames/view_models/exercise_cubit.dart';
import 'package:lucena/ui/endgames/widgets/exercise_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/test_app.dart';

class _Assets extends AssetService {
  @override
  Future<String> loadString(String path) => io.File(path).readAsString();
}

/// As aulas REAIS em PT-BR (Rei e peão; Oposição distante, com o feedback de
/// erro) no exercício: o balão nunca mostra notação, o lance sem comentário
/// ganha a frase gerada, a lista para no lance certo e o borrar não cobre o
/// erro do aluno.
void main() {
  const kingPawn = 'basics.kingPawn';
  const opposition = 'pawns.distantOpposition';
  late EndgameTrail trail;
  late LessonTexts texts;
  late AssetExerciseFeedbackRepository feedback;

  setUpAll(() async {
    await Goldens.loadFonts();
    final repo = AssetEndgameLessonRepository(
      _Assets(),
      school: AssetLessonRepository(_Assets()),
    );
    trail = await repo.trail();
    texts = await repo.texts('pt');
    // Esquenta o cache: dentro do teste de widget o relógio é falso.
    feedback = AssetExerciseFeedbackRepository(_Assets());
    for (final (lesson, exercise) in [(kingPawn, 'e13'), (opposition, 'e09')]) {
      await feedback.findExerciseReview(
        lessonId: lesson,
        exerciseId: exercise,
        language: 'pt',
      );
      await feedback.find(
        lessonId: lesson,
        exerciseId: exercise,
        kind: 'exercise',
        turn: 1,
        fen: '8/8/8/8/8/8/8/8 w - - 0 1',
        uci: 'a1a2',
        language: 'pt',
      );
    }
  });

  Move mv(String uci) => Move.parse(uci)!;

  Future<ExerciseCubit> pump(
    WidgetTester tester,
    String lesson,
    String exercise, {
    Size size = const Size(412, 915),
    Map<String, dynamic>? extraTexts,
    bool hide = false,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    final cubit = ExerciseCubit(
      now: FakeNow(DateTime.utc(2026, 10, 11)),
      lessons: FakeEndgameLessonRepository(
        trail: trail,
        texts: extraTexts == null
            ? texts
            : LessonTexts.fromJson({...texts.toJson(), ...extraTexts}),
      ),
      progress: FakeEndgameProgressRepository(),
      characters: FakeCharacterRepository(),
      feedback: feedback,
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    await tester.runAsync(() => cubit.load(lesson, exercise, 'pt'));
    final settings = SettingsCubit(
      FakeSettingsRepository(AppSettings(exerciseHiddenMoves: hide)),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        locale: const Locale('pt'),
        child: BlocProvider.value(value: cubit, child: const ExerciseScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  Future<void> play(
    WidgetTester tester,
    ExerciseCubit cubit,
    String uci,
  ) async {
    await tester.runAsync(() async {
      await cubit.play(mv(uci));
      await cubit.explaining;
    });
    await tester.pumpAndSettle();
  }

  String speech(WidgetTester tester) => tester
      .widgetList<RichText>(
        find.descendant(
          of: find.byKey(LessonScriptKeys.speech),
          matching: find.byType(RichText),
        ),
      )
      .map((text) => text.text.toPlainText())
      .join(' ');

  Future<void> expectNoNotation(WidgetTester tester) async {
    final said = speech(tester);
    expect(ExerciseReview.hasNotation(said), isFalse, reason: said);
    expect(said, isNot(contains('{{')));
  }

  // Rei e peão e13: 1.Rc6 Rb8 2.b7 Ra7 3.Rc7. Depois de 1.Rc6 Rb8 2.b7 Ra7,
  // 3.Rb6 (c6c5) é um lance fora da linha: erro do aluno.
  testWidgets('lance certo sem comentário: frase gerada, sem notação', (
    tester,
  ) async {
    final cubit = await pump(tester, kingPawn, 'e13');
    await play(tester, cubit, 'd7c6');
    final said = speech(tester);
    expect(said, startsWith('Correto. O rei vai para c6.'));
    expect(said, contains('Esse lance faz parte da solução.'));
    expect(said, endsWith('Sua vez.'));
    await expectNoNotation(tester);
  });

  testWidgets('lance errado sem comentário: frase gerada e "Ver solução" '
      'cheio no rodapé; o balão continua em 2 linhas', (tester) async {
    final cubit = await pump(tester, kingPawn, 'e13');
    await play(tester, cubit, 'b6b7');
    final said = speech(tester);
    expect(said, startsWith('Não. '));
    expect(said, contains('Esse lance não resolve o exercício.'));
    expect(
      said,
      contains('Com erro no primeiro lance, este exercício não vale mais '),
    );
    expect(said, endsWith('Tente outro lance.'));
    await expectNoNotation(tester);
    expect(
      find.descendant(
        of: find.byKey(ExerciseKeys.footer),
        matching: find.byType(FilledButton),
      ),
      findsOneWidget,
    );
    expect(find.byKey(ExerciseKeys.showSolution), findsOneWidget);
    expect(
      tester.widget(find.byKey(ExerciseKeys.showSolution)),
      isA<FilledButton>(),
    );
    // Depois de zerar, o aluno continua jogando.
    expect(cubit.state.interactive, isTrue);
    expect(cubit.state.worth, 0);
  });

  testWidgets('a seta vermelha do lance errado fica parada', (tester) async {
    final cubit = await pump(tester, kingPawn, 'e13');
    await play(tester, cubit, 'b6b7');
    await tester.pump(const Duration(seconds: 3));
    expect(cubit.state.wrongMove, isNotNull);
  });

  group('onde a lista para', () {
    testWidgets('sem erro: no lance-chave (o primeiro do aluno), '
        'destacado, com o tabuleiro nele', (tester) async {
      final cubit = await pump(tester, kingPawn, 'e13');
      for (final uci in ['d7c6', 'b6b7', 'c6c7']) {
        await play(tester, cubit, uci);
      }
      final state = cubit.state;
      expect(state.phase, ExercisePhase.done);
      expect(state.cursorId, 'm0');
      expect(state.fen, state.review.first.fenAfter);
      expect(state.lastMove?.uci, 'd7c6');
      expect(speech(tester), startsWith('Correto. O rei vai para c6.'));
      await expectNoNotation(tester);
      expect(state.say, ExerciseSay.solved);
    });

    testWidgets('com erro: no erro, destacado, com o tabuleiro nele', (
      tester,
    ) async {
      final cubit = await pump(tester, kingPawn, 'e13');
      await play(tester, cubit, 'd7c6');
      await play(tester, cubit, 'b6b7');
      // Depois de 1.Rc6 Rb8 2.b7 Ra7: c6c5 não é a linha.
      await play(tester, cubit, 'c6c5');
      expect(cubit.state.mistakes, 1);
      await play(tester, cubit, 'c6c7');
      final state = cubit.state;
      expect(state.phase, ExercisePhase.done);
      final wrong = state.review.firstWhere((node) => node.uci == 'c6c5');
      expect(state.cursorId, wrong.id);
      expect(state.fen, wrong.fenAfter);
      expect(
        speech(tester),
        startsWith('Resolvido, mas com um erro. O rei vai para c5.'),
      );
      expect(speech(tester), contains('Esse lance não resolve'));
      await expectNoNotation(tester);
    });

    testWidgets('Ver solução: posição final; com o borrar ligado, no 1º '
        'lance', (tester) async {
      final plain = await pump(tester, kingPawn, 'e13');
      await tester.runAsync(() => plain.showSolution());
      await tester.pumpAndSettle();
      final main = plain.state.review.where((node) => node.depth == 0);
      expect(plain.state.cursorId, main.last.id);
      expect(plain.state.fen, main.last.fenAfter);
      await expectNoNotation(tester);

      final covered = await pump(tester, kingPawn, 'e13', hide: true);
      await tester.runAsync(() => covered.showSolution(hidden: true));
      await tester.pumpAndSettle();
      final first = covered.state.review.first;
      expect(covered.state.cursorId, first.id);
      expect(covered.state.fen, first.fenAfter);
      expect(covered.state.seen, {first.id});
      expect(
        speech(tester),
        contains('Clique nos lances cobertos para vê-los.'),
      );
      await expectNoNotation(tester);
    });
  });

  testWidgets('borrar ligado não cobre o lance errado do aluno, mesmo '
      'previsto pela aula', (tester) async {
    final cubit = await pump(tester, kingPawn, 'e13', hide: true);
    await play(tester, cubit, 'd7c6');
    await play(tester, cubit, 'b6b7');
    await play(tester, cubit, 'c6c5');
    await play(tester, cubit, 'c6c7');
    final wrong = cubit.state.review.firstWhere((node) => node.uci == 'c6c5');
    expect(cubit.state.seen, contains(wrong.id));
    expect(find.byKey(LessonScriptKeys.hiddenMove(wrong.id)), findsNothing);
    expect(find.byKey(LessonScriptKeys.move(wrong.id)), findsOneWidget);
    // As outras variantes continuam cobertas.
    final others = cubit.state.review.where(
      (node) => node.depth > 0 && node.id != wrong.id,
    );
    for (final node in others) {
      expect(cubit.state.seen, isNot(contains(node.id)));
    }
  });

  group('a frase de abertura', () {
    testWidgets('1 erro: "Resolvido, mas com um erro."', (tester) async {
      final cubit = await pump(tester, kingPawn, 'e13');
      await play(tester, cubit, 'd7c6');
      await play(tester, cubit, 'b6b7');
      await play(tester, cubit, 'c6c5');
      await play(tester, cubit, 'c6c7');
      expect(speech(tester), contains('Resolvido, mas com um erro.'));
    });

    testWidgets('só dica: "Resolvido, mas com uma dica."', (tester) async {
      final cubit = await pump(tester, kingPawn, 'e13');
      await tester.runAsync(() => cubit.askHint());
      await tester.pumpAndSettle();
      for (final uci in ['d7c6', 'b6b7', 'c6c7']) {
        await play(tester, cubit, uci);
      }
      final said = speech(tester);
      expect(said, startsWith('Resolvido, mas com uma dica.'));
      expect(said, isNot(contains('erro')));
    });

    testWidgets('2 erros: "Resolvido, mas com 2 erros."', (tester) async {
      final cubit = await pump(tester, kingPawn, 'e13');
      await play(tester, cubit, 'b6b7');
      await play(tester, cubit, 'd7e7');
      for (final uci in ['d7c6', 'b6b7', 'c6c7']) {
        await play(tester, cubit, uci);
      }
      expect(speech(tester), startsWith('Resolvido, mas com 2 erros.'));
    });
  });

  testWidgets('Oposição distante: o feedback com lances escritos não vai ao '
      'balão (frase gerada no lugar)', (tester) async {
    final cubit = await pump(tester, opposition, 'e09');
    await play(tester, cubit, 'd2d3');
    final said = speech(tester);
    expect(said, startsWith('Não. O peão avança para d3.'));
    expect(said, endsWith('Tente outro lance.'));
    await expectNoNotation(tester);
    await tester.runAsync(() => cubit.askHint());
    await tester.pumpAndSettle();
    await expectNoNotation(tester);
  });

  testWidgets('o enunciado com citação marcada mostra só o nome', (
    tester,
  ) async {
    final cubit = await pump(
      tester,
      kingPawn,
      'e13',
      extraTexts: {
        '$kingPawn.ex.e13':
            'Partida ({{Matanović|aleksandar-matanovic}}, 1982).',
      },
    );
    expect(cubit.state.sayTexts, isNotEmpty);
    final said = speech(tester);
    expect(said, contains('Matanović'));
    expect(said, isNot(contains('{{')));
    expect(said, isNot(contains('aleksandar')));
  });

  group('o balão: 2 linhas e a letra de 16, em andamento e resolvido', () {
    final long = List.filled(
      12,
      'O rei vai a c6 e deixa a casa b8 livre para o rei preto.',
    ).join(' ');

    Text lines(WidgetTester tester) => tester.widget<Text>(
      find
          .descendant(
            of: find.byKey(LessonScriptKeys.speech),
            matching: find.byType(Text),
          )
          .first,
    );

    testWidgets('em andamento: corta em 2 linhas, 16 sp, o clique abre a '
        'folha', (tester) async {
      await pump(
        tester,
        kingPawn,
        'e13',
        extraTexts: {'$kingPawn.ex.e13': long},
      );
      final text = lines(tester);
      expect(text.maxLines, 2);
      expect(text.style?.fontSize ?? text.textSpan?.style?.fontSize, 16);
      await tester.tap(find.byKey(LessonScriptKeys.speech));
      await tester.pumpAndSettle();
      expect(find.byKey(LessonScriptKeys.speechSheet), findsOneWidget);
    });

    testWidgets('resolvido: mesma letra de 16 e reticências', (tester) async {
      final cubit = await pump(tester, kingPawn, 'e13');
      for (final uci in ['d7c6', 'b6b7', 'c6c7']) {
        await play(tester, cubit, uci);
      }
      final text = lines(tester);
      expect(text.maxLines, 2);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(text.style?.fontSize ?? text.textSpan?.style?.fontSize, 16);
    });
  });

  testWidgets('360×640: a primeira linha da lista não fica meio escondida', (
    tester,
  ) async {
    final cubit = await pump(
      tester,
      kingPawn,
      'e13',
      size: const Size(360, 640),
    );
    for (final uci in ['d7c6', 'b6b7', 'c6c7']) {
      await play(tester, cubit, uci);
    }
    expect(tester.takeException(), isNull);
    final page = tester.getRect(find.byKey(ExerciseKeys.page));
    final first = tester.getRect(find.byKey(LessonScriptKeys.move('m0')));
    final fullyBelow = first.top >= page.bottom - 0.5;
    final fullyIn = first.bottom <= page.bottom + 0.5;
    expect(fullyBelow || fullyIn, isTrue, reason: '$first em $page');
  });

  testWidgets('a folha tem o cabeçalho do exercício: borrar com a lista '
      'completa, e o fundo lavanda', (tester) async {
    final cubit = await pump(tester, kingPawn, 'e13');
    for (final uci in ['d7c6', 'b6b7', 'c6c7']) {
      await play(tester, cubit, uci);
    }
    await tester.tap(find.byKey(LessonScriptKeys.speech));
    await tester.pumpAndSettle();
    final sheet = find.byKey(LessonScriptKeys.speechSheet);
    expect(sheet, findsOneWidget);
    expect(
      find.descendant(
        of: sheet,
        matching: find.byKey(ExerciseKeys.hiddenMovesToggle),
      ),
      findsOneWidget,
    );
    final context = tester.element(sheet);
    final material = tester.widget<Material>(
      find.ancestor(of: sheet, matching: find.byType(Material)).first,
    );
    expect(material.color, Theme.of(context).colorScheme.surfaceContainerLow);
  });

  group('geometria do canvas (PropV2ExA4, A4P360, A7)', () {
    testWidgets(
      '360×640: a letra do balão continua 16 e o tabuleiro deixa 8 dp '
      'até o rodapé',
      (tester) async {
        await pump(
          tester,
          kingPawn,
          'e13',
          size: const Size(360, 640),
          extraTexts: {'$kingPawn.ex.e13': 'Jogue.'},
        );
        final text = tester.widget<Text>(
          find
              .descendant(
                of: find.byKey(LessonScriptKeys.speech),
                matching: find.byType(Text),
              )
              .first,
        );
        expect(text.style?.fontSize ?? text.textSpan?.style?.fontSize, 16);
        final board = tester.getRect(find.byKey(ExerciseKeys.board));
        final footer = tester.getRect(find.byKey(ExerciseKeys.footer));
        expect(footer.top - board.bottom, greaterThanOrEqualTo(8 - 1));
        expect(board.width, lessThanOrEqualTo(360));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('360×740: 20 dp entre a barra de cima e o balão de 2 linhas', (
      tester,
    ) async {
      await pump(
        tester,
        kingPawn,
        'e13',
        size: const Size(360, 740),
        extraTexts: {'$kingPawn.ex.e13': 'Jogue.'},
      );
      final bar = tester.getRect(find.byType(AppBar));
      final balloon = tester.getRect(find.byKey(LessonScriptKeys.speech));
      expect(balloon.top - bar.bottom, closeTo(20, 1));
      expect(balloon.height, closeTo(76 + 10, 1)); // 76 + a ponta
    });

    testWidgets('a folha: retrato de 56 e margem de 16', (tester) async {
      await pump(tester, kingPawn, 'e13');
      await tester.tap(find.byKey(LessonScriptKeys.speech));
      await tester.pumpAndSettle();
      final avatar = tester.getRect(
        find
            .descendant(
              of: find.byKey(LessonScriptKeys.speechSheet),
              matching: find.byType(CharacterAvatar),
            )
            .first,
      );
      expect(avatar.width, closeTo(56, 1));
      expect(avatar.left, closeTo(16, 1));
    });

    testWidgets('360×640: a nota do borrar tem no máximo 2 linhas', (
      tester,
    ) async {
      final cubit = await pump(
        tester,
        kingPawn,
        'e13',
        size: const Size(360, 640),
        hide: true,
      );
      await tester.runAsync(() => cubit.showSolution(hidden: true));
      await tester.pumpAndSettle();
      final tip = tester.getRect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText() ==
                  'Clique nos lances cobertos para vê-los.',
        ),
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText() ==
                  'Clique nos lances cobertos para vê-los.',
        ),
      );
      // Com a fonte real (Roboto), não a Ahem dos testes.
      expect(paragraph.size.height, lessThanOrEqualTo(2 * 24 + 1));
      expect(tip.height, lessThanOrEqualTo(2 * 24 + 1));
    });
  });

  testWidgets('a estrela da AppBar é neutra, na cor do texto', (tester) async {
    await pump(tester, kingPawn, 'e13');
    final star = tester.widget<Icon>(find.byKey(ExerciseKeys.stars));
    final context = tester.element(find.byKey(ExerciseKeys.stars));
    expect(star.color, Theme.of(context).colorScheme.onSurface);
  });
}
