import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/share/share_repository.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/app_links.dart';
import '../../../domain/models/daily_final.dart';
import '../../../routing/routes.dart';
import '../../core/analytics/analytics_context.dart';
import '../../core/keys/daily_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/share/share_button.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../../core/widgets/position_board.dart';
import '../../core/widgets/sheet_header.dart';
import '../view_models/daily_game_cubit.dart';

/// O que a partida do final do dia põe na app bar: o compartilhar (a qualquer
/// momento, sem ter jogado) e, de quem vê a vitória, o "Parabéns!" (H-DES-01
/// e 02). Sem desenho próprio além do ícone.
class DailyGameActions extends StatelessWidget {
  const DailyGameActions({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<DailyGameCubit, DailyGameState>(
        // O modal abre uma vez, quando a primeira tentativa do dia é gravada
        // como vitória (não quando o app reabre um dia já registrado).
        listenWhen: (previous, current) =>
            previous.ready &&
            previous.record == null &&
            current.record?.outcome == DailyOutcome.won,
        listener: (context, state) {
          final daily = state.daily;
          if (daily != null) unawaited(showDailyWinSheet(context, daily));
        },
        builder: (context, state) {
          final daily = state.daily;
          return IconButton(
            key: DailyKeys.appBarShare,
            tooltip: context.l10n.desafiosDailyShareTooltip,
            icon: const Icon(Icons.share_outlined),
            onPressed: daily == null
                ? null
                : () => unawaited(showDailyShareSheet(context, daily)),
          );
        },
      );
}

/// O convite para compartilhar: a posição inicial (sem coordenadas, sem
/// lances nem resposta) e o texto que vai junto. [won] troca o texto pelo de
/// quem ganhou.
Future<void> showDailyShareSheet(
  BuildContext context,
  DailyFinal daily, {
  bool won = false,
}) => showLucenaSheet<void>(
  context,
  sheetKey: DailyKeys.shareSheet,
  closeKey: DailyKeys.shareSheetClose,
  builder: (_) => _DailyShareSheet(daily: daily, won: won),
);

class _DailyShareSheet extends StatefulWidget {
  const _DailyShareSheet({required this.daily, required this.won});

  final DailyFinal daily;
  final bool won;

  @override
  State<_DailyShareSheet> createState() => _DailyShareSheetState();
}

class _DailyShareSheetState extends State<_DailyShareSheet> {
  final _boundary = GlobalKey();

  Side get _side => Setup.parseFen(widget.daily.position.fen).turn;

  String _text(BuildContext context) {
    final l10n = context.l10n;
    final link = '${AppLinks.finalHost}/${AppLinks.dailySegment}';
    final side = _side.name;
    final goal = widget.daily.position.goal.code;
    return widget.won
        ? l10n.desafiosDailyShareTextWon(side, goal, link)
        : l10n.desafiosDailyShareText(side, goal, link);
  }

  Future<void> _share(BuildContext context) async {
    final text = _text(context);
    final repository = context.read<ShareRepository>();
    final analytics = context.analytics;
    final navigator = Navigator.of(context);
    final background = Theme.of(context).colorScheme.surface;
    final png = await capturePng(_boundary, background: background);
    if (png == null) return;
    unawaited(
      analytics.log(
        AnalyticsEvents.share(
          contentType: 'final_do_dia',
          itemId: widget.daily.position.id,
          resultado: widget.won ? 'ganhou' : 'antes',
        ),
      ),
    );
    await repository.shareImage(
      png,
      name: 'lucena-final-do-dia.png',
      text: text,
    );
    // Ao voltar do menu do sistema, a folha fecha e a partida segue.
    if (navigator.mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetHeader(title: l10n.desafiosDailyShareSheetTitle),
        RepaintBoundary(
          key: _boundary,
          child: LayoutBuilder(
            builder: (context, constraints) => PositionBoard(
              key: DailyKeys.shareImage,
              fen: widget.daily.position.fen,
              size: constraints.maxWidth,
              orientation: _side,
              radius: 0,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SizedBox(
            width: double.infinity,
            child: BusyButton(
              buttonKey: DailyKeys.shareButton,
              label: l10n.desafiosDailyShareButton,
              icon: Icons.share,
              onPressed: () => _share(context),
            ),
          ),
        ),
      ],
    );
  }
}

/// O "Parabéns!" de quem ganhou o final do dia (H-DES-02): compartilhar ou
/// "Agora não", que leva ao Início. Sem confete aqui (animação à parte).
Future<void> showDailyWinSheet(BuildContext context, DailyFinal daily) =>
    showLucenaSheet<void>(
      context,
      sheetKey: DailyKeys.winSheet,
      enableDrag: false,
      builder: (sheetContext) {
        final l10n = sheetContext.l10n;
        final theme = Theme.of(sheetContext);
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events,
                size: AppIconSize.illustration,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.desafiosDailyWinTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.desafiosDailyWinBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: DailyKeys.winShare,
                  icon: const Icon(Icons.share),
                  label: Text(l10n.desafiosDailyWinShare),
                  onPressed: () => unawaited(
                    showDailyShareSheet(sheetContext, daily, won: true),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  key: DailyKeys.winLater,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.go(Routes.home);
                  },
                  child: Text(l10n.desafiosDailyWinLater),
                ),
              ),
            ],
          ),
        );
      },
    );
