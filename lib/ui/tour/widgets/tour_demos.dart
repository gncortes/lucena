import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../domain/models/character.dart';
import '../../core/keys/tour_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/l10n/run_time.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/position_board.dart';
import '../view_models/tour_cubit.dart';

/// Uma demonstração curta do que o passo do tour apresenta: toca uma vez ao
/// abrir e de novo a cada toque. Com "remover animações", aparece pronta.
class TourDemo extends StatefulWidget {
  const TourDemo({required this.step, required this.characters, super.key});

  final TourStep step;

  /// Os personagens, para os retratos da Jornada e dos adversários.
  final List<Character> characters;

  /// Os passos com demonstração.
  static bool covers(TourStep step) => switch (step) {
    TourStep.journey ||
    TourStep.speedrun ||
    TourStep.opponents ||
    TourStep.rating ||
    TourStep.records ||
    TourStep.endgames => true,
    _ => false,
  };

  @override
  State<TourDemo> createState() => _TourDemoState();
}

class _TourDemoState extends State<TourDemo>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: switch (widget.step) {
      TourStep.speedrun => const Duration(milliseconds: 7500),
      _ => const Duration(milliseconds: 3200),
    },
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (_controller.isDismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _replay() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: TourKeys.demo,
      behavior: HitTestBehavior.opaque,
      onTap: _replay,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_controller.value);
          return switch (widget.step) {
            TourStep.speedrun => _SpeedrunDemo(value: _controller.value),
            TourStep.journey => _JourneyDemo(
              value: t,
              characters: widget.characters,
            ),
            TourStep.opponents => _OpponentsDemo(
              value: _controller.value,
              characters: widget.characters,
            ),
            TourStep.rating => _RatingDemo(value: t),
            TourStep.records => _RecordsDemo(value: _controller.value),
            _ => const _EndgameDemo(),
          };
        },
      ),
    );
  }
}

/// O speedrun em ação: três mates em um, um depois do outro, com o relógio
/// do jogador somando.
class _SpeedrunDemo extends StatelessWidget {
  const _SpeedrunDemo({required this.value});

  final double value;

  // Antes do mate, o lance do mate e quanto o relógio correu na etapa.
  static final _stages = [
    (
      '6k1/8/6K1/8/8/8/8/Q7 w - - 0 1',
      NormalMove.fromUci('a1a8'),
      const Duration(milliseconds: 4200),
    ),
    (
      '6k1/8/6K1/8/8/8/8/R7 w - - 0 1',
      NormalMove.fromUci('a1a8'),
      const Duration(milliseconds: 3100),
    ),
    (
      'k7/8/1K6/8/8/8/7Q/8 w - - 0 1',
      NormalMove.fromUci('h2h8'),
      const Duration(milliseconds: 5600),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final count = _stages.length;
    final stage = (value * count).floor().clamp(0, count - 1);
    // Dentro da etapa: o tabuleiro antes do lance, depois o mate.
    final within = value >= 1 ? 1.0 : value * count - stage;
    final mated = within >= 0.45;
    final (fen, move, time) = _stages[stage];
    final after = Position.setupPosition(
      Rule.chess,
      Setup.parseFen(fen),
    ).play(move).fen;
    var clock = Duration.zero;
    for (var i = 0; i < stage; i++) {
      clock += _stages[i].$3;
    }
    clock += time * (mated ? 1 : within / 0.45);
    return Card(
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: PositionBoard(
                  key: ValueKey('$stage$mated'),
                  fen: mated ? after : fen,
                  // As brancas embaixo, mesmo com a vez das pretas no fim.
                  orientation: Side.white,
                  size: 128,
                  radius: 0,
                  lastMove: mated ? move : null,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.speedrunStageOf(stage + 1, count),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // As etapas: as vencidas cheias.
                  Row(
                    children: [
                      for (var i = 0; i < count; i++)
                        Expanded(
                          child: Container(
                            height: 6,
                            margin: const EdgeInsetsDirectional.only(end: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: i < stage || (i == stage && mated)
                                  ? colors.primary
                                  : colors.outlineVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, color: colors.primary),
                      const SizedBox(width: 6),
                      Text(
                        runTime(context, clock),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedOpacity(
                    opacity: mated ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Chip(
                      avatar: Icon(Icons.check_circle, color: colors.primary),
                      label: Text(l10n.tourDemoMate),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A Jornada: os adversários em escada, o progresso andando de um para o
/// outro até o Stockfish.
class _JourneyDemo extends StatelessWidget {
  const _JourneyDemo({required this.value, required this.characters});

  final double value;
  final List<Character> characters;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final people = [
      for (final level in const [1000, 1200, 1400]) ?characters.forLevel(level),
      Character.stockfish,
    ];
    final reached = value * (people.length - 1);
    return SizedBox(
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // A linha da escada, enchendo da esquerda para a direita.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Stack(
              children: [
                Container(height: 6, color: colors.outlineVariant),
                FractionallySizedBox(
                  widthFactor: value,
                  child: Container(height: 6, color: colors.primary),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final (index, person) in people.indexed)
                AnimatedScale(
                  scale: reached >= index ? 1 : 0.85,
                  duration: const Duration(milliseconds: 200),
                  child: Opacity(
                    opacity: reached >= index ? 1 : 0.4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: reached >= index
                            ? colors.primary
                            : colors.outlineVariant,
                      ),
                      child: ClipOval(
                        child: CharacterAvatar(character: person, size: 54),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Os adversários têm personalidade: os retratos mudam de emoção.
class _OpponentsDemo extends StatelessWidget {
  const _OpponentsDemo({required this.value, required this.characters});

  final double value;
  final List<Character> characters;

  static const _emotions = [
    Emotion.calm,
    Emotion.playful,
    Emotion.surprised,
    Emotion.happy,
  ];

  @override
  Widget build(BuildContext context) {
    final people = [
      for (final level in const [1000, 1200, 1400]) ?characters.forLevel(level),
    ];
    final beat = (value * _emotions.length).floor().clamp(
      0,
      _emotions.length - 1,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final (index, person) in people.indexed)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: CharacterAvatar(
              key: ValueKey('${person.id}$beat'),
              character: person,
              emotion: _emotions[(beat + index) % _emotions.length],
              size: 72,
            ),
          ),
      ],
    );
  }
}

/// O rating subindo.
class _RatingDemo extends StatelessWidget {
  const _RatingDemo({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final rating = 1000 + (150 * value).round();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$rating',
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 12),
        Opacity(
          opacity: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: colors.onPrimaryContainer),
                const SizedBox(width: 4),
                Text(
                  '+${rating - 1000}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Os tempos guardados aparecendo, o melhor com o troféu.
class _RecordsDemo extends StatelessWidget {
  const _RecordsDemo({required this.value});

  final double value;

  static const _times = [
    Duration(minutes: 1, seconds: 12, milliseconds: 400),
    Duration(seconds: 58, milliseconds: 900),
    Duration(seconds: 47, milliseconds: 300),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      children: [
        for (final (index, time) in _times.indexed)
          Opacity(
            opacity: ((value * _times.length) - index).clamp(0.0, 1.0),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    index == _times.length - 1
                        ? Icons.emoji_events
                        : Icons.flag_outlined,
                    color: index == _times.length - 1
                        ? colors.primary
                        : colors.outline,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    runTime(context, time),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: index == _times.length - 1
                          ? FontWeight.w800
                          : FontWeight.w500,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Um final de verdade: a posição de Lucena.
class _EndgameDemo extends StatelessWidget {
  const _EndgameDemo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: const PositionBoard(
          fen: '1K6/1P1k4/8/8/8/8/r7/2R5 w - - 0 1',
          orientation: Side.white,
          size: 160,
          radius: 0,
        ),
      ),
    );
  }
}
