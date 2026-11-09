import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/view_models/lesson_ad.dart';
import '../../../domain/use_cases/ad_policy.dart';
import '../../../routing/frentes/d2_routes.dart' show pilaresSaleOrigin;
import '../../../routing/route_names.dart';
import '../../core/keys/ads_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/entrada_em_cascata.dart';
import '../../core/motion/entradas_vistas.dart';
import '../../core/motion/rota_que_abre.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/lucena_sheet.dart';

/// O único ponto que abre uma lição (H-LIC-08 a 15): o comprador entra direto;
/// a demonstração vê o aviso uma vez e o anúncio em toda entrada. Substitui o
/// `LessonGate` antigo. Sem o acesso ao curso no contexto, o curso
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
    final gate = createLessonEntryGate(context);
    final noticeSeen = await gate.noticeSeen();
    if (!context.mounted) return;
    final step = DemoAdPolicy.stepFor(
      access: gate.access,
      entry: entry,
      noticeSeen: noticeSeen,
    );
    if (step == DemoAdStep.none || !gate.hasAds) {
      open();
      return;
    }
    if (step == DemoAdStep.notice) {
      // Aparece uma vez: marca ao mostrar, até se fechar à força.
      await gate.markNoticeSeen();
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
    gate.noteSetback();
    open();
  }

  /// O capítulo [chapterId] está trancado para quem está no contexto?
  static bool isLocked(BuildContext context, String chapterId) {
    final access = createLessonEntryGate(context).access;
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
    final access = createLessonEntryGate(context).access;
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
      await context.pushNamed<void>(
        RouteNames.pilaresOffer,
        queryParameters: const {'origem': 'catalogo'},
      );
    }
    return false;
  }

  /// Uma parte que só o curso completo tem (a meta trancada da demo,
  /// H-VEN-12): a mesma folha do capítulo trancado, com o cadeado, outro
  /// texto e "Agora não". Devolve se a pessoa pediu [primary].
  ///
  /// A folha é a [OrigemQueAbre] de [origem] (H-ANI-04): a tela aberta por
  /// [primary] cresce dela, e não da chamada da aba que fica embaixo.
  static Future<bool> showLockedFeature(
    BuildContext context, {
    required String title,
    required String body,
    required String primary,
    required Key sheetKey,
    required Key primaryKey,
    required Key laterKey,
    String quadro = 'PropV2MetaSemCompraDemoCadeadoFolha',
    String origem = pilaresSaleOrigin,
  }) async =>
      await showLucenaSheet<bool>(
        context,
        sheetKey: sheetKey,
        builder: (context) {
          final theme = Theme.of(context);
          return OrigemQueAbre(
            id: origem,
            // A cópia que cresce leva o fundo da folha.
            child: ColoredBox(
              color:
                  theme.bottomSheetTheme.modalBackgroundColor ??
                  theme.colorScheme.surfaceContainerLow,
              child: _SheetBody(
                quadro: quadro,
                icon: Icons.lock,
                title: title,
                body: body,
                primary: primary,
                later: context.l10n.licaoDemoLater,
                primaryKey: primaryKey,
                laterKey: laterKey,
                onPrimary: () => Navigator.of(context).pop(true),
              ),
            ),
          );
        },
      ) ==
      true;
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
    required this.quadro,
  });

  /// O quadro do canvas (a cascata só entra na primeira vez dele).
  final String quadro;
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
    // H-ANI-16: com a folha já parada, título, texto e os botões entram em
    // cascata, só na primeira vez que o quadro aparece na sessão.
    return EntradaDaTela(
      id: quadro,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: EntradaEmCascata(
          montar: (itens) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.md,
            children: itens,
          ),
          itens: [
            ItemDaCascata.titulo(
              Row(
                spacing: AppSpacing.sm,
                children: [
                  Icon(
                    icon,
                    size: AppIconSize.standard,
                    color: theme.colorScheme.primary,
                  ),
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                ],
              ),
            ),
            ItemDaCascata.texto(
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ItemDaCascata.botao(
              BusyButton(
                buttonKey: primaryKey,
                label: primary,
                onPressed: onPrimary,
              ),
            ),
            ItemDaCascata.botao(
              BusyButton(
                buttonKey: laterKey,
                label: later,
                style: BusyButtonStyle.text,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
          ],
        ),
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
      quadro: 'PropV2DemoAviso',
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
      quadro: 'PropV2DemoBloqueado',
      primaryKey: AdsKeys.demoLockedSheetBuy,
      laterKey: AdsKeys.demoLockedSheetLater,
      onPrimary: () => Navigator.of(context).pop(true),
    );
  }
}
