import 'package:flutter/material.dart';

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

  // Entrada em sequência: o mascote primeiro, depois o nome e a frase.
  late final _mascot = _stage(0, 0.6);
  late final _title = _stage(0.35, 0.8);
  late final _tagline = _stage(0.55, 1);

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
        child: Center(
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
              ],
            ),
          ),
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
