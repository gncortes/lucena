import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/lesson_ad/course_access_repository.dart';
import '../../../data/repositories/lesson_ad/demo_ad_repository.dart';
import '../../../data/repositories/review/review_repository.dart';
import '../../../domain/models/course_access.dart';
import '../../../domain/use_cases/ad_policy.dart';
import '../../../routing/route_names.dart';
import '../../core/keys/ads_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/lucena_sheet.dart';

/// O único ponto que abre uma lição (H-LIC-08 a 15): o comprador entra direto;
/// a demonstração vê o aviso uma vez e o anúncio em toda entrada. Substitui o
/// `LessonGate` antigo. Sem [CourseAccessRepository] no contexto, o curso
/// está aberto (V1).
abstract final class LessonEntry {
  /// Abre a lição [lessonId] chamando [open] depois do aviso e do anúncio.
  /// "Agora não" no aviso e "Voltar" na falha deixam a pessoa onde estava.
  static Future<void> open(
    BuildContext context, {
    required String lessonId,
    required String lessonTitle,
    required VoidCallback open,
    DemoAdEntry entry = DemoAdEntry.lesson,
  }) async {
    final access =
        _read<CourseAccessRepository>(context)?.access ?? CourseAccess.owned;
    final ads = _read<DemoAdRepository>(context);
    final review = _read<ReviewRepository>(context);
    final noticeSeen = ads == null ? true : await ads.noticeSeen();
    if (!context.mounted) return;
    final step = DemoAdPolicy.stepFor(
      access: access,
      entry: entry,
      noticeSeen: noticeSeen,
    );
    if (step == DemoAdStep.none || ads == null) {
      open();
      return;
    }
    if (step == DemoAdStep.notice) {
      // Aparece uma vez: marca ao mostrar, até se fechar à força.
      await ads.markNoticeSeen();
      if (!context.mounted) return;
      final see = await showLucenaSheet<bool>(
        context,
        sheetKey: AdsKeys.noticeSheet,
        builder: (context) => const _NoticeSheet(),
      );
      if (see != true || !context.mounted) return;
    }
    final closed = await context.pushNamed<bool>(
      RouteNames.lessonAd,
      extra: LessonAdArgs(lessonTitle: lessonTitle),
    );
    if (closed != true || !context.mounted) return;
    // Logo depois de um anúncio, a Play não pede avaliação (E1.26).
    review?.noteSetback();
    open();
  }

  /// O capítulo [chapterId] está trancado para quem está no contexto?
  static bool isLocked(BuildContext context, String chapterId) {
    final access =
        _read<CourseAccessRepository>(context)?.access ?? CourseAccess.owned;
    final chapter = DemoAdPolicy.chapterOf(chapterId);
    return chapter != null && DemoAdPolicy.isChapterLocked(access, chapter);
  }

  /// O toque num capítulo: aberto segue; trancado mostra a folha
  /// "Comprar o curso" (H-LIC-06). Devolve se o capítulo abriu.
  static Future<bool> openChapter(
    BuildContext context, {
    required String chapterId,
    required String chapterTitle,
  }) async {
    final access =
        _read<CourseAccessRepository>(context)?.access ?? CourseAccess.owned;
    final chapter = DemoAdPolicy.chapterOf(chapterId);
    if (chapter == null || !DemoAdPolicy.isChapterLocked(access, chapter)) {
      return true;
    }
    final buy = await showLucenaSheet<bool>(
      context,
      sheetKey: AdsKeys.lockedSheet,
      builder: (context) => _LockedSheet(title: chapterTitle),
    );
    if (buy == true && context.mounted) {
      await context.pushNamed<void>(RouteNames.pilaresOffer);
    }
    return false;
  }

  static T? _read<T>(BuildContext context) {
    try {
      return context.read<T>();
    } on ProviderNotFoundException {
      return null;
    }
  }
}

/// O que a rota do anúncio recebe.
class LessonAdArgs {
  const LessonAdArgs({required this.lessonTitle});

  final String lessonTitle;
}

/// A folha com ícone, título, texto e os dois botões (canvas `DemoAviso` e
/// `DemoBloqueado`): "filled 48" e "text 48".
class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.icon,
    required this.title,
    required this.body,
    required this.primary,
    required this.later,
    required this.primaryKey,
    required this.laterKey,
    required this.onPrimary,
  });

  final IconData icon;
  final String title;
  final String body;
  final String primary;
  final String later;
  final Key primaryKey;
  final Key laterKey;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          Row(
            spacing: AppSpacing.sm,
            children: [
              Icon(icon, size: 24, color: theme.colorScheme.primary),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            ],
          ),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          BusyButton(
            buttonKey: primaryKey,
            label: primary,
            onPressed: onPrimary,
          ),
          BusyButton(
            buttonKey: laterKey,
            label: later,
            style: BusyButtonStyle.text,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}

class _NoticeSheet extends StatelessWidget {
  const _NoticeSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _SheetBody(
      icon: Icons.campaign_outlined,
      title: l10n.licaoAdNoticeTitle,
      body: l10n.licaoAdNoticeBody,
      primary: l10n.licaoAdNoticeSee,
      later: l10n.licaoDemoLater,
      primaryKey: AdsKeys.demoAdNoticeSee,
      laterKey: AdsKeys.demoAdNoticeLater,
      onPrimary: () => Navigator.of(context).pop(true),
    );
  }
}

class _LockedSheet extends StatelessWidget {
  const _LockedSheet({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _SheetBody(
      icon: Icons.lock_outline,
      title: title,
      body: l10n.licaoLockedBody,
      primary: l10n.licaoLockedBuy,
      later: l10n.licaoDemoLater,
      primaryKey: AdsKeys.demoLockedSheetBuy,
      laterKey: AdsKeys.demoLockedSheetLater,
      onPrimary: () => Navigator.of(context).pop(true),
    );
  }
}
