import '../widgets/speech_balloon.dart';

export '../widgets/animated_speech_switcher.dart'
    show AnimatedSpeechSwitcher, SpeechPop;
export '../widgets/speech_balloon.dart' show BalloonTail, SpeechBalloon;

/// O balão do Viktor (H-ANI-09) é o [SpeechBalloon] de sempre, um componente
/// só: a entrada pelo bico é o `SpeechPop` e a troca da fala, o
/// `AnimatedSpeechSwitcher` (com `speech` como identidade da fala), já nos
/// tempos do kit.
typedef BalaoViktor = SpeechBalloon;
