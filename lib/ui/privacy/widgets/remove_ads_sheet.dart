import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/purchase/purchase_repository.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/use_cases/analytics_rules.dart';
import '../../core/analytics/analytics_context.dart';
import '../../core/keys/privacy_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_sheet.dart';

/// "Remover anúncios" (canvas `PropV1AnuncioRemover`): o botão abre a janela
/// de pagamento da Play. Compra confirmada fecha a folha. [origin] é de onde
/// a folha abriu (o `origem` do `anuncio_remocao`).
Future<void> showRemoveAdsSheet(
  BuildContext context, {
  String origin = 'perfil',
}) {
  final purchases = context.read<PurchaseRepository>();
  final analytics = context.analytics;
  return showLucenaSheet<void>(
    context,
    sheetKey: PrivacyKeys.removeSheet,
    builder: (sheet) => RemoveAdsSheet(
      purchases: purchases,
      analytics: analytics,
      origin: origin,
    ),
  );
}

class RemoveAdsSheet extends StatefulWidget {
  const RemoveAdsSheet({
    required this.purchases,
    this.analytics = const NoAnalyticsRepository(),
    this.origin = 'perfil',
    super.key,
  });

  final PurchaseRepository purchases;
  final AnalyticsRepository analytics;
  final String origin;

  @override
  State<RemoveAdsSheet> createState() => _RemoveAdsSheetState();
}

class _RemoveAdsSheetState extends State<RemoveAdsSheet> {
  late final StreamSubscription<PurchaseState> _changes;
  late PurchaseState _state = widget.purchases.state;

  @override
  void initState() {
    super.initState();
    _changes = widget.purchases.changes.listen(_changed);
    _count('aberto');
  }

  void _count(String step) => unawaited(
    widget.analytics.log(
      AnalyticsEvents.anuncioRemocao(etapa: step, origem: widget.origin),
    ),
  );

  void _changed(PurchaseState state) {
    if (!mounted) return;
    if (state.adFree) {
      _count('comprado');
      final value = AnalyticsRules.priceValue(state.price ?? _state.price);
      if (value != null) {
        unawaited(widget.analytics.log(AnalyticsEvents.purchase(value: value)));
      }
      return Navigator.of(context).pop();
    }
    if (state.pending && !_state.pending) _count('pendente');
    // A Play não diz se cancelou ou falhou: os dois contam como cancelado.
    if (state.error && !_state.error) _count('cancelado');
    setState(() => _state = state);
  }

  @override
  void dispose() {
    _changes.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final price = _state.price ?? '';
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppShape.large),
                      ),
                      child: SizedBox.square(
                        dimension: 56,
                        child: Icon(
                          Icons.hide_source,
                          size: AppIconSize.large,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.removeAdsTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n.removeAdsText(price), style: muted),
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n.removeAdsHelp, style: muted),
                  if (_state.pending) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.removeAdsPending,
                      key: PrivacyKeys.removePending,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (_state.error) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.removeAdsError,
                      key: PrivacyKeys.removeError,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ActionsFooter(
              stacked: true,
              margin: AppSpacing.xl,
              note: Text(
                l10n.removeAdsNote,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              children: [
                FilledButton.icon(
                  key: PrivacyKeys.removeBuy,
                  onPressed: _state.pending || _state.price == null
                      ? null
                      : widget.purchases.buy,
                  icon: const Icon(Icons.payments),
                  label: Text(l10n.removeAdsBuy(price)),
                ),
                TextButton(
                  key: PrivacyKeys.removeNo,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.removeAdsNo),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
