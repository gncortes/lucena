import 'package:flutter/material.dart';

import '../../../domain/models/achievement.dart';
import '../../../domain/models/character.dart';
import '../../core/keys/achievements_keys.dart';
import '../../core/l10n/l10n.dart';
import 'achievement_ui.dart';

/// O aviso de conquista desbloqueada, como o troféu do PlayStation: desce do
/// alto da tela, o troféu salta, um brilho passa por ele e o aviso some
/// sozinho. Com várias conquistas, uma depois da outra. Não recebe toques: o
/// que está embaixo continua usável.
class AchievementToasts extends StatefulWidget {
  const AchievementToasts({
    required this.achievements,
    this.characters = const [],
    super.key,
  });

  final List<Achievement> achievements;

  /// Os personagens, para o nome da conquista dizer o adversário.
  final List<Character> characters;

  /// Quanto tempo cada aviso fica na tela, da entrada à saída.
  static const duration = Duration(milliseconds: 3800);

  @override
  State<AchievementToasts> createState() => _AchievementToastsState();
}

class _AchievementToastsState extends State<AchievementToasts>
    with SingleTickerProviderStateMixin {
  late final _show = AnimationController(
    vsync: this,
    duration: AchievementToasts.duration,
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
    final still = MediaQuery.disableAnimationsOf(context);
    final enter = CurvedAnimation(
      parent: _show,
      curve: const Interval(0, 0.12, curve: Curves.easeOutCubic),
    );
    final leave = CurvedAnimation(
      parent: _show,
      curve: const Interval(0.9, 1, curve: Curves.easeInCubic),
    );
    final pop = CurvedAnimation(
      parent: _show,
      curve: const Interval(0.08, 0.26, curve: Curves.easeOutBack),
    );
    final shine = CurvedAnimation(
      parent: _show,
      curve: const Interval(0.24, 0.5, curve: Curves.easeInOut),
    );
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: AnimatedBuilder(
              animation: _show,
              builder: (context, child) {
                final visible = enter.value - leave.value;
                return Opacity(
                  opacity: visible.clamp(0, 1),
                  child: FractionalTranslation(
                    translation: Offset(0, still ? 0 : visible - 1),
                    child: child,
                  ),
                );
              },
              child: Semantics(
                liveRegion: true,
                label: '${l10n.achievementUnlocked}: $title',
                excludeSemantics: true,
                child: Material(
                  key: AchievementsKeys.toast,
                  color: colors.inverseSurface,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(36),
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
                            child: _Trophy(
                              icon: achievement.iconData,
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

/// O troféu dourado com o ícone da conquista; o brilho atravessa o disco.
class _Trophy extends StatelessWidget {
  const _Trophy({required this.icon, required this.shine});

  final IconData icon;
  final Animation<double> shine;

  static const _size = 48.0;
  static const _gold = [
    Color(0xFFFFE08A),
    Color(0xFFF2B705),
    Color(0xFFB97A00),
  ];
  static const _ink = Color(0xFF4A3000);

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: _size,
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _gold,
                ),
              ),
            ),
            Icon(icon, size: 28, color: _ink),
            AnimatedBuilder(
              animation: shine,
              builder: (context, _) {
                final t = shine.value;
                // Parado no começo e no fim, o brilho fica fora do disco.
                if (t == 0 || t == 1) return const SizedBox.shrink();
                return FractionalTranslation(
                  translation: Offset(t * 2.4 - 1.2, 0),
                  child: Transform.rotate(
                    angle: 0.5,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0x00FFFFFF),
                            Color(0xCCFFFFFF),
                            Color(0x00FFFFFF),
                          ],
                          stops: [0.35, 0.5, 0.65],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
