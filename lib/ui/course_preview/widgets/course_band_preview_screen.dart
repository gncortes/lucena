import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/course_preview.dart';
import '../../core/keys/course_preview_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/scroll_padding.dart';
import '../view_models/course_preview_cubit.dart';

/// "Para quem é" do Pilares do Xadrez (canvas `PropV2CursoFaixa`): por que a
/// faixa é larga, o gráfico da frequência de cada tema por faixa de rating e
/// o aviso de que o curso não promete rating. Abre pelo cartão da faixa na
/// Visão geral da venda.
class CourseBandPreviewScreen extends StatelessWidget {
  const CourseBandPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CoursePreviewCubit, CoursePreviewState>(
      builder: (context, state) {
        final band = state.preview?.sale.band;
        return Scaffold(
          key: CoursePreviewKeys.band,
          appBar: LucenaAppBar(title: Text(context.l10n.courseSaleAudience)),
          body: band == null
              ? const SizedBox.shrink()
              : ListView(
                  // faixa_corpo: coluna 8 16 32 16, 12 entre os blocos.
                  padding: scrollPadding(
                    context,
                    left: AppSpacing.lg,
                    top: AppSpacing.sm,
                    right: AppSpacing.lg,
                    bottom: AppSpacing.xxl,
                  ),
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AppSpacing.md,
                      children: [
                        Text(band.heading, style: _strong(context, 22, 28)),
                        Text(
                          band.line,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontSize: 15, height: 22 / 15),
                        ),
                        _Chart(band: band),
                        _Warning(item: band.warning),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }
}

TextStyle? _strong(BuildContext context, double size, double line) =>
    Theme.of(context).textTheme.titleMedium?.copyWith(
      fontSize: size,
      height: line / size,
      fontWeight: AppWeight.strong,
    );

TextStyle? _small(BuildContext context, double size, double line) =>
    Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: size,
      height: line / size,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

/// O gráfico (cartao, 14 entre as linhas): título, nota, legenda, uma barra
/// por faixa em cada tema e a fonte.
class _Chart extends StatelessWidget {
  const _Chart({required this.band});

  final CourseSaleBand band;

  /// A escala do canvas: 15 % ocupa 78 % da largura da barra.
  static const _scale = 15.0;
  static const _fill = 0.78;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Os três azuis do canvas (#9DB4D9, #4F75B8 e o azul do app), do mais
    // claro para a faixa mais alta.
    final tones = [
      colors.primary.withValues(alpha: 0.45),
      colors.primary.withValues(alpha: 0.8),
      colors.primary,
    ];
    final percent = NumberFormat(
      '0.0',
      Localizations.localeOf(context).toString(),
    );
    return DecoratedBox(
      key: CoursePreviewKeys.bandChart,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppShape.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            Text(band.chartTitle, style: _strong(context, 17, 22)),
            Text(band.chartNote, style: _small(context, 14, 20)),
            Wrap(
              spacing: 14,
              runSpacing: AppSpacing.xs,
              children: [
                for (final (i, range) in band.ranges.indexed)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: tones[i % tones.length],
                          borderRadius: BorderRadius.circular(AppShape.tiny),
                        ),
                      ),
                      Text(range, style: _small(context, 13, 18)),
                    ],
                  ),
              ],
            ),
            for (final theme in band.themes)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.xs,
                children: [
                  Text(theme.name, style: _strong(context, 15, 20)),
                  for (final (i, value) in theme.values.indexed)
                    LayoutBuilder(
                      builder: (context, constraints) => Row(
                        spacing: AppSpacing.sm,
                        children: [
                          // Flexible: a barra encolhe antes de empurrar o
                          // número para fora.
                          Flexible(
                            child: Container(
                              width:
                                  constraints.maxWidth *
                                  (value / _scale).clamp(0, 1) *
                                  _fill,
                              height: 8,
                              decoration: BoxDecoration(
                                color: tones[i % tones.length],
                                borderRadius: BorderRadius.circular(
                                  AppShape.tiny,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            '${percent.format(value)} %',
                            style: _small(context, 12, 16),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            Text(band.source, style: _small(context, 12, 17)),
          ],
        ),
      ),
    );
  }
}

/// O aviso "Sem promessa de rating": cartão branco com borda e o ícone de
/// informação.
class _Warning extends StatelessWidget {
  const _Warning({required this.item});

  final CourseSaleItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppShape.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.md,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 22,
              color: colors.onSurfaceVariant,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(item.title, style: _strong(context, 16, 22)),
                  if (item.summary != null)
                    Text(item.summary!, style: _small(context, 14, 20)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
