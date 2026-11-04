import 'package:flutter/material.dart';

import '../keys/core_keys.dart';
import '../theme/app_colors.dart';
import '../theme/app_shape.dart';
import '../theme/app_spacing.dart';

/// O cartão do app (T85-D0, superfícies sem branco): #FAFBF9 com contorno
/// 1px #E1E5DF, raio 16 e padding 16. Com [onTap], o cartão inteiro abre.
class LucenaCard extends StatelessWidget {
  const LucenaCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  static const _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppShape.large)),
    side: BorderSide(color: AppColors.cardOutline),
  );

  @override
  Widget build(BuildContext context) {
    final body = Padding(padding: padding, child: child);
    return KeyedSubtree(
      key: key ?? CoreKeys.card,
      child: DecoratedBox(
        decoration: const ShapeDecoration(
          color: AppColors.cardSurface,
          shape: _shape,
        ),
        child: onTap == null
            ? body
            : Material(
                type: MaterialType.transparency,
                child: InkWell(customBorder: _shape, onTap: onTap, child: body),
              ),
      ),
    );
  }
}
