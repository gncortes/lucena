import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../core/widgets/actions_footer.dart';

/// O corpo das duas telas de atualização (canvas `PropV1AtualizarObrigatoria`
/// e `PropV1AtualizarRecomendada`): o ícone num quadrado, o título e o texto
/// no meio, e os botões embaixo.
class UpdateBody extends StatelessWidget {
  const UpdateBody({
    required this.title,
    required this.body,
    required this.actions,
    super.key,
  });

  final String title;
  final String body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppShape.large),
                      ),
                      child: SizedBox.square(
                        dimension: 72,
                        child: Icon(
                          Icons.system_update,
                          size: AppIconSize.illustration,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ActionsFooter(
            stacked: true,
            margin: AppSpacing.xl,
            children: actions,
          ),
        ],
      ),
    );
  }
}
