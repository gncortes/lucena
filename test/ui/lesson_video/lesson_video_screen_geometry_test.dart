import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/ui/core/keys/lesson_video_keys.dart';
import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:lucena/ui/lesson_video/view_models/lesson_video_cubit.dart';
import 'package:lucena/ui/lesson_video/widgets/lesson_video_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../testing/board_center.dart';
import '../../../testing/fakes/fake_lesson_script_repository.dart';
import '../../../testing/fakes/fake_lesson_video_repository.dart';
import '../../../testing/fakes/fake_video_interruptions_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/script_fixture.dart';
import '../../../testing/test_app.dart';

/// Os aparelhos do contrato da aula em vídeo (dp, densidade 1, barras 24/32).
const _aparelhos = [
  AparelhoA8(Size(360, 740)),
  AparelhoA8(Size(393, 852)),
  AparelhoA8(Size(412, 917)),
];

void _setView(WidgetTester tester, AparelhoA8 aparelho) {
  final padding = FakeViewPadding(top: aparelho.status, bottom: aparelho.nav);
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = aparelho.size
    ..viewPadding = padding
    ..padding = padding;
  addTearDown(tester.view.reset);
}

Future<LessonVideoCubit> _pump(
  WidgetTester tester, {
  AparelhoA8 aparelho = const AparelhoA8(Size(412, 917)),
  String stage = 'ideia',
  VoidCallback? onGlossary,
  VoidCallback? onNextStage,
}) async {
  _setView(tester, aparelho);
  final settings = SettingsCubit(
    FakeSettingsRepository(const AppSettings()),
    languages: AppLanguage.selectable,
  );
  addTearDown(settings.close);
  await settings.load();
  final cubit = LessonVideoCubit(
    scripts: FakeLessonScriptRepository(scriptFixture(), scriptTexts()),
    videos: FakeLessonVideoRepository(),
    interruptions: FakeVideoInterruptionsRepository(),
    now: FakeNow(DateTime(2026, 11, 23, 10)),
    lessonId: 'pawns.test',
    partId: 'distant',
    scriptPath: 'roteiro.json',
    stage: stage,
    autoplay: false,
    ticker: (_, _) => null,
  );
  addTearDown(cubit.close);
  await tester.pumpWidget(
    TestApp(
      locale: const Locale('pt'),
      settingsCubit: settings,
      child: BlocProvider.value(
        value: cubit,
        child: LessonVideoScreen(
          title: 'Oposição distante',
          onGlossary: onGlossary,
          onNextStage: onNextStage,
        ),
      ),
    ),
  );
  await cubit.start();
  await tester.pump(const Duration(milliseconds: 300));
  return cubit;
}

Rect _rect(WidgetTester tester, Finder f) => tester.getRect(f);

Finder _balloon() => find
    .ancestor(
      of: find.byKey(LessonVideoKeys.caption),
      matching: find.byType(DecoratedBox),
    )
    .first;

void main() {
  for (final aparelho in _aparelhos) {
    testWidgets('tabuleiro centrado no corpo e sem sobrepor nada ($aparelho)', (
      tester,
    ) async {
      await _pump(tester, aparelho: aparelho);
      final board = maiorTabuleiro(tester);
      final appBarBottom = _rect(tester, find.byType(LucenaAppBar)).bottom;
      final bodyBottom = _rect(
        tester,
        find.byKey(LessonVideoKeys.screen),
      ).bottom;
      final bodyCenter = (appBarBottom + bodyBottom) / 2;
      expect(
        board.center.dy,
        closeTo(bodyCenter, 4),
        reason:
            '$aparelho: centro ${board.center.dy} x corpo $bodyCenter '
            '($appBarBottom–$bodyBottom), $board',
      );
      expect(board.top, greaterThanOrEqualTo(appBarBottom));

      final balloon = _rect(tester, _balloon());
      final bar = _rect(tester, find.byKey(LessonVideoKeys.bar));
      final play = _rect(tester, find.byKey(LessonVideoKeys.playPause));
      for (final (name, r) in [
        ('balão', balloon),
        ('barra', bar),
        ('controles', play),
      ]) {
        expect(
          board.overlaps(r),
          isFalse,
          reason: '$aparelho: tabuleiro $board sobrepõe $name $r',
        );
      }
      expect(balloon.bottom, lessThanOrEqualTo(board.top));
      expect(bar.top, greaterThanOrEqualTo(board.bottom));
      if (aparelho.size.width == 360) {
        expect(
          board.width,
          greaterThanOrEqualTo(300),
          reason: '$aparelho: lado ${board.width}',
        );
      }
      // Documenta o lado medido (aparece com --reporter expanded).
      debugPrint('$aparelho: lado do tabuleiro ${board.width}');
    });
  }

  testWidgets('no fim, o rodapé (voltar ao início, próxima etapa) aparece', (
    tester,
  ) async {
    var next = 0;
    final cubit = await _pump(
      tester,
      stage: 'demos',
      onNextStage: () => next++,
    );
    expect(find.byKey(LessonVideoKeys.endRestart), findsNothing);
    cubit.seek(cubit.state.total);
    await tester.pump(const Duration(milliseconds: 300));
    expect(cubit.state.ended, isTrue);
    expect(find.byKey(LessonVideoKeys.endRestart), findsOneWidget);
    expect(find.byKey(LessonVideoKeys.endNext), findsOneWidget);
    expect(find.byKey(LessonVideoKeys.playPause), findsNothing);

    await tester.tap(find.byKey(LessonVideoKeys.endNext));
    await tester.pump();
    expect(next, 1);

    await tester.tap(find.byKey(LessonVideoKeys.endRestart));
    await tester.pump(const Duration(milliseconds: 300));
    expect(cubit.state.position, Duration.zero);
    expect(cubit.state.playing, isTrue);
    expect(find.byKey(LessonVideoKeys.playPause), findsOneWidget);
  });

  testWidgets('CC troca o balão por "Legenda desligada" e volta', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byKey(LessonVideoKeys.caption), findsOneWidget);
    await tester.tap(find.byKey(LessonVideoKeys.captions));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(LessonVideoKeys.caption), findsNothing);
    final off = tester.getRect(find.byKey(LessonVideoKeys.captionsOff));
    expect(off.height, 48, reason: 'linha de 48 do protótipo');
    await tester.tap(find.byKey(LessonVideoKeys.captions));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(LessonVideoKeys.caption), findsOneWidget);
    expect(find.byKey(LessonVideoKeys.captionsOff), findsNothing);
  });

  testWidgets('o livro do topo chama o callback do Glossário', (tester) async {
    var opened = 0;
    await _pump(tester, onGlossary: () => opened++);
    await tester.tap(find.byKey(LessonVideoKeys.glossaryButton));
    await tester.pump();
    expect(opened, 1);
  });
}
