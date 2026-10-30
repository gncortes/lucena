import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Os tokens de movimento do app, sobre os do Material 3 ([Durations] e
/// [Easing]). Toda animação de `lib/ui/` usa estes nomes; o teste
/// `test/ui/core/motion_usage_test.dart` acusa durações e curvas escritas à
/// mão.
///
/// Para respeitar "remover animações" do sistema, a tela pede as durações por
/// [AppMotion.of], que as devolve zeradas.
abstract final class AppMotion {
  static const persistenceRetry = Duration(milliseconds: 500);

  /// Resposta ao toque: botão, chip, seleção de casa.
  static const tap = Durations.short2;

  /// Troca de estado num componente: cor, ícone, relógio ativo.
  static const state = Durations.short4;

  /// Cartão que expande, painel que abre, balão que troca de fala.
  static const component = Durations.medium2;

  /// Folha que sobe por cima do tabuleiro na apresentação do passo.
  static const panel = Durations.medium1;

  /// Entrada de tela, versus, conclusão.
  static const screen = Durations.long2;

  /// Diploma, conquista, recorde.
  static const celebrate = Durations.extralong2;

  /// Atraso entre itens em cascata.
  static const stagger = Durations.short1;

  /// Revelar um lance oculto da faixa de variantes (T69, "desliza para fora").
  static const reveal = Duration(milliseconds: 240);

  /// Os três pontinhos de "digitando" (T70): ciclo e defasagem entre pontos.
  static const typingCycle = Duration(milliseconds: 1200);
  static const typingStagger = Durations.short3;

  /// Coreografias longas (D34): uma duração com nome para cada uma.
  /// Entrada da tela inicial.
  static const entrance = Duration(milliseconds: 1400);

  /// Volta contínua do brilho do esqueleto de carregamento.
  static const shimmer = Duration(milliseconds: 1400);

  /// Confete da celebração.
  /// Quanto o aviso (snackbar) fica na tela.
  static const snackBar = Duration(seconds: 4);

  static const confetti = Duration(milliseconds: 1600);

  /// Selo de fim da partida: entra, fica no pico ([narrationPeak]) e sai.
  static const narration = Duration(milliseconds: 1600);
  static const narrationPeak = Duration(milliseconds: 1200);

  /// Selo de fim do final em destaque: pisca (entra, fica e sai) em 1,5 s.
  static const featuredFlash = Duration(milliseconds: 1500);

  /// Selo de fim com "remover animações": só um fade curto.
  static const reducedFade = Duration(milliseconds: 150);

  /// Abertura do confronto com a contagem e sem ela.
  static const versus = Duration(milliseconds: 4600);
  static const versusShort = Duration(milliseconds: 2000);

  /// Tempo, não animação (ficam aqui para a tela não escrever milissegundos).
  /// Tique que repinta o relógio da partida.
  static const clockRefresh = Duration(milliseconds: 100);

  /// Tique do cronômetro do exercício.
  static const exerciseTick = Duration(milliseconds: 250);

  /// Toque mínimo no microfone das Às cegas para valer como segurar.
  static const micHold = Duration(milliseconds: 350);

  /// Quanto um aviso de conquista sozinho fica na tela.
  static const achievementToast = Duration(milliseconds: 3800);

  /// Ritmo de leitura da fala: uma letra a cada tanto.
  static const typewriterLetter = Duration(milliseconds: 28);

  /// Quanto a fala flutuante da barra do personagem fica à vista: 60 ms por
  /// caractere, no mínimo 6 s.
  static Duration floatingSpeech(int length) =>
      Duration(milliseconds: math.max(6000, length * 60));

  /// A fala do professor aparecendo: uns 15 caracteres por segundo quando
  /// no ritmo da voz ([paced]); mais rápido, sem voz.
  static Duration typedText(int length, {required bool paced}) => paced
      ? Duration(milliseconds: (length * 65).clamp(600, 60000))
      : Duration(milliseconds: (length * 14).clamp(300, 2800));

  /// Curva da revelação.
  static const revealCurve = Curves.easeOutCubic;

  /// Algo aparece ou entra na tela.
  static const enter = Easing.emphasizedDecelerate;

  /// Algo some ou sai.
  static const exit = Easing.emphasizedAccelerate;

  /// Algo se move dentro da tela (peça, marcador, régua). O [Easing] não tem
  /// o "emphasized" puro; esta é a aproximação do próprio Flutter.
  static const move = Curves.easeInOutCubicEmphasized;

  /// Algo muda de tamanho aos poucos (balão que cresce ou encolhe): suave e
  /// simétrica, sem o arranque do [move], para o que está em volta não pular.
  static const resize = Curves.easeInOut;

  /// Progresso contínuo (anel de tempo, barra que anda sozinha).
  static const linear = Easing.linear;

  /// Rebote: em celebração, com [celebrate], e no pop do relógio na entrada
  /// da partida (`GameEntrance`).
  static const pop = Curves.easeOutBack;

  /// Rebote elástico: só em celebração, com [celebrate].
  static const bounce = Curves.elasticOut;

  /// As durações para esta tela: zeradas com "remover animações" ligado.
  static MotionDurations of(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? MotionDurations.none
      : MotionDurations.standard;

  /// "Remover animações" está ligado: o que se move fica parado.
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}

/// As durações de [AppMotion] já ajustadas para "remover animações".
class MotionDurations {
  const MotionDurations._({
    required this.tap,
    required this.state,
    required this.component,
    required this.panel,
    required this.screen,
    required this.celebrate,
    required this.stagger,
  });

  static const standard = MotionDurations._(
    tap: AppMotion.tap,
    state: AppMotion.state,
    component: AppMotion.component,
    panel: AppMotion.panel,
    screen: AppMotion.screen,
    celebrate: AppMotion.celebrate,
    stagger: AppMotion.stagger,
  );

  static const none = MotionDurations._(
    tap: Duration.zero,
    state: Duration.zero,
    component: Duration.zero,
    panel: Duration.zero,
    screen: Duration.zero,
    celebrate: Duration.zero,
    stagger: Duration.zero,
  );

  final Duration tap;
  final Duration state;
  final Duration component;
  final Duration panel;
  final Duration screen;
  final Duration celebrate;
  final Duration stagger;

  /// Sem movimento: a tela aparece pronta.
  bool get disabled => identical(this, none);
}
