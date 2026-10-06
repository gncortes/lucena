// Clipes gravados na Entrega 1 (landing/assets/<nome>.{webm,mp4},
// <nome>-poster.webp e o print <nome>.webp). Todos em retrato, 1440x3120 no
// aparelho e 720x1560 na web.
export const clips = {
  hero: 'destaque',
  home: 'inicio',
  beginner: 'iniciante-aulas',
  intermediate: 'intermediario-jornada',
  queenRook: 'aula-dama-vs-torre',
  bishopKnight: 'aula-bispo-e-cavalo',
  maia: 'maia-nivel-e-ritmo',
  stockfish: 'partida-stockfish',
  speedrun: 'speedrun',
  analysis: 'analise-partida',
  custom: 'personalizacao',
} as const;

export type Clip = keyof typeof clips;

export const clipSize = { width: 720, height: 1560 };
