import 'dart:ui';

/// O aparelho principal de teste (Gabriel, 04/11/2026): o tamanho mais comum
/// no Brasil, 1080x2400 a 420 dpi.
const aparelhoPrincipalFisico = Size(1080, 2400);

/// A densidade do aparelho principal (420 dpi / 160).
const aparelhoPrincipalDpr = 420 / 160;

/// O aparelho principal em dp (411,4 x 914,3), para os testes que montam a
/// tela com densidade 1.
const aparelhoPrincipal = Size(
  1080 / aparelhoPrincipalDpr,
  2400 / aparelhoPrincipalDpr,
);
