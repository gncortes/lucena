import 'package:flutter/material.dart';

import '../../core/keys/training_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/entrada_em_cascata.dart';
import '../../core/motion/entradas_vistas.dart';
import '../../core/motion/lista_em_ordem.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/canvas_symbols.dart';
import '../../core/widgets/lucena_app_bar.dart';

class TrainingHelpScreen extends StatelessWidget {
  const TrainingHelpScreen({
    required this.onBack,
    required this.onTour,
    this.footer,
    super.key,
  });
  final VoidCallback onBack, onTour;

  /// O cartão no fim da lista (o "Sobre o Pilares", da frente de Venda).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final questions = [
      t.courseGuideFaq1Question,
      t.courseGuideFaq2Question,
      t.courseGuideFaq3Question,
      t.courseGuideFaq4Question,
      t.courseGuideFaq5Question,
      t.courseGuideFaq6Question,
    ];
    final answers = [
      t.courseGuideFaq1Answer,
      t.courseGuideFaq2Answer,
      t.courseGuideFaq3Answer,
      t.courseGuideFaq4Answer,
      t.courseGuideFaq5Answer,
      t.courseGuideFaq6Answer,
    ];
    // H-ANI-16/17: na primeira visita da sessão, os cartões entram em
    // cascata e as perguntas em ordem; voltar mostra tudo pronto.
    return EntradaDaTela(
      id: 'PropV1TreinoAjuda',
      child: _scaffold(context, questions, answers),
    );
  }

  Widget _scaffold(
    BuildContext context,
    List<String> questions,
    List<String> answers,
  ) {
    final t = context.l10n;
    return Scaffold(
      key: TrainingKeys.helpScreen,
      appBar: LucenaAppBar(
        title: Text(t.courseGuideHelpAction),
        leading: IconButton(
          key: TrainingKeys.helpBack,
          onPressed: onBack,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(CanvasSymbols.arrowBack),
        ),
      ),
      body: EntradaEmCascata(
        montar: (itens) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            for (var i = 0; i < itens.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              itens[i],
            ],
          ],
        ),
        itens: [
          ItemDaCascata.texto(
            Material(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppShape.large),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 10,
                  children: [
                    Text(
                      t.courseGuideHelpTourTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      t.courseGuideHelpTourBody,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(letterSpacing: 0),
                    ),
                    FilledButton.icon(
                      key: TrainingKeys.helpTour,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(kButtonHeight),
                      ),
                      onPressed: onTour,
                      icon: const Icon(CanvasSymbols.playArrow, fill: 1),
                      label: Text(t.courseGuideHelpTourAction),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ItemDaCascata.texto(
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppShape.large),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 4,
                  children: [
                    Text(
                      t.courseGuideFaqTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    ListaEmOrdem.feitos(
                      montar: (linhas) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 4,
                        children: linhas,
                      ),
                      itens: [
                        for (var i = 0; i < questions.length; i++)
                          Container(
                            decoration: i == 0
                                ? null
                                : BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outlineVariant,
                                      ),
                                    ),
                                  ),
                            child: ExpansionTile(
                              key: TrainingKeys.faq(i + 1),
                              initiallyExpanded: i == 0,
                              maintainState: true,
                              minTileHeight: 48,
                              visualDensity: VisualDensity.standard,
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: const EdgeInsets.only(bottom: 6),
                              shape: const Border(),
                              collapsedShape: const Border(),
                              title: Text(
                                questions[i],
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontSize: 14,
                                      height: 20 / 14,
                                      letterSpacing: 0,
                                    ),
                              ),
                              children: [
                                // Canvas summary margin-bottom -12 plus answer top 6.
                                Transform.translate(
                                  offset: const Offset(0, -6),
                                  child: Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Text(
                                      answers[i],
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontSize: 14,
                                            height: 20 / 14,
                                            letterSpacing: 0,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (footer case final footer?) ItemDaCascata.texto(footer),
        ],
      ),
    );
  }
}
