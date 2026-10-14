import 'package:flutter/material.dart';

/// As cores que não são do esquema do Material mas o app repete em várias
/// telas (T73, D14): ouro, prata e bronze das estrelas, o verde e o vermelho
/// do lance (certo/errado) e as peças branca e preta. Nenhuma tela escreve
/// `Color(0x…)` à mão: lê daqui ([AppColors.of]) ou, onde não há contexto
/// (valor `const`), pelas constantes de classe.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    this.gold = goldColor,
    this.silver = silverColor,
    this.bronze = bronzeColor,
    this.success = successColor,
    this.error = errorColor,
    this.chessWhite = chessWhiteColor,
    this.chessBlack = chessBlackColor,
  });

  static const goldColor = Color(0xfff2b705);
  static const silverColor = Color(0xffa8b3bd);
  static const bronzeColor = Color(0xffcd7f32);

  /// O lance certo (círculo, seta) e o nível fácil.
  static const successColor = Color(0xff15781b);

  /// O lance errado e o nível difícil.
  static const errorColor = Color(0xffc62828);
  static const chessWhiteColor = Color(0xffffffff);
  static const chessBlackColor = Color(0xff2b2b2b);

  /// A opacidade das marcas de lance sobre o tabuleiro (0xcc).
  static const boardMarkAlpha = 0.8;

  static const standard = AppColors();

  final Color gold;
  final Color silver;
  final Color bronze;
  final Color success;
  final Color error;
  final Color chessWhite;
  final Color chessBlack;

  /// As cores do tema; fora do tema do app (testes de um widget só), as
  /// padrões.
  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? standard;

  @override
  AppColors copyWith({
    Color? gold,
    Color? silver,
    Color? bronze,
    Color? success,
    Color? error,
    Color? chessWhite,
    Color? chessBlack,
  }) => AppColors(
    gold: gold ?? this.gold,
    silver: silver ?? this.silver,
    bronze: bronze ?? this.bronze,
    success: success ?? this.success,
    error: error ?? this.error,
    chessWhite: chessWhite ?? this.chessWhite,
    chessBlack: chessBlack ?? this.chessBlack,
  );

  @override
  AppColors lerp(AppColors? other, double t) => t < 0.5 ? this : other ?? this;
}
