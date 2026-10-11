import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/achievement.dart';
import '../../../domain/models/character.dart';
import '../../../routing/routes.dart';
import '../../core/keys/achievements_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import 'achievement_medal.dart';
import 'achievement_ui.dart';

/// Abre o detalhe de [achievement] num painel inferior. Obtida ([unlocked]),
/// mostra a data e a hora e, quando a origem foi gravada, o botão para a
/// partida ou para a tentativa de speedrun ([speedrunId] é o speedrun da
/// tentativa). Faltando, o que falta, o [progress] quando dá para medir e o
/// atalho para onde se conquista. O botão fecha o painel e abre a rota.
Future<void> showAchievementDetail(
  BuildContext context, {
  required Achievement achievement,
  UnlockedAchievement? unlocked,
  List<Character> characters = const [],
  AchievementProgress? progress,
  String? speedrunId,
}) async {
  final route = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => SafeArea(
      top: false,
      child: AchievementDetail(
        achievement: achievement,
        unlocked: unlocked,
        characters: characters,
        progress: progress,
        speedrunId: speedrunId,
        onOpen: (route) => Navigator.of(context).pop(route),
      ),
    ),
  );
  if (route != null && context.mounted) await context.push(route);
}

/// O conteúdo do painel de detalhe (ver [showAchievementDetail]).
class AchievementDetail extends StatefulWidget {
  const AchievementDetail({
    required this.achievement,
    required this.onOpen,
    this.unlocked,
    this.characters = const [],
    this.progress,
    this.speedrunId,
    super.key,
  });

  final Achievement achievement;
  final UnlockedAchievement? unlocked;
  final List<Character> characters;
  final AchievementProgress? progress;
  final String? speedrunId;

  /// Um botão foi tocado: a rota a abrir.
  final ValueChanged<String> onOpen;

  /// O botão da origem: a tentativa de speedrun (nas conquistas de speedrun)
  /// ou a partida. Nulo sem origem gravada.
  static (String route, bool speedrun)? sourceOf(
    Achievement achievement,
    UnlockedAchievement? unlocked,
    String? speedrunId,
  ) {
    if (unlocked == null) return null;
    final attemptId = unlocked.speedrunAttemptId;
    if (achievement.fromSpeedrun && attemptId != null && speedrunId != null) {
      return (Routes.speedrunAttempt(speedrunId, attemptId), true);
    }
    final gameId = unlocked.gameId;
    if (gameId != null) return (Routes.game(gameId), false);
    return null;
  }

  @override
  State<AchievementDetail> createState() => _AchievementDetailState();
}

class _AchievementDetailState extends State<AchievementDetail>
    with SingleTickerProviderStateMixin {
  late final _entrance = AnimationController(vsync: this);
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // A medalha gira um quarto e assenta, e o brilho passa (T51, G6).
    _entrance
      ..duration = AppMotion.of(context).celebrate
      ..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final achievement = widget.achievement;
    final unlocked = widget.unlocked;
    final progress = widget.progress;
    final source = AchievementDetail.sourceOf(
      achievement,
      unlocked,
      widget.speedrunId,
    );
    final shortcut = unlocked == null
        ? achievement.shortcut(l10n, widget.characters)
        : null;
    final settle = CurvedAnimation(
      parent: _entrance,
      curve: Interval(
        0,
        0.6,
        curve: unlocked == null ? AppMotion.enter : AppMotion.pop,
      ),
    );
    final shine = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.55, 1, curve: AppMotion.move),
    );
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: colors.onSurfaceVariant,
    );
    return SingleChildScrollView(
      key: AchievementsKeys.detail,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: FadeTransition(
              opacity: settle.drive(Tween(begin: 0.0, end: 1.0)),
              child: ScaleTransition(
                scale: settle.drive(Tween(begin: 0.4, end: 1.0)),
                child: RotationTransition(
                  // Um quarto de volta até assentar; a que falta só cresce.
                  turns: unlocked == null
                      ? const AlwaysStoppedAnimation(0)
                      : settle.drive(Tween(begin: -0.25, end: 0.0)),
                  child: AchievementMedal(
                    key: AchievementsKeys.detailMedal,
                    icon: achievement.iconData,
                    unlocked: unlocked != null,
                    size: 96,
                    shine: shine,
                    lockLabel: l10n.achievementsLockedLabel,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            achievement.title(l10n, widget.characters),
            key: AchievementsKeys.detailTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (unlocked == null) ...[
            Text(
              l10n.achievementDetailMissing,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(
            achievement.description(l10n, widget.characters),
            key: AchievementsKeys.detailDescription,
            textAlign: TextAlign.center,
            style: muted,
          ),
          if (unlocked != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 18, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    l10n.achievementsUnlockedOn(
                      fullDateTime(l10n, locale, unlocked.at),
                    ),
                    key: AchievementsKeys.detailDate,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
          if (unlocked == null && progress != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              progress.label(l10n),
              key: AchievementsKeys.detailProgress,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(value: progress.fraction),
          ],
          if (source case (final route, final speedrun)) ...[
            const SizedBox(height: AppSpacing.xl),
            FilledButton.tonalIcon(
              key: speedrun
                  ? AchievementsKeys.detailOpenSpeedrun
                  : AchievementsKeys.detailOpenGame,
              onPressed: () => widget.onOpen(route),
              icon: Icon(speedrun ? Icons.timer_outlined : Icons.visibility),
              label: Text(
                speedrun
                    ? l10n.achievementOpenSpeedrun
                    : l10n.achievementOpenGame,
              ),
            ),
          ],
          if (shortcut != null) ...[
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              key: AchievementsKeys.detailShortcut,
              onPressed: () => widget.onOpen(shortcut.route),
              icon: const Icon(Icons.arrow_forward),
              label: Text(shortcut.label),
            ),
          ],
        ],
      ),
    );
  }
}
