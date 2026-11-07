import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/training/training_course.dart';
import '../../../routing/frentes/d2_routes.dart';
import '../../../routing/routes.dart';
import '../../core/keys/purchase_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/busy_button.dart';
import 'pilares_sale_parts.dart';

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

/// Os botões de quem acabou de ter o curso: "Escolher meu objetivo" (com o
/// estádio) e o outro caminho ("Ver o curso" na Concluída; "Continuar o
/// curso", que vem primeiro, na Restaurada). O do curso abre o Guia do
/// Pilares (sugestão S1 do T85, aprovada pelo Gabriel em 06/11: antes ia ao
/// Perfil); o do objetivo, "Seu objetivo" (H-TRE-06). Na Concluída o do curso
/// é contornado, para não parecer um link solto sob o botão principal.
List<Widget> pilaresOwnedActions(
  BuildContext context, {
  required bool goalFirst,
  required String other,
  required Key goalKey,
  required Key otherKey,
}) {
  final l10n = context.l10n;
  void goal() => context.go(D2Paths.pilaresGoal);
  void course() => context.go(Routes.training(TrainingCourse.pilares.name));
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
            style: BusyButtonStyle.outlined,
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
