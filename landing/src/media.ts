// Clipes do app (tools/capture no repositório): para cada idioma capturado,
// landing/assets/media/<idioma>/<nome>.{webm,mp4}, <nome>-poster.webp e o
// print <nome>.webp. Os idiomas sem captura própria usam os de inglês.
export const clips = {
  hero: 'destaque',
  home: 'inicio',
  beginner: 'iniciante-aulas',
  intermediate: 'intermediario-jornada',
  queenRook: 'aula-dama-vs-torre',
  bishopKnight: 'aula-bispo-e-cavalo',
  lucena: 'aula-lucena',
  maia: 'maia-nivel-e-ritmo',
  stockfish: 'partida-stockfish',
  speedrun: 'speedrun',
  analysis: 'analise-partida',
  custom: 'personalizacao',
} as const;

export type Clip = keyof typeof clips;

/** Os idiomas com captura própria; o resto usa `en`. */
const captured: Record<string, string> = { 'pt-br': 'pt', en: 'en', es: 'es' };

/** Pasta das capturas do idioma [locale], relativa a landing/assets. */
export const mediaDir = (locale: string) => `media/${captured[locale] ?? 'en'}`;

/** O tamanho dos vídeos na web: o formato da tela do Pixel 9 Pro XL. */
export const clipSize = { width: 720, height: 1604 };
