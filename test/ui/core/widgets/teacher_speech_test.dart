import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/character_avatar.dart';
import 'package:lucena/ui/core/widgets/teacher_speech.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/fakes/fake_voice_repository.dart';
import '../../../../testing/test_app.dart';

import 'package:lucena/data/repositories/voice/voice_repository.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/core/keys/voice_keys.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

void main() {
  const speech = Key('speech');
  const speech_ = speech;
  const long =
      'Queen against rook is a win, but the queen cannot do it alone: a rook '
      'glued to its king defends everything.';

  Future<void> pump(
    WidgetTester tester, {
    SpeechContext speechContext = SpeechContext.game,
    bool typed = false,
    bool noAnimations = false,
  }) => tester.pumpWidget(
    TestApp(
      child: MediaQuery(
        data: MediaQueryData(disableAnimations: noAnimations),
        child: Scaffold(
          body: TeacherSpeech(
            teacher: FakeCharacterRepository.viktor,
            text: long,
            bubbleKey: speech,
            speechContext: speechContext,
            typed: typed,
          ),
        ),
      ),
    ),
  );

  String shown(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(speech)).data!;

  testWidgets('ao lado: o balão começa à direita do retrato', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();
    final avatar = tester.getRect(find.byType(CharacterAvatar));
    final text = tester.getRect(find.byKey(speech));
    expect(text.left, greaterThan(avatar.right));
  });

  testWidgets('embaixo: o balão fica abaixo do retrato e usa a largura toda', (
    tester,
  ) async {
    await pump(tester, speechContext: SpeechContext.teaching);
    await tester.pumpAndSettle();
    final avatar = tester.getRect(find.byType(CharacterAvatar));
    final text = tester.getRect(find.byKey(speech));
    expect(text.top, greaterThan(avatar.bottom));
    expect(text.left, lessThan(avatar.right));
  });

  testWidgets('a fala aparece aos poucos e o texto está inteiro desde o '
      'começo', (tester) async {
    await pump(tester, speechContext: SpeechContext.teaching, typed: true);
    await tester.pump(const Duration(milliseconds: 100));
    // O texto inteiro já está lá (quem lê a tela ouve tudo); só a vista é
    // recortada enquanto a fala anda.
    expect(shown(tester), long);
    expect(find.byType(ClipPath), findsOneWidget);

    await tester.pumpAndSettle();
    expect(shown(tester), long);
    expect(find.byType(ClipPath), findsNothing);
  });

  testWidgets('um toque no balão mostra a fala inteira', (tester) async {
    await pump(tester, speechContext: SpeechContext.teaching, typed: true);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ClipPath), findsOneWidget);

    // O texto ainda está recortado: quem recebe o toque é a área da fala.
    await tester.tap(find.byKey(speech), warnIfMissed: false);
    await tester.pump();
    expect(find.byType(ClipPath), findsNothing);
  });

  testWidgets('com as animações desligadas a fala aparece de uma vez', (
    tester,
  ) async {
    await pump(
      tester,
      speechContext: SpeechContext.teaching,
      typed: true,
      noAnimations: true,
    );
    await tester.pump();
    expect(shown(tester), long);
    expect(find.byType(ClipPath), findsNothing);
  });

  testWidgets('a fala longa cresce o balão, sem rolagem dentro dele', (
    tester,
  ) async {
    await pump(tester);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(TeacherSpeech),
        matching: find.byType(Scrollable),
      ),
      findsNothing,
    );
  });

  testWidgets('fala nova com o começo fora da tela: a tela rola até ele', (
    tester,
  ) async {
    final text = ValueNotifier(long);
    final controller = ScrollController();
    addTearDown(text.dispose);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: SingleChildScrollView(
            controller: controller,
            child: Column(
              children: [
                const SizedBox(height: 300),
                ValueListenableBuilder(
                  valueListenable: text,
                  builder: (context, value, _) => TeacherSpeech(
                    speechContext: SpeechContext.game,
                    teacher: FakeCharacterRepository.viktor,
                    text: value,
                    bubbleKey: speech,
                  ),
                ),
                const SizedBox(height: 3000),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.jumpTo(1500);
    await tester.pump();

    text.value = 'Now the next step.';
    await tester.pumpAndSettle();
    final top = tester.getRect(find.byType(TeacherSpeech)).top;
    expect(top, greaterThanOrEqualTo(0));
    expect(controller.offset, lessThan(400));
  });

  testWidgets('fala nova à vista: a tela não se mexe', (tester) async {
    final text = ValueNotifier(long);
    final controller = ScrollController();
    addTearDown(text.dispose);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: SingleChildScrollView(
            controller: controller,
            child: Column(
              children: [
                const SizedBox(height: 300),
                ValueListenableBuilder(
                  valueListenable: text,
                  builder: (context, value, _) => TeacherSpeech(
                    speechContext: SpeechContext.game,
                    teacher: FakeCharacterRepository.viktor,
                    text: value,
                    bubbleKey: speech,
                  ),
                ),
                const SizedBox(height: 3000),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.jumpTo(100);
    await tester.pump();

    text.value = 'Now the next step.';
    await tester.pumpAndSettle();
    expect(controller.offset, 100);
  });

  group('com a voz', () {
    Future<(SpeechCubit, FakeVoiceRepository)> pumpWithVoice(
      WidgetTester tester, {
      bool enabled = true,
    }) async {
      final voice = FakeVoiceRepository(
        settings: VoiceSettings(enabled: enabled),
      );
      final speech = SpeechCubit(voice);
      addTearDown(speech.close);
      await speech.load();
      await tester.pumpWidget(
        TestApp(
          speechCubit: speech,
          child: Scaffold(
            body: TeacherSpeech(
              teacher: FakeCharacterRepository.viktor,
              text: long,
              bubbleKey: speech_,
              speechContext: SpeechContext.teaching,
              typed: true,
              speaks: true,
            ),
          ),
        ),
      );
      await tester.pump();
      return (speech, voice);
    }

    testWidgets('o texto acompanha a voz e não pisca: entre uma palavra e '
        'outra, segue recortado', (tester) async {
      final (_, voice) = await pumpWithVoice(tester);
      expect(voice.spoken, hasLength(1));
      for (final end in [10, 25, 40]) {
        voice.emit(TtsProgress(end - 5, end));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        // A animação até a palavra acabou, e a fala ainda não está inteira.
        expect(find.byType(ClipPath), findsOneWidget);
      }
      voice.emit(const TtsFinished());
      await tester.pumpAndSettle();
      expect(find.byType(ClipPath), findsNothing);
    });

    testWidgets('o botão de velocidade passa para a próxima e recomeça a '
        'fala nela', (tester) async {
      final (speech, voice) = await pumpWithVoice(tester);
      expect(find.text('1×'), findsOneWidget);
      await tester.tap(find.byKey(VoiceKeys.speedButton));
      await tester.pump();
      expect(voice.settings.speed, 1.2);
      expect(find.text('1.2×'), findsOneWidget);
      // Falando, a fala recomeça já na velocidade nova.
      expect(voice.spoken, hasLength(2));
      expect(voice.spoken.last.$2.rate, closeTo(1.2, 1e-9));
      expect(speech.state.isSpeaking(long), isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('um botão de som só: desligado, liga a voz e fala; ligado, '
        'cala e grava a escolha', (tester) async {
      final (speech, voice) = await pumpWithVoice(tester, enabled: false);
      expect(voice.spoken, isEmpty);
      expect(find.byIcon(Icons.volume_off_outlined), findsOneWidget);
      await tester.tap(find.byKey(VoiceKeys.speakButton));
      await tester.pump();
      expect(voice.settings.enabled, isTrue);
      expect(speech.state.isSpeaking(long), isTrue);
      expect(find.byIcon(Icons.volume_up_outlined), findsOneWidget);
      await tester.tap(find.byKey(VoiceKeys.speakButton));
      await tester.pump();
      expect(voice.settings.enabled, isFalse);
      expect(speech.state.speaking, isNull);
      await tester.pumpAndSettle();
    });
  });

  group('casas e lances tocáveis', () {
    const said = 'O bispo em e4 fecha d5, e depois Tf7.';

    Future<List<String>> pumpLinks(
      WidgetTester tester, {
      bool typed = false,
      SpeechCubit? speech,
    }) async {
      final tapped = <String>[];
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          speechCubit: speech,
          child: Scaffold(
            body: TeacherSpeech(
              teacher: FakeCharacterRepository.viktor,
              text: said,
              bubbleKey: speech_,
              speechContext: SpeechContext.teaching,
              typed: typed,
              speaks: speech != null,
              onLink: (link) => tapped.add(link.text),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tapped;
    }

    // O centro da letra [offset] do balão, na tela.
    Offset letter(WidgetTester tester, int offset) {
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byKey(speech_),
          matching: find.byType(RichText),
        ),
      );
      final caret = paragraph.getOffsetForCaret(
        TextPosition(offset: offset),
        Rect.zero,
      );
      return paragraph.localToGlobal(caret + const Offset(4, 10));
    }

    testWidgets('as casas e os lances viram trechos destacados, e tocar '
        'num deles avisa a tela', (tester) async {
      final tapped = await pumpLinks(tester);
      final text = tester.widget<Text>(find.byKey(speech_));
      expect(text.data, isNull);
      expect(text.textSpan!.toPlainText(), said);

      await tester.tapAt(letter(tester, said.indexOf('e4')));
      await tester.tapAt(letter(tester, said.indexOf('Tf7') + 1));
      // Fora de uma casa, nada.
      await tester.tapAt(letter(tester, 2));
      expect(tapped, ['e4', 'Tf7']);
    });

    testWidgets('o dedo que erra a casa por pouco ainda vale nela', (
      tester,
    ) async {
      final tapped = await pumpLinks(tester);
      // Logo depois do fim de "e4", já no espaço seguinte.
      final end = said.indexOf('e4') + 2;
      await tester.tapAt(letter(tester, end) + const Offset(8, 0));
      expect(tapped, ['e4']);
    });

    testWidgets('aparecendo aos poucos: tocar fora de uma casa mostra tudo; '
        'numa casa já à vista, vale na hora', (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          child: Scaffold(
            body: TeacherSpeech(
              teacher: FakeCharacterRepository.viktor,
              text: said,
              bubbleKey: speech_,
              speechContext: SpeechContext.teaching,
              typed: true,
              onLink: (link) => tapped.add(link.text),
            ),
          ),
        ),
      );
      // Até "e4" à vista, o resto ainda escondido.
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(ClipPath), findsOneWidget);
      await tester.tapAt(letter(tester, said.indexOf('e4')));
      expect(tapped, ['e4']);
      expect(find.byType(ClipPath), findsOneWidget);
      // "Tf7" ainda não apareceu: o toque mostra a fala inteira.
      await tester.tapAt(letter(tester, said.indexOf('Tf7')));
      await tester.pump();
      expect(find.byType(ClipPath), findsNothing);
      expect(tapped, ['e4']);
      await tester.tapAt(letter(tester, said.indexOf('d5')));
      expect(tapped, ['e4', 'd5']);
    });

    testWidgets('com a voz, cada casa aparece quando a voz chega nela', (
      tester,
    ) async {
      final voice = FakeVoiceRepository(
        settings: const VoiceSettings(enabled: true),
      );
      final speech = SpeechCubit(voice);
      addTearDown(speech.close);
      await speech.load();
      final tapped = <String>[];
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          speechCubit: speech,
          child: Scaffold(
            body: TeacherSpeech(
              teacher: FakeCharacterRepository.viktor,
              text: said,
              bubbleKey: speech_,
              speechContext: SpeechContext.teaching,
              typed: true,
              speaks: true,
              onLink: (_) {},
              onSpoken: (link) => tapped.add(link.text),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(voice.spoken, hasLength(1));
      // A voz passou de "e4" (ainda antes de "d5").
      voice.emit(TtsProgress(said.indexOf('e4') + 3, said.indexOf('e4') + 4));
      await tester.pump();
      expect(tapped, ['e4']);
      voice.emit(TtsProgress(said.indexOf('Tf7') + 1, said.indexOf('Tf7') + 2));
      await tester.pump();
      expect(tapped, ['e4', 'Tf7']);
      await tester.pumpAndSettle();
    });
  });
}
