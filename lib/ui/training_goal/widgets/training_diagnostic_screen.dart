import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/training/goal/training_diagnostic.dart';
import '../../../domain/use_cases/training/goal/goal_view.dart';
import '../../core/keys/training_goal_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/choice_card.dart';
import '../view_models/training_goal_cubit.dart';
import 'goal_page.dart';

/// "Como montar o plano" (H-TRE-04, quadro PropV2MetaDiagnostico): teste de
/// posições ou questionário, em opções de escolha única (H-ANI-30), e o
/// rodapé "Continuar" segue a marcada.
///
/// A marca vem do diagnóstico salvo (voltar com um teste começado mostra o
/// teste marcado); sem o teste baixado, o questionário vem marcado.
class TrainingDiagnosticScreen extends StatefulWidget {
  const TrainingDiagnosticScreen({
    required this.onBack,
    required this.onTest,
    required this.onQuestionnaire,
    super.key,
  });
  final VoidCallback onBack, onTest, onQuestionnaire;

  @override
  State<TrainingDiagnosticScreen> createState() =>
      _TrainingDiagnosticScreenState();
}

class _TrainingDiagnosticScreenState extends State<TrainingDiagnosticScreen> {
  DiagnosticMethod? _tocada;

  DiagnosticMethod? _marcada(TrainingGoalCubit cubit, GoalView view) {
    final available = cubit.testAvailable(cubit.testSize());
    final escolha = _tocada ?? view.state.diagnostic?.method;
    if (!available) return DiagnosticMethod.questionnaire;
    return escolha;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cubit = context.read<TrainingGoalCubit>();
    return GoalPage(
      screenKey: TrainingGoalKeys.diagnosticScreen,
      title: t.treinoPlanTitle,
      onBack: widget.onBack,
      builder: (context, view) {
        final size = cubit.testSize();
        final available = cubit.testAvailable(size);
        final marcada = _marcada(cubit, view);
        return [
          Text(
            t.treinoDiagIntro,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          ChoiceCard(
            key: TrainingGoalKeys.diagnosticTest,
            icon: Icons.quiz,
            title: t.treinoDiagTest,
            body: t.treinoDiagTestSub(size),
            selected: marcada == DiagnosticMethod.test,
            onTap: available
                ? () => setState(() => _tocada = DiagnosticMethod.test)
                : null,
          ),
          if (!available)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                t.treinoDiagOffline,
                key: TrainingGoalKeys.diagnosticOffline,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          ChoiceCard(
            key: TrainingGoalKeys.diagnosticQuestionnaire,
            icon: Icons.checklist,
            title: t.treinoDiagQuest,
            body: t.treinoDiagQuestSub,
            selected: marcada == DiagnosticMethod.questionnaire,
            onTap: () =>
                setState(() => _tocada = DiagnosticMethod.questionnaire),
          ),
        ];
      },
      footer: (context, view) {
        final marcada = _marcada(cubit, view);
        return BlocBuilder<TrainingGoalCubit, TrainingGoalState>(
          builder: (context, state) => BusyButton(
            buttonKey: TrainingGoalKeys.diagnosticContinue,
            label: t.treinoContinue,
            busy: state.saving,
            onPressed: switch (marcada) {
              null => null,
              DiagnosticMethod.test => () async {
                if (await cubit.chooseTest()) widget.onTest();
              },
              DiagnosticMethod.questionnaire => () async {
                if (await cubit.chooseQuestionnaire()) {
                  widget.onQuestionnaire();
                }
              },
            },
          ),
        );
      },
    );
  }
}
