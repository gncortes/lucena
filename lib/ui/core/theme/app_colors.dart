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

  /// O verde do recorde novo (texto e ícone do troféu).
  static const record = Color(0xff2e6b3a);

  static const goldColor = Color(0xfff2b705);

  /// Texto sobre o dourado (D26): selos, medalha e relatório.
  static const goldInk = Color(0xff5a3c00);

  /// O preto quente do relógio e do confronto (D26). [chessBlackColor] é só
  /// a peça.
  static const ink = Color(0xff312e2b);
  static const silverColor = Color(0xffa8b3bd);
  static const bronzeColor = Color(0xffcd7f32);

  /// O lance certo (círculo, seta) e o nível fácil.
  static const successColor = Color(0xff15781b);

  /// O lance errado e o nível difícil.
  static const errorColor = Color(0xffc62828);
  static const chessWhiteColor = Color(0xffffffff);
  static const chessBlackColor = Color(0xff2b2b2b);

  /// As cores do avatar (canvas `PropV1PerfilDados`): a inicial na cor da
  /// frente, sobre o fundo. Fixas, iguais em todo tema de destaque.
  static const avatars = <({Color foreground, Color background})>[
    (foreground: Color(0xff24508f), background: Color(0xffd6e4fb)),
    (foreground: Color(0xff2e6b3a), background: Color(0xffddebdd)),
    (foreground: Color(0xff7a5900), background: Color(0xffffe2a6)),
    (foreground: Color(0xff6b3fa0), background: Color(0xffeaddff)),
    (foreground: Color(0xff8c1d18), background: Color(0xffffdad6)),
  ];

  // Neutros e sombras.
  static const white = Color(0xffffffff);
  static const black = Color(0xff000000);
  static const black38 = Color(0x61000000);
  static const black45 = Color(0x73000000);
  static const clear = Color(0x00000000);
  static const scrimBottom = Color(0xb3000000);

  // Revisão da partida.
  static const paper = Color(0xfff2f2f0);
  static const markBlue = Color(0xcc3e7bc4);
  static const markGreen = Color(0xcc5fa14a);

  // Estilo do objetivo (ganhar = verde, defender = azul).
  static const goalWin = Color(0xff2e7d32);
  static const goalWinDk = Color(0xff7bd88f);
  static const goalWinBg = Color(0xffdcf2df);
  static const goalWinBgDk = Color(0xff1f4a2a);
  static const goalWinOn = Color(0xff1b4d20);
  static const goalWinOnDk = Color(0xffc8f2cf);
  static const goalDraw = Color(0xff1565c0);
  static const goalDrawDk = Color(0xff8cc4ff);
  static const goalDrawBg = Color(0xffddebfb);
  static const goalDrawBgDk = Color(0xff1d3a5c);
  static const goalDrawOn = Color(0xff0d3c78);
  static const goalDrawOnDk = Color(0xffd3e6ff);
  static const resultUpDk = Color(0xff3fa55a);
  static const resultDownDk = Color(0xffd9534f);

  static const shine = Color(0xccffffff);
  static const shineClear = Color(0x00ffffff);

  // Jogo às cegas.
  static const greenBlind = Color(0xff43a047);

  // Os ícones dos atalhos da tela inicial (canvas `CompModoTile`).
  static const tileGreen = Color(0xffd3f0da);
  static const tileGreenOn = Color(0xff0f3d17);
  static const tilePurple = Color(0xffe8ddfb);
  static const tilePurpleOn = Color(0xff2e1a5e);

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
