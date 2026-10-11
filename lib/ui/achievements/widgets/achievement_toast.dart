import 'package:flutter/material.dart';

import '../../../domain/models/achievement.dart';
import '../../../domain/models/character.dart';
import '../../core/keys/achievements_keys.dart';
import '../../core/l10n/l10n.dart';
import 'achievement_medal.dart';
import 'achievement_ui.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';

/// O aviso de conquista desbloqueada, como o troféu do PlayStation: desce do
/// alto da tela, o troféu salta, um brilho passa por ele e o aviso some
/// sozinho. Com várias conquistas, uma depois da outra. Com [onTap], tocar no
/// aviso abre o detalhe da conquista (T51, A6); fora dele, o que está embaixo
/// continua usável.
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
  static const duration = Duration(milliseconds: 3800);

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
  late final _show = AnimationController(
    vsync: this,
    duration: AchievementToasts.durationFor(widget.achievements.length),
  );

  // A conquista na tela. Depois da última, nada.
  var _current = 0;

  @override
  void initState() {
    super.initState();
    _show
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        setState(() => _current++);
        if (_current < widget.achievements.length) _show.forward(from: 0);
      })
      ..forward();
  }

  @override
  void dispose() {
    _show.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_current >= widget.achievements.length) return const SizedBox.shrink();
    final achievement = widget.achievements[_current];
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final title = achievement.title(l10n, widget.characters);
    // Sem animações (pedido do aparelho), o aviso só aparece e some.
    final still = AppMotion.of(context).disabled;
    final enter = CurvedAnimation(
      parent: _show,
      curve: const Interval(0, 0.12, curve: AppMotion.enter),
    );
    final leave = CurvedAnimation(
      parent: _show,
      curve: const Interval(0.9, 1, curve: AppMotion.exit),
    );
    final pop = CurvedAnimation(
      parent: _show,
      curve: const Interval(0.08, 0.26, curve: AppMotion.pop),
    );
    final shine = CurvedAnimation(
      parent: _show,
      curve: const Interval(0.24, 0.5, curve: AppMotion.move),
    );
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: AnimatedBuilder(
            animation: _show,
            builder: (context, child) {
              final visible = enter.value - leave.value;
              // Só o aviso à vista recebe toques; fora dele, nada.
              return IgnorePointer(
                ignoring: widget.onTap == null || visible < 0.5,
                child: Opacity(
                  opacity: visible.clamp(0, 1),
                  child: FractionalTranslation(
                    translation: Offset(0, still ? 0 : visible - 1),
                    child: child,
                  ),
                ),
              );
            },
            child: Semantics(
              liveRegion: true,
              label: '${l10n.achievementUnlocked}: $title',
              button: widget.onTap != null,
              onTap: widget.onTap == null
                  ? null
                  : () => widget.onTap!(achievement),
              excludeSemantics: true,
              child: Material(
                key: AchievementsKeys.toast,
                color: colors.inverseSurface,
                elevation: 8,
                borderRadius: BorderRadius.circular(AppShape.full),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: widget.onTap == null
                      ? null
                      : () => widget.onTap!(achievement),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        10,
                        10,
                        24,
                        10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ScaleTransition(
                            scale: still
                                ? const AlwaysStoppedAnimation(1)
                                : Tween<double>(
                                    begin: 0.3,
                                    end: 1,
                                  ).animate(pop),
                            child: AchievementMedal(
                              icon: achievement.iconData,
                              unlocked: true,
                              size: 48,
                              shine: still
                                  ? const AlwaysStoppedAnimation(0)
                                  : shine,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.achievementUnlocked,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: colors.onInverseSurface.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                                Text(
                                  title,
                                  key: AchievementsKeys.toastTitle,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colors.onInverseSurface,
                                    fontWeight: FontWeight.w800,
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
            ),
          ),
        ),
      ),
    );
  }
}
