import 'package:freezed_annotation/freezed_annotation.dart';

part 'board_settings.freezed.dart';

/// Cores das casas do tabuleiro.
enum BoardColors {
  blue,
  green,
  brown,
  gray,
  purple;

  static const fallback = BoardColors.blue;

  /// Valor gravado nas preferências.
  String get code => name;

  static BoardColors fromCode(String? code) =>
      values.asNameMap()[code] ?? fallback;
}

/// Conjunto de peças. Só entram conjuntos de licença livre, compatível com a
/// AGPL do app (ver `THIRD-PARTY-NOTICES.md`).
enum PieceStyle {
  cburnett('Cburnett'),
  merida('Merida'),
  chessnut('Chessnut'),
  pirouetti('Pirouetti'),
  mpchess('MPChess'),
  firi('Firi'),
  rhosgfx('RhosGFX'),
  fantasy('Fantasy'),
  celtic('Celtic'),
  spatial('Spatial'),
  pixel('Pixel'),
  letter('Letter');

  const PieceStyle(this.label);

  /// Nome próprio do conjunto: não é traduzido.
  final String label;

  static const fallback = PieceStyle.cburnett;

  /// Valor gravado nas preferências.
  String get code => name;

  static PieceStyle fromCode(String? code) =>
      values.asNameMap()[code] ?? fallback;
}

/// Preferências do tabuleiro. Valem em todo tabuleiro do app.
@freezed
abstract class BoardSettings with _$BoardSettings {
  const factory BoardSettings({
    @Default(BoardColors.fallback) BoardColors colors,
    @Default(PieceStyle.fallback) PieceStyle pieces,

    /// Letras e números das casas na borda do tabuleiro.
    @Default(true) bool coordinates,
  }) = _BoardSettings;

  const BoardSettings._();

  /// Esta configuração com a aparência (cores, peças, coordenadas) de fábrica.
  BoardSettings withDefaultAppearance() {
    const defaults = BoardSettings();
    return copyWith(
      colors: defaults.colors,
      pieces: defaults.pieces,
      coordinates: defaults.coordinates,
    );
  }
}
