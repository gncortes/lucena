import 'dart:convert';
import 'dart:io' as io;
import 'dart:ui' as ui;

import 'package:dartchess/dartchess.dart';
import 'package:chessground/chessground.dart' show ChessgroundImages;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/ui/core/board/board_settings_ui.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_cubit.dart';
import 'package:lucena/ui/lesson_script/widgets/lesson_script_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_kpk_repository.dart';
import '../../../testing/fakes/fake_lesson_script_repository.dart';
import '../../../testing/fakes/fake_lesson_source.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/script_fixture.dart';
import '../../../testing/test_app.dart';

const matrixPath = 'docs/qa/T85-integral/lesson-snapshots.json';
const capturePath = String.fromEnvironment('T85_CAPTURE');

/// Static visual fixtures. These do not certify transitions or persistence.
class _CanvasCubit extends LessonScriptCubit {
  _CanvasCubit(this.snapshot, this.data, {required bool school})
    : super(
        lessonId: 'canvas.fixture',
        partId: 'fixture',
        scriptPath: 'fixture.json',
        language: 'pt',
        scripts: FakeLessonScriptRepository(scriptFixture(), scriptTexts()),
        kpk: FakeKpkRepository(FakeKpkOracle()),
        source: FakeLessonSource(endgame: !school),
      );
  final LessonScriptState snapshot;
  final Map<String, dynamic> data;
  @override
  List<String> get answerChoices =>
      (data['id'] as String).endsWith('AbValeAqui')
      ? [
          for (final button
              in (data['imports'] as List).cast<Map<String, dynamic>>().where(
                (p) => p['name'] == 'CompBotao',
              ))
            button['rotulo'] as String,
        ]
      : const [];
  @override
  Future<void> answerChoice(int index) async {}
  @override
  int get progressSteps =>
      int.tryParse(
        _component(data, 'CompProgressoPassos')['total'] as String? ?? '',
      ) ??
      0;
  @override
  double get progressValue =>
      double.tryParse(
        _component(data, 'CompProgressoPassos')['atual'] as String? ?? '',
      ) ??
      0;
  @override
  bool get canHint => _component(data, 'CompRodapeLicao')['lampada'] == 'true';
  @override
  Future<void> hint() async {}
  @override
  bool get canAnalyze =>
      _component(data, 'CompRodapeLicao')['analisar'] == 'true';
  @override
  Future<void> start() async => emit(snapshot);
  @override
  void demoVoice({required bool speaking}) {}
}

Map<String, dynamic> _component(Map<String, dynamic> data, String name) =>
    (data['imports'] as List)
        .cast<Map<String, dynamic>>()
        .where((p) => p['name'] == name)
        .firstOrNull ??
    {};

ScriptAction? _action(Object? label) => switch (label) {
  'Próxima etapa' => ScriptAction.proximaEtapa,
  'Partidas-modelo' || 'Praticar' => ScriptAction.proximaEtapa,
  'Tentar de novo' => ScriptAction.tentarDeNovo,
  'Ver a solução' ||
  'Ver solução' ||
  'Ver resposta' => ScriptAction.verResposta,
  'Rever a ideia' => ScriptAction.reverIdeia,
  null || '' => null,
  _ => ScriptAction.continuar,
};

LessonScriptState _state(Map<String, dynamic> data) {
  final name = data['id'] as String;
  final footer = _component(data, 'CompRodapeLicao');
  final board = _component(data, 'CompTabuleiro');
  final speech = _component(data, 'CompBalao');
  final demo = footer['demo'] as String? ?? '';
  final theory = footer['teoria'] as String? ?? '';
  final stage = name.contains('Demo') || name.contains('Modelo')
      ? 1
      : RegExp('Pratica|ValeAqui|Armadilha|Tarefa|Mate').hasMatch(name)
      ? 2
      : 0;
  final phase = footer['rotulo'] == 'Próxima partida'
      ? ScriptPhase.fimExemplo
      : name.contains('Errou')
      ? ScriptPhase.refutacao
      : name.contains('Acertou')
      ? ScriptPhase.praticaFim
      : footer['rotulo'] == 'Próxima etapa'
      ? ScriptPhase.fimEtapa
      : stage == 2
      ? ScriptPhase.praticaVez
      : ScriptPhase.entrada;
  final parts = (_component(data, 'CompNotacao')['lances'] as String? ?? '')
      .replaceAll('|', ' ')
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty);
  final moves = <ScriptMoveEntry>[];
  var number = 1;
  var side = Side.white;
  for (final token in parts) {
    final count = int.tryParse(token.replaceAll('.', ''));
    if (count != null) {
      number = count;
      side = Side.white;
      continue;
    }
    moves.add(
      ScriptMoveEntry(
        id: '${moves.length}',
        san: token.replaceAll('*', ''),
        displaySan: token.replaceAll('*', ''),
        number: number,
        side: side,
        variant: false,
      ),
    );
    if (side == Side.black) number++;
    side = side == Side.white ? Side.black : Side.white;
  }
  return LessonScriptState(
    ready: true,
    stageIndex: stage,
    stageCount: 3,
    stageId: ['ideia', 'demos', 'pratica'][stage],
    phase: phase,
    fen: board['fen'] as String,
    orientation: board['orientation'] == 'pretas' ? Side.black : Side.white,
    lastMove: board['last-move'] as String?,
    arrows: [
      for (final arrow in (board['arrows'] as String? ?? '').split(','))
        if (arrow.length >= 4)
          ScriptArrow(
            arrow.substring(0, 2),
            arrow.substring(2, 4),
            arrow.contains(':red')
                ? 'r'
                : arrow.contains(':blue')
                ? 'b'
                : 'g',
          ),
    ],
    speech: [speech['texto'] as String? ?? ''],
    primary: footer['sem-principal'] == 'true'
        ? null
        : _action(footer['rotulo']),
    secondary: _action(footer['secundario']),
    canBack: footer['voltar'] == 'true',
    stars: (board['estrelas'] as String? ?? '')
        .split(',')
        .where((s) => s.isNotEmpty)
        .toList(),
    moves: moves,
    currentMoveId: parts.any((token) => token.endsWith('*'))
        ? moves.lastOrNull?.id
        : null,
    tone: name.contains('Errou')
        ? ScriptTone.bad
        : name.contains('Acertou')
        ? ScriptTone.good
        : ScriptTone.neutral,
    demo: demo.isNotEmpty || theory.isNotEmpty
        ? ScriptDemo(
            playing: (demo.isNotEmpty ? demo : theory) == 'tocando',
            ended: demo == 'fim',
            progress: double.tryParse(footer['anel'] as String? ?? '') ?? 0,
            remaining: const Duration(hours: 1),
            tick: 0,
            speaking: true,
            canStepBack: footer['lance-anterior'] == 'true',
            full: demo.isNotEmpty,
          )
        : null,
  );
}

/// Samples the actual hit path through ancestor clips, rather than trusting
/// the widget's nominal size or a single point at its centre.
double _contiguousVerticalHitExtent(WidgetTester tester, Finder button) {
  final height = tester.getSize(button).height;
  const step = .5;
  var longest = 0, current = 0;
  for (var y = step / 2; y < height; y += step) {
    final alignment = Alignment(0, 2 * y / height - 1);
    if (button.hitTestable(at: alignment).evaluate().isNotEmpty) {
      current++;
      if (current > longest) longest = current;
    } else {
      current = 0;
    }
  }
  return longest * step;
}

// Existing board geometry measured by independent QA final5. The base Canvas
// is the same block at 412x917, two dp taller than its 412x915 adaptation.
const _choiceBoardTops = <(int, int), double>{
  (412, 917): 325.5,
  (360, 740): 234.5,
  (360, 800): 248.5,
  (384, 832): 287,
  (393, 873): 303,
  (412, 915): 324.5,
  (414, 896): 314,
};

void main() {
  final matrix = io.File(matrixPath);
  if (!matrix.existsSync()) {
    test(
      'Canvas source fixtures are private and optional on public CI',
      () {},
      skip: true,
    );
    return;
  }
  final fixtures = (jsonDecode(matrix.readAsStringSync()) as List)
      .cast<Map<String, dynamic>>()
      .toList();
  final choiceFixture = fixtures.singleWhere((f) => f['id'] == 'AbValeAqui');
  for (final (width, height) in [
    (360, 740),
    (360, 800),
    (384, 832),
    (393, 873),
    (412, 915),
    (414, 896),
  ]) {
    fixtures.add({
      ...choiceFixture,
      'id': 'Adapt${width}x${height}AbValeAqui',
      'size': [width, height],
    });
  }
  final choiceMetrics = <Map<String, Object?>>[];
  setUpAll(Goldens.loadFonts);
  for (final data in fixtures) {
    testWidgets('Canvas stages ${data['id']}', (tester) async {
      final size = Size(
        (data['size'][0] as num).toDouble(),
        (data['size'][1] as num).toDouble(),
      );
      final (top, bottom) = switch ((size.width.toInt(), size.height.toInt())) {
        (360, 640) || (360, 740) => (24.0, 48.0),
        (360, 800) => (32.0, 48.0),
        (384, 832) || (393, 873) => (32.0, 24.0),
        _ => (52.0, 24.0),
      };
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1
        ..padding = FakeViewPadding(top: top, bottom: bottom)
        ..viewPadding = FakeViewPadding(top: top, bottom: bottom);
      addTearDown(tester.view.reset);
      final shadows = debugDisableShadows;
      debugDisableShadows = false;
      try {
        final settings = SettingsCubit(
          FakeSettingsRepository(),
          languages: AppLanguage.selectable,
        );
        await settings.load();
        addTearDown(settings.close);
        final speech = SpeechCubit(
          FakeVoiceRepository(settings: const VoiceSettings(enabled: true)),
        );
        await speech.load();
        addTearDown(speech.close);
        final state = _state(data);
        final cubit = _CanvasCubit(
          state,
          data,
          school: '${data['id']}'.contains('Escola'),
        );
        addTearDown(cubit.close);
        final title = _component(data, 'CompTopBar')['title'] as String;
        final boundary = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: TestApp(
              locale: const Locale('pt'),
              settingsCubit: settings,
              speechCubit: speech,
              child: RepositoryProvider<CharacterRepository>(
                create: (_) => FakeCharacterRepository(),
                child: BlocProvider<LessonScriptCubit>.value(
                  value: cubit,
                  child: Navigator(
                    onGenerateInitialRoutes: (_, _) => [
                      MaterialPageRoute<void>(builder: (_) => const SizedBox()),
                      MaterialPageRoute<void>(
                        builder: (_) => LessonScriptScreen(
                          title: Future.value(title),
                          previewTitle: title,
                          previewTeacher: FakeCharacterRepository.viktor,
                          onAnalyze: (fen) => expect(fen, state.fen),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.runAsync(() async {
          await ChessgroundImages.instance.loadAll(
            PieceStyle.cburnett.assets,
            devicePixelRatio: 1,
          );
          await precacheImage(
            AssetImage(FakeCharacterRepository.viktor.imageFor(null)),
            tester.element(find.byKey(LessonScriptKeys.screen)),
          );
        });
        await tester.pump(const Duration(seconds: 1));
        expect(
          ChessgroundImages.instance.isAllLoaded(PieceStyle.cburnett.assets),
          isTrue,
        );
        if (capturePath.isNotEmpty) {
          await tester.runAsync(() async {
            final box =
                boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final picture = await box.toImage(pixelRatio: 2);
            final bytes = await picture.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final target = io.File('$capturePath/${data['id']}.png');
            await target.parent.create(recursive: true);
            await target.writeAsBytes(bytes!.buffer.asUint8List());
            picture.dispose();
          });
        }
        expect(find.byKey(LessonScriptKeys.board), findsOneWidget);
        if ((data['id'] as String).endsWith('AbValeAqui')) {
          final boardRect = tester.getRect(find.byKey(LessonScriptKeys.board));
          final expectedTop =
              _choiceBoardTops[(size.width.toInt(), size.height.toInt())]!;
          expect(boardRect.left, closeTo(0, .5));
          expect(boardRect.top, closeTo(expectedTop, .5));
          expect(boardRect.width, closeTo(size.width, .5));
          expect(boardRect.height, closeTo(size.width, .5));
          final page = tester.getRect(find.byKey(LessonScriptKeys.page));
          final footer = tester.getRect(find.byKey(LessonScriptKeys.footer));
          final answers = <Map<String, Object?>>[];
          for (var i = 0; i < 2; i++) {
            final button = find.byKey(LessonScriptKeys.answerChoice(i));
            final rect = tester.getRect(button);
            final hitExtent = _contiguousVerticalHitExtent(tester, button);
            expect(
              hitExtent,
              greaterThanOrEqualTo(44),
              reason:
                  '${data['id']} answer $i must expose a contiguous real 44dp hit target',
            );
            expect(rect.top, greaterThanOrEqualTo(boardRect.bottom));
            expect(rect.bottom, lessThanOrEqualTo(footer.bottom));
            answers.add({
              'index': i,
              'nominalHeight': rect.height,
              'top': rect.top,
              'bottom': rect.bottom,
              'contiguousHitHeight': hitExtent,
              'inFooter': rect.top >= footer.top,
            });
          }
          choiceMetrics.add({
            'id': data['id'],
            'width': size.width,
            'height': size.height,
            'board': [
              boardRect.left,
              boardRect.top,
              boardRect.width,
              boardRect.height,
            ],
            'availableBelowBoard': page.bottom - boardRect.bottom,
            'answers': answers,
          });
          if (capturePath.isNotEmpty) {
            await tester.runAsync(() async {
              await io.File('$capturePath/choice-metrics.json').writeAsString(
                const JsonEncoder.withIndent('  ').convert(choiceMetrics),
              );
            });
          }
        }
        expect(find.byKey(LessonScriptKeys.close), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      } finally {
        debugDisableShadows = shadows;
      }
    });
  }
}
