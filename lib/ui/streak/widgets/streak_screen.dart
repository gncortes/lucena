import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/widgets/load_error.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat, toBeginningOfSentenceCase;

import '../../core/keys/motion_keys.dart';
import '../../core/keys/streak_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/anel_da_meta.dart';
import '../../core/motion/entradas_vistas.dart';
import '../../core/motion/lucena_motion.dart';
import '../../core/motion/meta_da_semana.dart';
import '../../core/motion/numero_que_conta.dart';
import '../../core/motion/shimmer_conteudo.dart';
import '../../core/motion/valor_que_anima.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/load_skeleton.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/scroll_padding.dart';
import '../view_models/streak_cubit.dart';

/// A Sequência (canvas `PropV1RetencaoSequencia`): dias seguidos e recorde, a
/// semana de segunda a domingo e o mês com os dias marcados.
class StreakScreen extends StatelessWidget {
  const StreakScreen({super.key});

  /// Quadro do canvas, para a primeira entrada da sessão.
  static const streakEntranceId = 'PropV1RetencaoSequencia';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.watch<StreakCubit>();
    if (cubit.state.failure case final failure?) {
      return KeyedSubtree(
        key: StreakKeys.error,
        child: LoadErrorScreen(
          kind: LoadErrorKind.fromFailure(failure),
          onAction: cubit.load,
          onBack: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
      );
    }
    return EntradaDaTela(
      id: StreakScreen.streakEntranceId,
      child: Scaffold(
        key: StreakKeys.screen,
        appBar: LucenaAppBar(title: Text(l10n.streakTitle)),
        body: BlocBuilder<StreakCubit, StreakState>(
          builder: (context, state) => ShimmerConteudo(
            carregando: !state.ready,
            // Canvas `PropV1InicioSequenciaCarregando`.
            esqueleto: const KeyedSubtree(
              key: StreakKeys.loading,
              child: SkeletonBody([
                SkeletonShape.block(height: 160),
                SkeletonShape.block(height: 64),
                SkeletonShape.block(height: 20, radius: AppShape.small),
                SkeletonShape.block(height: 20, radius: AppShape.small),
                SkeletonShape.block(height: 20, radius: AppShape.small),
              ]),
            ),
            child: ListView(
              padding: scrollPadding(
                context,
                left: AppSpacing.screen,
                top: AppSpacing.sm,
                right: AppSpacing.screen,
              ),
              children: [
                _Hero(state: state),
                const SizedBox(height: AppSpacing.betweenCards),
                _Month(state: state),
                const SizedBox(height: AppSpacing.betweenCards),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Text(
                    l10n.streakRules,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

// Os dias seguidos, o recorde e a faixa da semana.
class _Hero extends StatelessWidget {
  const _Hero({required this.state});

  final StreakState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final streak = state.streak;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final today = state.today;
    // H-ANI-28: hoje cumprido comemora na faixa da semana e no contador.
    return MetaDaSemana(
      cumprida: state.ready && today != null && state.run.contains(today),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.insideCard),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(AppShape.large),
                    ),
                    child: SizedBox.square(
                      dimension: 64,
                      child: Icon(
                        Icons.event_repeat,
                        size: AppIconSize.large,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      key: StreakKeys.current,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) {
                            final estilo = theme.textTheme.headlineLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                );
                            final meta = MetaDaSemana.of(context);
                            if (!meta.festa) {
                              return ValorQueAnima(
                                valor: streak.current.toDouble(),
                                duracao: LucenaMotion.numeroConta,
                                builder: (context, agora) => Text(
                                  l10n.streakDayCount(agora.round()),
                                  style: estilo,
                                ),
                              );
                            }
                            // Na festa, o contador sai do valor de ontem e
                            // sobe com um salto.
                            return Transform.scale(
                              key: MotionKeys.contadorDaMeta,
                              alignment: AlignmentDirectional.centerStart
                                  .resolve(Directionality.of(context)),
                              scale: meta.contadorAntes ? 1 : meta.contador,
                              child: Text(
                                l10n.streakDayCount(
                                  meta.contadorAntes
                                      ? streak.current - 1
                                      : streak.current,
                                ),
                                style: estilo,
                              ),
                            );
                          },
                        ),
                        Text(
                          l10n.streakFollowing(streak.current),
                          style: muted,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    key: StreakKeys.record,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      NumeroQueConta(
                        valor: streak.record,
                        alinhamento: AlignmentDirectional.centerEnd,
                        estilo: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l10n.streakRecord,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              StreakWeek(state: state),
            ],
          ),
        ),
      ),
    );
  }
}

/// Segunda a domingo: os dias da sequência atual com o check, hoje com anel.
/// Também no cartão da sequência do resultado do final do dia.
class StreakWeek extends StatelessWidget {
  const StreakWeek({required this.state, super.key});

  final StreakState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final weekday = DateFormat.EEEEE(
      Localizations.localeOf(context).toString(),
    );
    final meta = MetaDaSemana.of(context);
    final cumprida = state.today != null && state.run.contains(state.today);
    // A ordem da onda: os dias da sequência antes de hoje, da esquerda.
    final antes = [
      for (final day in state.week)
        if (day != state.today && state.run.contains(day)) day,
    ];
    final week = state.week;
    return Row(
      key: StreakKeys.weekStrip,
      children: [
        for (final (i, day) in week.indexed)
          Expanded(
            child: Column(
              children: [
                Text(
                  weekday.format(day),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _Ring(
                  on: day == state.today,
                  // H-ANI-28: o anel de hoje fecha quando a meta é cumprida.
                  tempo: day == state.today && cumprida ? meta.anel : null,
                  gap: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: state.run.contains(day)
                          ? colors.primary
                          : colors.surfaceContainerHighest,
                    ),
                    child: SizedBox.square(
                      dimension: 32,
                      child: state.run.contains(day)
                          ? Transform.scale(
                              key: MotionKeys.checkDaSemana(i),
                              scale: day == state.today
                                  ? meta.checkDeHoje
                                  : meta.checkAnterior(antes.indexOf(day)),
                              child: Icon(
                                Icons.check,
                                size: AppIconSize.button,
                                color: colors.onPrimary,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// O mês de hoje, com a semana começando na segunda.
class _Month extends StatelessWidget {
  const _Month({required this.state});

  final StreakState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final days = state.month;
    final weekday = DateFormat.EEEEE(locale);
    final blanks = days.first.weekday - DateTime.monday;
    final cells = <DateTime?>[for (var i = 0; i < blanks; i++) null, ...days];
    while (cells.length % DateTime.daysPerWeek != 0) {
      cells.add(null);
    }
    final label = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.insideCard),
        child: Column(
          key: StreakKeys.monthGrid,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              toBeginningOfSentenceCase(
                DateFormat.yMMMM(locale).format(days.first),
                locale,
              ),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                for (final day in state.week)
                  Expanded(
                    child: Text(
                      weekday.format(day),
                      textAlign: TextAlign.center,
                      style: label,
                    ),
                  ),
              ],
            ),
            for (var row = 0; row < cells.length; row += DateTime.daysPerWeek)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Row(
                  children: [
                    for (final day in cells.sublist(
                      row,
                      row + DateTime.daysPerWeek,
                    ))
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: day == null
                              ? null
                              : Center(
                                  child: _Day(day: day, state: state),
                                ),
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

class _Day extends StatelessWidget {
  const _Day({required this.day, required this.state});

  final DateTime day;
  final StreakState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final inRun = state.run.contains(day);
    final active = state.active.contains(day);
    final future = state.today != null && day.isAfter(state.today!);
    return _Ring(
      key: StreakKeys.day(day.day),
      on: day == state.today,
      gap: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: inRun
              ? colors.primary
              // Dias de sequências que já acabaram: marcados, mais claros.
              : active
              ? colors.primary.withValues(alpha: 0.3)
              : null,
        ),
        child: SizedBox.square(
          dimension: 34,
          child: Center(
            child: Text(
              '${day.day}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: inRun
                    ? colors.onPrimary
                    : future
                    ? colors.outline
                    : colors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// O anel de hoje, por fora do círculo, sem mudar o tamanho dele.
class _Ring extends StatelessWidget {
  const _Ring({
    super.key,
    required this.on,
    required this.gap,
    required this.child,
    this.tempo,
  });

  final bool on;

  /// Com valor, o anel é pintado fechando até [tempo] (0 a 1).
  final double? tempo;
  final double gap;
  final Widget child;

  static const _width = 2.0;

  @override
  Widget build(BuildContext context) {
    if (!on) return child;
    final outside = -(gap + _width);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          left: outside,
          top: outside,
          right: outside,
          bottom: outside,
          child: IgnorePointer(
            child: tempo == null
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: _width,
                      ),
                    ),
                  )
                : CustomPaint(
                    key: MotionKeys.anelDaMeta,
                    painter: PintorDoAnel(
                      tempo: tempo!,
                      feito: 1,
                      espessura: _width,
                      faixa: Colors.transparent,
                      cor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
