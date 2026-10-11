import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Uma lista ainda vazia (T51, G5): um desenho simples, uma frase e, quando
/// houver, a ação que enche a lista ("Jogar agora").
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionKey,
    this.messageKey,
    super.key,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;
  final Key? messageKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final actionLabel = this.actionLabel;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // O desenho: o ícone num círculo suave.
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Icon(icon, size: 40, color: colors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            key: messageKey,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton.tonal(
              key: actionKey,
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }
}

/// Algo deu errado (T51, G5): nunca texto técnico, só uma frase e, quando
/// der, "Tentar de novo".
class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.message,
    this.retryLabel,
    this.onRetry,
    this.messageKey,
    super.key,
  });

  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final Key? messageKey;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      message: message,
      messageKey: messageKey,
      actionLabel: retryLabel,
      onAction: onRetry,
    );
  }
}
