import 'package:flutter/material.dart';

import '../../../domain/models/achievement.dart';
import '../../../domain/models/character.dart';
import '../../core/keys/achievements_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/lucena_motion.dart';
import '../../core/motion/movimento_reduzido.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import 'achievement_medal.dart';
import 'achievement_ui.dart';

/// A mola leve da entrada do aviso: passa uns 5 px do lugar e assenta.
class _MolaLeve extends Curve {
  const _MolaLeve();

  static const _s = 1.5;

  @override
  double transformInternal(double t) {
    final u = t - 1;
    return u * u * ((_s + 1) * u + _s) + 1;
  }
}

/// O aviso de conquista desbloqueada (T85, S3b). Vive na faixa da AppBar, entre
/// o X e as ações (ponha-o como `title` dela): cai de cima 64 px com mola leve
/// em 480 ms, fica e sai para cima. Com várias conquistas, o anterior sai e o
/// próximo entra 120 ms depois, sem corte seco. Texto longo termina em
/// reticências. Com [onTap], tocar no aviso abre o detalhe da conquista
/// (T51, A6); fora dele, o que está embaixo continua usável.
class AchievementToasts extends StatefulWidget {
  const AchievementToasts({
    required this.achievements,
    this.characters = const [],
    this.onTap,
    super.key,
  });

  /// O aviso de [Achievement] foi tocado. Nulo: o aviso não recebe toques.
  final ValueChanged<Achievement>? onTap;

  final List<Achievement> achievements;

  /// Os personagens, para o nome da conquista dizer o adversário.
  final List<Character> characters;

  /// Quanto tempo um aviso sozinho fica na tela, da entrada à saída.
  static const duration = AppMotion.achievementToast;

  /// A altura do aviso e a largura máxima (canvas Sug3b).
  static const height = 48.0;
  static const maxWidth = 236.0;

  /// Quanto tempo cada aviso fica quando são [count] de uma vez: a fila
  /// inteira não passa de uns 8 segundos.
  static Duration durationFor(int count) => Duration(
    milliseconds: (8000 ~/ (count < 1 ? 1 : count)).clamp(
      1600,
      duration.inMilliseconds,
    ),
  );

  @override
  State<AchievementToasts> createState() => _AchievementToastsState();
}

class _AchievementToastsState extends State<AchievementToasts>
    with SingleTickerProviderStateMixin {
  late final Duration _each = AchievementToasts.durationFor(
    widget.achievements.length,
  );

  // O começo de cada aviso: o próximo entra 120 ms depois de o anterior
  // começar a sair.
  late final Duration _step =
      _each - LucenaMotion.avisoSai + LucenaMotion.intervaloDoAviso;

  late final _clock = AnimationController(
    vsync: this,
    duration: _step * (widget.achievements.length - 1) + _each,
  );

  @override
  void initState() {
    super.initState();
    if (widget.achievements.isNotEmpty) _clock.forward();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sem animações (pedido do aparelho), o aviso só aparece e some.
    final still = MovimentoReduzido.of(context);
    return AnimatedBuilder(
      animation: _clock,
      builder: (context, _) {
        final now = _clock.value * _clock.duration!.inMicroseconds / 1000;
        final shown = <Widget>[];
        for (final (index, achievement) in widget.achievements.indexed) {
          final start = _step.inMicroseconds * index / 1000;
          final leaves =
              start + (_each - LucenaMotion.avisoSai).inMicroseconds / 1000;
          final end = start + _each.inMicroseconds / 1000;
          if (now < start || now >= end) continue;
          final enter = ((now - start) / LucenaMotion.avisoEntra.inMilliseconds)
              .clamp(0.0, 1.0);
          final leave = ((now - leaves) / LucenaMotion.avisoSai.inMilliseconds)
              .clamp(0.0, 1.0);
          final double dy;
          final double opacity;
          if (still) {
            dy = 0;
            opacity = 1;
          } else {
            final drop = LucenaMotion.quedaDoAviso;
            dy =
                -drop * (1 - const _MolaLeve().transform(enter)) -
                drop * AppMotion.exit.transform(leave);
            opacity = const Interval(0, .3).transform(enter) * (1 - leave);
          }
          shown.add(
            IgnorePointer(
              key: ValueKey(achievement.id),
              ignoring: widget.onTap == null || enter < .5 || leave > 0,
              child: Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(0, dy),
                  child: _Toast(
                    achievement: achievement,
                    characters: widget.characters,
                    onTap: widget.onTap,
                  ),
                ),
              ),
            ),
          );
        }
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: shown,
        );
      },
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast({
    required this.achievement,
    required this.characters,
    required this.onTap,
  });

  final Achievement achievement;
  final List<Character> characters;
  final ValueChanged<Achievement>? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final title = achievement.title(l10n, characters);
    return Semantics(
      liveRegion: true,
      label: '${l10n.achievementUnlocked}: $title',
      button: onTap != null,
      onTap: onTap == null ? null : () => onTap!(achievement),
      excludeSemantics: true,
      child: Material(
        key: AchievementsKeys.toast,
        color: colors.inverseSurface,
        elevation: 4,
        borderRadius: BorderRadius.circular(AchievementToasts.height / 2),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap == null ? null : () => onTap!(achievement),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AchievementToasts.maxWidth,
              minHeight: AchievementToasts.height,
              maxHeight: AchievementToasts.height,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.sm,
                0,
                AppSpacing.md,
                0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AchievementMedal(
                    icon: achievement.iconData,
                    unlocked: true,
                    size: 32,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.achievementUnlocked,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onInverseSurface.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                        Text(
                          title,
                          key: AchievementsKeys.toastTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.cardTitle?.copyWith(
                            color: colors.onInverseSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
