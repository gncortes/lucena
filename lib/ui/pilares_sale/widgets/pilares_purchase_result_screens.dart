import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/frentes/d2_routes.dart';
import '../../../routing/routes.dart';
import '../../core/keys/purchase_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/sucesso_da_compra.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/busy_button.dart';
import 'pilares_sale_parts.dart';

/// "O curso completo é seu" (H-VEN-05). Voltar vai ao Início, nunca de
/// volta à oferta.
class PilaresPurchaseDoneScreen extends StatelessWidget {
  const PilaresPurchaseDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return KeyedSubtree(
      key: PurchaseKeys.doneScreen,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) context.go(Routes.home);
        },
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.xl,
                ),
                child: SucessoDaCompra(
                  titulo: Text(
                    l10n.venDoneTitle,
                    key: PurchaseKeys.doneTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  texto: Text(
                    l10n.venDoneText,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  botoes: pilaresOwnedActions(
                    context,
                    goalFirst: true,
                    goalKey: PurchaseKeys.doneGoal,
                    otherKey: PurchaseKeys.doneSeeCourse,
                    other: l10n.venSeeCourse,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Pagamento pendente" (H-VEN-06): "Entendi" volta para quem abriu a oferta.
class PilaresPurchasePendingScreen extends StatelessWidget {
  const PilaresPurchasePendingScreen({super.key});

  void _close(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(Routes.home);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return KeyedSubtree(
      key: PurchaseKeys.pendingScreen,
      child: PilaresResultScreen(
        icon: Icons.hourglass_top,
        done: false,
        title: l10n.venPendingTitle,
        text: l10n.venPendingText,
        onBack: () => _close(context),
        actions: [
          BusyButton(
            buttonKey: PurchaseKeys.pendingOk,
            label: l10n.venPendingOk,
            onPressed: () => _close(context),
          ),
        ],
      ),
    );
  }
}

/// Os botões de quem acabou de ter o curso: "Definir meu objetivo" (com o
/// estádio) e o outro caminho ("Ver o curso" na Concluída; "Continuar o
/// curso", que vem primeiro, na Restaurada). Os dois levam ao perfil com o
/// cartão do curso (H-VEN-09) ou a "Seu objetivo" (H-TRE-06).
List<Widget> pilaresOwnedActions(
  BuildContext context, {
  required bool goalFirst,
  required String other,
  required Key goalKey,
  required Key otherKey,
}) {
  final l10n = context.l10n;
  void goal() => context.go(D2Paths.pilaresGoal);
  void course() => context.go(Routes.settingsProfile);
  return goalFirst
      ? [
          BusyButton(
            buttonKey: goalKey,
            icon: Icons.stadium,
            label: l10n.venDefineGoal,
            onPressed: goal,
          ),
          BusyButton(
            buttonKey: otherKey,
            style: BusyButtonStyle.text,
            label: other,
            onPressed: course,
          ),
        ]
      : [
          BusyButton(buttonKey: otherKey, label: other, onPressed: course),
          BusyButton(
            buttonKey: goalKey,
            style: BusyButtonStyle.text,
            label: l10n.venDefineGoal,
            onPressed: goal,
          ),
        ];
}
