import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../data/repositories/share/share_repository.dart';
import '../../../domain/models/app_links.dart';
import '../../../domain/models/daily_final.dart';
import '../../core/keys/daily_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/share/share_button.dart';
import '../../core/share/share_cubit.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../streak/view_models/streak_cubit.dart';
import '../view_models/daily_result_cubit.dart';
import 'daily_squares.dart';

/// A prévia do compartilhar (canvas `PropV1RetencaoImagem`): a imagem só com
/// o resultado (sem a posição nem os lances) e o texto que vai junto.
class DailyShareScreen extends StatefulWidget {
  const DailyShareScreen({super.key});

  @override
  State<DailyShareScreen> createState() => _DailyShareScreenState();
}

class _DailyShareScreenState extends State<DailyShareScreen> {
  final _boundary = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final record = context.select((DailyResultCubit c) => c.state.record);
    final days = context.select((StreakCubit c) => c.state.streak.current);
    final text = record == null ? null : _text(context, record, days);
    return BlocProvider(
      create: (context) => ShareCubit(context.read<ShareRepository>()),
      child: Scaffold(
        key: DailyKeys.shareScreen,
        appBar: LucenaAppBar(title: Text(l10n.dailyShareTitle)),
        body: record == null || text == null
            ? const SizedBox.shrink()
            : ListView(
                padding: scrollPadding(
                  context,
                  left: AppSpacing.screen,
                  top: AppSpacing.sm,
                  right: AppSpacing.screen,
                ),
                children: [
                  Center(
                    child: RepaintBoundary(
                      key: _boundary,
                      child: DailyShareImage(record: record, days: days),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.insideCard),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.dailyShareTextLabel,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(text, style: theme.textTheme.bodyLarge),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.dailyShareNote,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: record == null || text == null
            ? null
            : BlocBuilder<ShareCubit, bool>(
                builder: (context, sharing) => ActionsFooter(
                  children: [
                    FilledButton.icon(
                      key: DailyKeys.shareButton,
                      onPressed: sharing ? null : () => _share(context, text),
                      icon: const Icon(Icons.share_rounded),
                      label: Text(l10n.dailyShareTitle),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _share(BuildContext context, String text) async {
    final cubit = context.read<ShareCubit>();
    final png = await capturePng(
      _boundary,
      background: Theme.of(context).scaffoldBackgroundColor,
    );
    if (png == null) return;
    await cubit.share(png, name: 'lucena-final-do-dia.png', text: text);
  }

  // "Final do dia do Lucena, 22 de outubro: ganhei em 5 lances e a
  // sequência está em 12 dias. Você acha o lance? <link>".
  String _text(BuildContext context, DailyRecord record, int days) {
    final l10n = context.l10n;
    final line = dailyImageLine(l10n, record);
    final result = line.isEmpty
        ? line
        : line[0].toLowerCase() + line.substring(1);
    return l10n.dailyShareText(
      dailyDate(context, record.date),
      result,
      days,
      AppLinks.uri('/${AppLinks.dailySegment}').toString(),
    );
  }
}

/// A imagem de 332 x 332: a marca, a data, os quadradinhos, o resultado, a
/// sequência e o link.
class DailyShareImage extends StatelessWidget {
  const DailyShareImage({required this.record, required this.days, super.key});

  final DailyRecord record;
  final int days;

  static const size = 332.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final ink = colors.onPrimary;
    final soft = ink.withValues(alpha: 0.85);
    // A imagem tem tamanho fixo: o tamanho de letra do aparelho não a muda.
    return MediaQuery.withNoTextScaling(
      child: Container(
        key: DailyKeys.shareImage,
        width: size,
        height: size,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(AppShape.large),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppShape.small),
                      child: Image.asset(
                        'assets/branding/launcher_icon.png',
                        width: 40,
                        height: 40,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l10n.appTitle,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.dailyShareImageDate(dailyDate(context, record.date)),
                  style: theme.textTheme.bodyMedium?.copyWith(color: soft),
                ),
              ],
            ),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  children: [
                    DailySquares(
                      squares: record.squares,
                      size: record.squares.length > 6 ? 22 : 40,
                      gap: record.squares.length > 6
                          ? AppSpacing.xs
                          : AppSpacing.sm,
                      radius: AppShape.tiny,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      dailyImageLine(l10n, record),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.event_repeat, size: AppIconSize.button, color: ink),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    l10n.streakDays(days),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    '${AppLinks.host}/${AppLinks.dailySegment}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(color: soft),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
