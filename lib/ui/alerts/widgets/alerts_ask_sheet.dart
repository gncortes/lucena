import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/push/push_repository.dart';
import '../../core/keys/alerts_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../view_models/alerts_cubit.dart';

/// Abre "Quer receber avisos do Lucena?" (canvas `PropV1RetencaoPermissao`)
/// sobre o fim do primeiro final concluído, do dia ou de torneio. Aparece
/// uma vez só: "Agora não" (ou fechar a folha) não pergunta de novo, e a
/// janela do Android negada fica para Perfil > Avisos.
class AlertsAskGate extends StatefulWidget {
  const AlertsAskGate({required this.child, super.key});

  final Widget child;

  @override
  State<AlertsAskGate> createState() => _AlertsAskGateState();
}

class _AlertsAskGateState extends State<AlertsAskGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_ask()));
  }

  Future<void> _ask() async {
    final push = context.read<PushRepository>();
    if (!await push.shouldAsk() || !mounted) return;
    await push.markAsked();
    if (!mounted) return;
    final alerts = context.read<AlertsCubit>();
    final wants = await showLucenaSheet<bool>(
      context,
      sheetKey: AlertsKeys.askSheet,
      builder: (sheet) => const SafeArea(top: false, child: _AskSheet()),
    );
    if (wants != true) return;
    // No Android 12 ou menor não há janela: a permissão já vem dada.
    await push.requestPermission();
    await alerts.refresh();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AskSheet extends StatelessWidget {
  const _AskSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppShape.large),
                ),
                child: SizedBox.square(
                  dimension: 56,
                  child: Icon(
                    Icons.notifications,
                    size: AppIconSize.large,
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.alertsAskTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.alertsAskText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        ActionsFooter(
          stacked: true,
          children: [
            FilledButton.icon(
              key: AlertsKeys.askYes,
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.notifications),
              label: Text(l10n.alertsAskYes),
            ),
            TextButton(
              key: AlertsKeys.askLater,
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.alertsAskLater),
            ),
          ],
        ),
      ],
    );
  }
}
