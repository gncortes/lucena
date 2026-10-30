import 'package:flutter/material.dart';

import '../keys/core_keys.dart';
import '../theme/app_icon_size.dart';
import '../theme/app_spacing.dart';

/// Como o estado vazio se apresenta (canvas `CompEstadoVazio`).
enum EmptyStateStyle {
  /// Lista que o usuário enche com a ação principal ("Jogar agora").
  primary,

  /// Lista vazia sem urgência: ação tonal.
  tonal,

  /// Algo deu errado: círculo de erro e, se der, "Tentar de novo".
  error,

  /// Só a frase, sem ícone nem ação.
  text,

  /// Os filtros não acharam nada: ícone solto e "Limpar filtros".
  filters,
}

/// Uma lista ainda vazia: um desenho simples, uma frase e, quando houver, a
/// ação que resolve.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.message,
    this.icon,
    this.iconFill,
    this.style = EmptyStateStyle.tonal,
    this.actionLabel,
    this.onAction,
    this.actionKey,
    this.messageKey,
    this.actionIcon,
    this.usePrimaryErrorColor = false,
    this.title,
    this.plainIcon = false,
    super.key,
  });

  /// O círculo do desenho.
  static const circle = 72.0;

  final IconData? icon;
  final String message;
  final EmptyStateStyle style;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;
  final Key? messageKey;
  final IconData? actionIcon;
  final bool usePrimaryErrorColor;
  final String? title;
  final bool plainIcon;
  final double? iconFill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = style == EmptyStateStyle.text;
    final filters = style == EmptyStateStyle.filters;
    final loud = text || filters;
    final label = actionLabel;
    final action = text || label == null || onAction == null
        ? null
        : _action(label);
    return Padding(
      key: CoreKeys.emptyState,
      padding: text
          ? const EdgeInsets.all(AppSpacing.xxl)
          : filters
          ? const EdgeInsets.symmetric(vertical: AppSpacing.xxl)
          : const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!text && icon != null || filters) ...[
            if (filters || plainIcon)
              Icon(
                icon ?? Icons.filter_list_off,
                size: AppIconSize.illustration,
                opticalSize: plainIcon ? AppIconSize.illustration : null,
                color: plainIcon ? colors.onSurfaceVariant : colors.outline,
              )
            else
              _circle(colors),
            const SizedBox(height: AppSpacing.md),
          ],
          if (title case final title?) ...[
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(letterSpacing: 0),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            message,
            key: messageKey,
            textAlign: TextAlign.center,
            style: plainIcon
                ? theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                    height: 20 / 14,
                    letterSpacing: 0,
                  )
                : loud
                ? theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  )
                : theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
          ),
          if (action != null) ...[
            SizedBox(height: filters ? AppSpacing.md : AppSpacing.lg),
            action,
          ],
        ],
      ),
    );
  }

  // O ícone de 48 num círculo suave de 72.
  Widget _circle(ColorScheme colors) {
    final error = style == EmptyStateStyle.error && !usePrimaryErrorColor;
    return Container(
      width: circle,
      height: circle,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: (error ? colors.errorContainer : colors.primaryContainer)
            .withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        fill: iconFill,
        size: AppIconSize.illustration,
        color: error ? colors.error : colors.primary,
      ),
    );
  }

  Widget _action(String label) {
    final text = Text(label);
    switch (style) {
      case EmptyStateStyle.primary:
        return FilledButton.icon(
          key: actionKey ?? CoreKeys.emptyAction,
          onPressed: onAction,
          icon: actionIcon == null ? null : Icon(actionIcon),
          label: text,
        );
      case EmptyStateStyle.filters:
        return OutlinedButton.icon(
          key: actionKey ?? CoreKeys.emptyAction,
          onPressed: onAction,
          icon: const Icon(Icons.filter_list_off),
          label: text,
        );
      case EmptyStateStyle.tonal:
      case EmptyStateStyle.error:
      case EmptyStateStyle.text:
        return FilledButton.tonal(
          key: actionKey ?? CoreKeys.emptyAction,
          onPressed: onAction,
          child: text,
        );
    }
  }
}

/// Algo deu errado: nunca texto técnico, só uma frase e, quando der,
/// "Tentar de novo".
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
      style: EmptyStateStyle.error,
      icon: Icons.cloud_off_rounded,
      message: message,
      messageKey: messageKey,
      actionLabel: retryLabel,
      onAction: onRetry,
    );
  }
}
