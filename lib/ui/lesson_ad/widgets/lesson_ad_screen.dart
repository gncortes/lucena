import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/route_names.dart';
import '../../core/keys/ads_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/barra_do_anuncio.dart';
import '../../core/motion/entrada_de_estado.dart';
import '../../core/motion/entradas_vistas.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/canvas_symbols.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/skeleton.dart';
import '../view_models/lesson_ad_cubit.dart';

/// O anúncio da demonstração em tela cheia (canvas `PropV2DemoAnuncio`,
/// `PropV2DemoAnuncioFalhou`; H-LIC-10 a 12). Fecha com `true` quando a pessoa
/// toca "Fechar" depois da contagem (a lição abre) e com `false` no "Voltar"
/// da falha. O [LessonAdCubit] vem de cima.
class LessonAdScreen extends StatefulWidget {
  const LessonAdScreen({required this.lessonTitle, super.key});

  /// O nome da lição que abre depois do anúncio.
  final String lessonTitle;

  @override
  State<LessonAdScreen> createState() => _LessonAdScreenState();
}

class _LessonAdScreenState extends State<LessonAdScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Segundo plano pausa a contagem; ao voltar, ela retoma de onde parou.
    _lifecycle = AppLifecycleListener(
      onInactive: () => context.read<LessonAdCubit>().pause(),
      onResume: () => context.read<LessonAdCubit>().resume(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LessonAdCubit>();
    return BlocBuilder<LessonAdCubit, LessonAdState>(
      builder: (context, state) => switch (state.phase) {
        LessonAdPhase.failed => _AdFailed(
          onRetry: () => cubit.load(retry: true),
          onLearnMore: () => context.pushNamed(
            RouteNames.pilaresPresentation,
            queryParameters: const {'origem': 'anuncio'},
          ),
        ),
        LessonAdPhase.loading => const Scaffold(
          key: AdsKeys.loading,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: SkeletonBlock(
                height: double.infinity,
                radius: AppShape.extraLarge,
              ),
            ),
          ),
        ),
        LessonAdPhase.ready => _AdBody(
          state: state,
          lessonTitle: widget.lessonTitle,
        ),
      },
    );
  }
}

class _AdBody extends StatelessWidget {
  const _AdBody({required this.state, required this.lessonTitle});

  final LessonAdState state;
  final String lessonTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final label = theme.textTheme.labelLarge?.copyWith(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    );
    final progress = ((4 - state.secondsLeft) / 3).clamp(0.0, 1.0);
    return Scaffold(
      key: AdsKeys.screen,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  DecoratedBox(
                    key: AdsKeys.badge,
                    decoration: ShapeDecoration(
                      color: colors.surfaceContainerHighest,
                      shape: const StadiumBorder(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      child: Text(
                        l10n.adsLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontSize: 12,
                          height: 20 / 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // H-ANI-31: "Conhecer o Pilares" entra e afunda no toque.
                  ConhecerQueEntra(
                    child: _TopText(
                      key: AdsKeys.learnMore,
                      onTap: () => context.pushNamed(
                        RouteNames.pilaresPresentation,
                        queryParameters: const {'origem': 'anuncio'},
                      ),
                      child: Text(
                        l10n.licaoAdLearnMore,
                        style: label?.copyWith(color: colors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // H-ANI-31: a contagem cruza 3 → 2 → 1 → "Fechar".
                  _TopText(
                    key: AdsKeys.adCloseButton,
                    child: ContagemParaFechar(
                      restantes: state.canClose ? 0 : state.secondsLeft,
                      aoFechar: () => Navigator.of(context).pop(true),
                      estilo: label?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppShape.card),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: AppSpacing.md,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 64,
                      color: colors.onSurfaceVariant,
                    ),
                    Text(
                      l10n.licaoAdSpace,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.sm,
                children: [
                  Text(
                    l10n.licaoAdAfter(lessonTitle),
                    key: AdsKeys.after,
                    style: theme.textTheme.bodyMedium,
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppShape.tiny),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      color: colors.primary,
                      backgroundColor: colors.outlineVariant,
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

/// Texto tocável da barra do topo (14/20, peso 500), com a altura de toque
/// de 48. Sem [onTap], o toque é do próprio [child] (a contagem).
class _TopText extends StatelessWidget {
  const _TopText({required this.child, this.onTap, super.key});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppShape.small),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kButtonHeightCompact),
      child: Center(
        widthFactor: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: child,
        ),
      ),
    ),
  );
}

/// O anúncio não carregou (canvas `PropV2DemoAnuncioFalhouCompra`, H-VEN-13):
/// sem anúncio, sem lição. "Tentar novamente" mostra o carregando no botão;
/// "Conhecer o Pilares" abre a apresentação, e voltar dela reabre esta tela.
/// O voltar do sistema volta ao catálogo.
class _AdFailed extends StatelessWidget {
  const _AdFailed({required this.onRetry, required this.onLearnMore});

  final Future<void> Function() onRetry;
  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    // H-ANI-24: o erro aparece com calma na primeira vez da sessão.
    return EntradaDaTela(
      id: 'PropV2DemoAnuncioFalhou',
      child: _AdFailedScaffold(onRetry: onRetry, onLearnMore: onLearnMore),
    );
  }
}

class _AdFailedScaffold extends StatelessWidget {
  const _AdFailedScaffold({required this.onRetry, required this.onLearnMore});

  final Future<void> Function() onRetry;
  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      key: AdsKeys.failed,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.xl,
                  ),
                  child: EntradaDeEstado(
                    espaco: AppSpacing.xl,
                    icone: Icon(
                      CanvasSymbols.error,
                      size: 64,
                      fill: 0,
                      weight: 300,
                      color: theme.colorScheme.primary,
                    ),
                    texto: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: AppSpacing.sm,
                      children: [
                        Text(
                          l10n.loadErrorGenericTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 22,
                            height: 28 / 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                        Text(
                          l10n.venAdFailedMessage,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ActionsFooter(
              stacked: true,
              children: [
                BusyButton(
                  buttonKey: AdsKeys.adFailedRetry,
                  label: l10n.licaoAdRetry,
                  onPressed: onRetry,
                ),
                BusyButton(
                  buttonKey: AdsKeys.adFailedLearnMore,
                  label: l10n.licaoAdLearnMore,
                  style: BusyButtonStyle.outlined,
                  onPressed: onLearnMore,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
