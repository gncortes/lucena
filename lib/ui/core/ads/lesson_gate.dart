import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/ads/ads_repository.dart';
import '../../../domain/models/ads_state.dart';
import '../keys/ads_keys.dart';
import '../l10n/l10n.dart';
import '../theme/app_icon_size.dart';
import '../theme/app_shape.dart';
import '../theme/app_spacing.dart';

/// O único ponto que abre ou continua uma lição (E1.25, item 3): conta a
/// lição, mostra o intersticial se o [AdsRepository] decidir e só então
/// chama [open]. Sem anúncio pronto, a lição abre direto.
abstract final class LessonGate {
  static Future<void> open(
    BuildContext context, {
    required String lessonId,
    required LessonKind kind,
    required VoidCallback open,
  }) async {
    final ads = _ads(context);
    final outcome = ads == null
        ? AdOutcome.none
        : await ads.beforeLesson(lessonId: lessonId, kind: kind);
    if (!context.mounted) return;
    if (outcome == AdOutcome.showInApp) {
      await showFakeInterstitial(context);
      if (!context.mounted) return;
    }
    open();
  }

  static AdsRepository? _ads(BuildContext context) {
    try {
      return context.read<AdsRepository>();
    } on ProviderNotFoundException {
      return null;
    }
  }
}

/// O anúncio falso do modo E2E (sem SDK, sem rede): o selo "Anúncio" e o X.
Future<void> showFakeInterstitial(BuildContext context) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (context) => const FakeInterstitial(),
);

class FakeInterstitial extends StatelessWidget {
  const FakeInterstitial({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Dialog.fullscreen(
      key: AdsKeys.fakeInterstitial,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Chip(
                    avatar: const Icon(Icons.campaign, size: AppIconSize.small),
                    label: Text(l10n.adsLabel),
                  ),
                  const Spacer(),
                  IconButton(
                    key: AdsKeys.fakeClose,
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AppShape.large),
                    ),
                    child: const SizedBox.square(
                      dimension: 160,
                      child: Icon(
                        Icons.campaign,
                        size: AppIconSize.illustration,
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                l10n.adsLessonNote,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.adsCloseNote,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
