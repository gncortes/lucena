import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/blind/widgets/blind_entry_screen.dart';
import 'package:lucena/ui/core/keys/blind_keys.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeVoiceRepository voice;
  late SpeechCubit fakeSpeech;
  late GoRouter router;
  var catalogVisits = 0;

  Future<void> mount(
    WidgetTester tester, {
    required List<TtsVoice> voices,
    bool loaded = true,
    bool resume = false,
  }) async {
    catalogVisits = 0;
    voice = FakeVoiceRepository(voices: voices);
    fakeSpeech = SpeechCubit(voice);
    addTearDown(fakeSpeech.close);
    if (loaded) await fakeSpeech.load();
    router = GoRouter(
      initialLocation: Routes.blindEntry,
      routes: [
        GoRoute(
          path: Routes.blindEntry,
          builder: (_, _) => BlindEntryScreen(resume: resume),
        ),
        GoRoute(
          path: '/catalog',
          builder: (_, _) {
            catalogVisits++;
            return const Scaffold();
          },
        ),
        GoRoute(path: Routes.allModes, builder: (_, _) => const Scaffold()),
        GoRoute(
          path: Routes.blind,
          builder: (_, _) => const Scaffold(body: Text('partida salva')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt', 'BR'),
        speechCubit: fakeSpeech,
        router: router,
        child: const SizedBox.shrink(),
      ),
    );
    await tester.pump();
  }

  testWidgets('sem voz bloqueia a entrada e permite abrir vozes do aparelho', (
    tester,
  ) async {
    await mount(tester, voices: []);
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byKey(BlindKeys.entry)),
    );

    expect(find.byKey(BlindKeys.voiceRequired), findsOneWidget);
    expect(find.textContaining(l10n.blindVoiceRequired), findsOneWidget);
    expect(find.textContaining(l10n.voiceUnavailable), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, Routes.blindEntry);
    expect(catalogVisits, 0);
    expect(voice.systemOpened, 0);

    await tester.tap(find.byKey(BlindKeys.openVoices));
    await tester.pumpAndSettle();

    expect(voice.systemOpened, 1);
    expect(router.routeInformationProvider.value.uri.path, Routes.blindEntry);
    expect(catalogVisits, 0);
  });

  testWidgets('voz de outro idioma não libera o modo em português', (
    tester,
  ) async {
    await mount(
      tester,
      voices: const [TtsVoice(id: 'en', locale: 'en-US')],
    );
    await tester.pumpAndSettle();

    expect(find.byKey(BlindKeys.voiceRequired), findsOneWidget);
    expect(find.byKey(BlindKeys.openVoices), findsOneWidget);
    expect(catalogVisits, 0);
  });

  testWidgets('com voz carregada encaminha ao catálogo com blind=1', (
    tester,
  ) async {
    await mount(
      tester,
      voices: const [TtsVoice(id: 'pt', locale: 'pt-BR')],
    );
    expect(fakeSpeech.state.loaded, isTrue);
    await tester.pumpAndSettle();

    final uri = router.routeInformationProvider.value.uri;
    expect(uri.path, '/catalog');
    expect(uri.queryParameters, {'blind': '1'});
    expect(find.byKey(BlindKeys.entry), findsNothing);
    expect(find.byKey(BlindKeys.voiceRequired), findsNothing);
    expect(voice.systemOpened, 0);
    expect(router.canPop(), isFalse);
  });

  testWidgets('aguarda carregar as vozes antes de decidir o destino', (
    tester,
  ) async {
    await mount(
      tester,
      voices: const [TtsVoice(id: 'pt', locale: 'pt-BR')],
      loaded: false,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(BlindKeys.voiceRequired), findsNothing);
    expect(catalogVisits, 0);

    await fakeSpeech.load();
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.toString(),
      Routes.blindCatalog,
    );
  });

  testWidgets('voltar dos ajustes relê as vozes e mantém intenção às cegas', (
    tester,
  ) async {
    final voices = <TtsVoice>[];
    await mount(tester, voices: voices);
    await tester.pumpAndSettle();
    expect(find.byKey(BlindKeys.voiceRequired), findsOneWidget);
    voices.add(const TtsVoice(id: 'pt', locale: 'pt-BR'));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.toString(),
      Routes.blindCatalog,
    );
  });

  testWidgets('checkpoint sem voz aguarda ajustes e retoma a partida salva', (
    tester,
  ) async {
    final voices = <TtsVoice>[];
    await mount(tester, voices: voices, resume: true);
    await tester.pumpAndSettle();
    expect(find.byKey(BlindKeys.voiceRequired), findsOneWidget);
    expect(find.text('partida salva'), findsNothing);
    voices.add(const TtsVoice(id: 'pt', locale: 'pt-BR'));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('partida salva'), findsOneWidget);
    expect(catalogVisits, 0);
  });
}
