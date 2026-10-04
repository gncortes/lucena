import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/keys/home_keys.dart';
import '../../core/l10n/l10n.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  // Entrada em sequência: o mascote primeiro, depois o nome, a frase e o botão.
  late final _mascot = _stage(0, 0.55);
  late final _title = _stage(0.3, 0.75);
  late final _tagline = _stage(0.45, 0.9);
  late final _actions = _stage(0.6, 1);

  CurvedAnimation _stage(double begin, double end) {
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Quem pediu menos movimento ao sistema vê a tela pronta, sem animação.
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else if (_entrance.isDismissed) {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _mascot.dispose();
    _title.dispose();
    _tagline.dispose();
    _actions.dispose();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      key: HomeKeys.screen,
      body: SafeArea(
        child: Stack(
          children: [
            _content(context, theme, isDark),
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: FadeTransition(
                  opacity: _actions,
                  child: IconButton(
                    key: HomeKeys.settingsButton,
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: context.l10n.settingsTitle,
                    onPressed: () => context.go(Routes.settings),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, ThemeData theme, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Entrance(
              animation: _mascot,
              scaleFrom: 0.9,
              child: FractionallySizedBox(
                widthFactor: 0.6,
                child: Image.asset(
                  isDark
                      ? 'assets/branding/mascot_dark.png'
                      : 'assets/branding/mascot_light.png',
                  key: HomeKeys.mascot,
                  semanticLabel: context.l10n.homeMascotLabel,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _Entrance(
              animation: _title,
              child: Text(
                context.l10n.appTitle,
                key: HomeKeys.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _Entrance(
              animation: _tagline,
              child: Text(
                context.l10n.homeTagline,
                key: HomeKeys.tagline,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(height: 40),
            _Entrance(
              animation: _actions,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    FilledButton.icon(
                      key: HomeKeys.catalogButton,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(220, 52),
                        textStyle: theme.textTheme.titleMedium,
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(context.l10n.homeTrain),
                      onPressed: () => context.go(Routes.catalog),
                    ),
                    FilledButton.tonalIcon(
                      key: HomeKeys.customPositionButton,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(220, 48),
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(context.l10n.customPositionTitle),
                      onPressed: () => context.go(Routes.customPosition),
                    ),
                    OutlinedButton.icon(
                      key: HomeKeys.freeBoardButton,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(220, 48),
                      ),
                      icon: const Icon(Icons.grid_on_outlined),
                      label: Text(context.l10n.freeBoardTitle),
                      onPressed: () => context.go(Routes.freeBoard),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Surge subindo de leve; com [scaleFrom], também cresce até o tamanho final.
class _Entrance extends StatelessWidget {
  const _Entrance({
    required this.animation,
    required this.child,
    this.scaleFrom = 1,
  });

  final Animation<double> animation;
  final Widget child;
  final double scaleFrom;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(animation),
        child: ScaleTransition(
          scale: Tween(begin: scaleFrom, end: 1.0).animate(animation),
          child: child,
        ),
      ),
    );
  }
}
