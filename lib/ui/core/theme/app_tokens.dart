import 'package:flutter/material.dart';

import 'app_shape.dart';
import 'app_spacing.dart';

/// Os tokens de forma e espaço no tema, para os componentes lerem do
/// contexto ([AppTokens.of]).
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    this.radiusSmall = AppShape.small,
    this.radiusMedium = AppShape.medium,
    this.radiusLarge = AppShape.large,
    this.screenPadding = AppSpacing.screen,
    this.betweenCards = AppSpacing.betweenCards,
    this.insideCard = AppSpacing.insideCard,
  });

  static const standard = AppTokens();

  final double radiusSmall;
  final double radiusMedium;
  final double radiusLarge;
  final double screenPadding;
  final double betweenCards;
  final double insideCard;

  /// Os tokens do tema; fora do tema do app (testes de um widget só), os
  /// padrões.
  static AppTokens of(BuildContext context) =>
      Theme.of(context).extension<AppTokens>() ?? standard;

  @override
  AppTokens copyWith({
    double? radiusSmall,
    double? radiusMedium,
    double? radiusLarge,
    double? screenPadding,
    double? betweenCards,
    double? insideCard,
  }) => AppTokens(
    radiusSmall: radiusSmall ?? this.radiusSmall,
    radiusMedium: radiusMedium ?? this.radiusMedium,
    radiusLarge: radiusLarge ?? this.radiusLarge,
    screenPadding: screenPadding ?? this.screenPadding,
    betweenCards: betweenCards ?? this.betweenCards,
    insideCard: insideCard ?? this.insideCard,
  );

  // Os tokens são fixos: a troca de tema não os interpola.
  @override
  AppTokens lerp(AppTokens? other, double t) => t < 0.5 ? this : other ?? this;
}
