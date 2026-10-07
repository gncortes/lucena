import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:dartchess/dartchess.dart';
import 'package:lucena/ui/blind/view_models/blind_game_cubit.dart';
import 'package:lucena/ui/blind/widgets/blind_game_screen.dart';
import 'package:lucena/ui/core/keys/blind_keys.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_blind_log_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_speech_input_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeSpeechInputRepository input;
  late BlindGameCubit cubit;

  Future<void> pump(WidgetTester tester, {bool permitted = true}) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    input = FakeSpeechInputRepository(permitted: permitted, grants: false);
    cubit = BlindGameCubit(
      restartDelay: Duration.zero,
      releaseWait: Duration.zero,
      opponent: FakeOpponentRepository(),
      voice: FakeVoiceRepository()..autoFinish = true,
      input: input,
      log: FakeBlindLogRepository(),
      now: FakeNow(DateTime.utc(2026, 10, 7)),
      thinkTime: Duration.zero,
    );
    addTearDown(cubit.close);
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await cubit.load(
      fen: '4k3/8/8/8/8/8/8/R3K3 w - - 0 1',
      userSide: Side.white,
      kind: OpponentKind.maia,
      level: 1000,
      language: 'en-US',
      phrases: blindPhrases(l10n),
    );
    await cubit.start();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        child: BlocProvider.value(value: cubit, child: const BlindGameScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a vez do jogador, só as casas; o microfone escuta e o lance '
      'dito é jogado', (tester) async {
    await pump(tester);
    expect(find.text('Your move'), findsOneWidget);
    expect(find.byKey(BlindKeys.board), findsNothing);

    // Segura para falar; soltar envia.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(BlindKeys.mic)),
    );
    await tester.pump(const Duration(milliseconds: 600));
    // Gravando: o tempo e as ondas no balão.
    expect(find.byKey(BlindKeys.recording), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);
    input.hear(['rook a7']);
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();
    // Só a torre vai a a7: o app propõe e espera o "sim".
    expect(find.byKey(BlindKeys.proposal), findsOneWidget);
    await tester.tap(find.byKey(BlindKeys.confirm));
    await tester.pumpAndSettle();
    expect(find.byKey(BlindKeys.status), findsOneWidget);
    expect(find.text('Your move'), findsOneWidget);
    // O lance da máquina pode ser ouvido de novo.
    expect(find.text('Hear again'), findsOneWidget);
  });

  testWidgets('não entendeu: o recado fica junto do microfone', (tester) async {
    await pump(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(BlindKeys.mic)),
    );
    await tester.pump(const Duration(milliseconds: 600));
    input.hear(['good morning']);
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();
    // O recado sobe num aviso no topo; o balão continua no convite.
    expect(find.byKey(BlindKeys.toast), findsOneWidget);
    expect(find.textContaining('good morning'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(BlindKeys.hint)).data,
      'Tap or hold to talk',
    );
  });

  testWidgets('o tabuleiro com as peças aceita o toque', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(BlindKeys.view(BlindView.board)));
    await tester.pumpAndSettle();
    expect(find.byKey(BlindKeys.board), findsOneWidget);
  });

  testWidgets('sem microfone: a explicação antes do pedido; recusar deixa o '
      'toque e o aviso', (tester) async {
    await pump(tester, permitted: false);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(BlindKeys.mic)),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Use the microphone?'), findsOneWidget);
    await tester.tap(find.byKey(BlindKeys.micDeny));
    await tester.pumpAndSettle();
    expect(
      find.text('No microphone: play by tapping the board.'),
      findsOneWidget,
    );
    expect(find.byKey(BlindKeys.board), findsOneWidget);
  });

  testWidgets('um toque rápido abre a gravação sem segurar: descartar e '
      'enviar nos botões, e o lance aparece escrito para confirmar', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(BlindKeys.mic));
    await tester.pump();
    expect(find.byKey(BlindKeys.recording), findsOneWidget);
    expect(find.byKey(BlindKeys.discard), findsOneWidget);

    // Descartar fecha a gravação.
    await tester.tap(find.byKey(BlindKeys.discard));
    await tester.pumpAndSettle();
    expect(find.byKey(BlindKeys.recording), findsNothing);

    // De novo: fala e toca no enviar.
    await tester.tap(find.byKey(BlindKeys.mic));
    await tester.pump();
    input.hear(['rook a7']);
    await tester.pump();
    await tester.tap(find.byKey(BlindKeys.mic));
    await tester.pumpAndSettle();
    expect(find.byKey(BlindKeys.proposal), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(BlindKeys.proposal)).data, 'Rook a7');
    await tester.tap(find.byKey(BlindKeys.confirm));
    await tester.pumpAndSettle();
    expect(cubit.state.lastUser, 'Ra7');
  });

  testWidgets('arrastar o dedo para longe cancela a gravação', (tester) async {
    await pump(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(BlindKeys.mic)),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(-150, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Your move'), findsOneWidget);
    expect(input.cancels, 1);
  });

  testWidgets('digitar o lance no campo da barra', (tester) async {
    await pump(tester);
    // O campo já está na barra; com texto, o microfone vira o enviar.
    expect(find.byKey(BlindKeys.mic), findsOneWidget);
    await tester.enterText(find.byKey(BlindKeys.typeField), 'Ra7');
    await tester.pump();
    expect(find.byKey(BlindKeys.mic), findsNothing);
    await tester.tap(find.byKey(BlindKeys.typeSend));
    await tester.pumpAndSettle();
    expect(find.byKey(BlindKeys.status), findsOneWidget);
  });

  testWidgets('tocar nas casas do tabuleiro vazio joga o lance', (
    tester,
  ) async {
    await pump(tester);
    final board = tester.getRect(find.byKey(BlindKeys.emptyBoard));
    final cell = board.width / 8;
    // a1 e depois a7, com as brancas embaixo.
    await tester.tapAt(board.bottomLeft + Offset(cell / 2, -cell / 2));
    await tester.pump();
    await tester.tapAt(board.topLeft + Offset(cell / 2, cell * 1.5));
    await tester.pumpAndSettle();
    expect(find.byKey(BlindKeys.status), findsOneWidget);
  });

  testWidgets('o "é isso?" fica no painel de baixo: o tabuleiro não muda '
      'de tamanho', (tester) async {
    await pump(tester);
    final before = tester.getRect(find.byKey(BlindKeys.emptyBoard));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(BlindKeys.mic)),
    );
    await tester.pump(const Duration(milliseconds: 600));
    input.hear(['rook a7']);
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byKey(BlindKeys.proposal), findsOneWidget);
    expect(tester.getRect(find.byKey(BlindKeys.emptyBoard)), before);
    await tester.tap(find.byKey(BlindKeys.reject));
    await tester.pumpAndSettle();
    expect(find.byKey(BlindKeys.proposal), findsNothing);
    expect(find.text('Your move'), findsOneWidget);
  });

  testWidgets('desistir, no alto, pede confirmação e encerra', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(BlindKeys.resign));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(BlindKeys.resignConfirm));
    await tester.pumpAndSettle();
    expect(cubit.state.phase, BlindPhase.finished);
  });

  testWidgets('com o teclado aberto e pouca altura, nada estoura', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(BlindKeys.typeField));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 560);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(BlindKeys.typeField), findsOneWidget);
  });

  testWidgets('as ações em voz ficam à vista também gravando e confirmando', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byKey(BlindKeys.narrateGame), findsOneWidget);
    await tester.tap(find.byKey(BlindKeys.mic));
    await tester.pump();
    expect(find.byKey(BlindKeys.recording), findsOneWidget);
    expect(find.byKey(BlindKeys.narrateGame), findsOneWidget);
    input.hear(['rook a7']);
    await tester.pump();
    await tester.tap(find.byKey(BlindKeys.mic));
    await tester.pumpAndSettle();
    expect(find.byKey(BlindKeys.proposal), findsOneWidget);
    expect(find.byKey(BlindKeys.narrateGame), findsOneWidget);
    // O áudio gravado fica em cima, com o microfone para gravar de novo.
    expect(find.byKey(BlindKeys.reRecord), findsOneWidget);
  });

  testWidgets('o ⓘ explica como dizer e digitar os lances, no idioma', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(BlindKeys.help));
    await tester.pumpAndSettle();
    expect(find.byKey(BlindKeys.helpSheet), findsOneWidget);
    expect(find.textContaining('K king, Q queen'), findsOneWidget);
  });
}
