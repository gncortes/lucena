// Linhas como a consulta `sqlDoDia` devolve do export do Analytics (dia 25/11/2026).
import type { LinhaEvento } from '../../src/fechamento/consultas';

function l(evento: string, pais: string, n: { eventos?: number; pessoas: number }, d: Partial<LinhaEvento> = {}): LinhaEvento {
  return {
    evento,
    pais,
    curso: null,
    aula: null,
    capitulo: null,
    exercicio: null,
    acertou: null,
    fonte: null,
    eventos: n.eventos ?? n.pessoas,
    pessoas: n.pessoas,
    ...d,
  };
}

export const EXPORT_25_11: LinhaEvento[] = [
  l('_ativos_app', 'BR', { pessoas: 120 }),
  l('_ativos_app', 'PT', { pessoas: 8 }),
  l('_ativos_curso', 'BR', { pessoas: 40 }, { curso: 'pilares' }),
  l('_ativos_curso', 'PT', { pessoas: 2 }, { curso: 'pilares' }),
  l('treino_objetivo_definido', 'BR', { pessoas: 6 }, { curso: 'pilares' }),
  l('treino_objetivo_definido', 'PT', { pessoas: 1 }, { curso: 'pilares' }),
  l('treino_meta_inicio', 'BR', { eventos: 90, pessoas: 35 }, { curso: 'pilares' }),
  l('treino_meta_fim', 'BR', { eventos: 70, pessoas: 30 }, { curso: 'pilares', acertou: 'sim' }),
  l('treino_meta_fim', 'BR', { eventos: 15, pessoas: 10 }, { curso: 'pilares', acertou: 'nao' }),
  l('treino_ciclo_fim', 'BR', { eventos: 3, pessoas: 3 }, { curso: 'pilares' }),
  l('pilares_oferta_vista', 'BR', { eventos: 30, pessoas: 25 }),
  l('demo_inicio', 'BR', { pessoas: 9 }),
  l('aula_aberta', 'BR', { pessoas: 50 }, { aula: 'oposicao' }),
  l('aula_concluida', 'BR', { pessoas: 12 }, { aula: 'oposicao' }),
  l('aula_capitulo_inicio', 'BR', { pessoas: 30 }, { aula: 'oposicao', capitulo: 'c1' }),
  l('aula_capitulo_fim', 'BR', { pessoas: 20 }, { aula: 'oposicao', capitulo: 'c1' }),
  l('exercicio_resultado', 'BR', { eventos: 14, pessoas: 9 }, { aula: 'oposicao', capitulo: 'c1', exercicio: 'ex1.Kd7', acertou: 'nao' }),
  l('exercicio_resultado', 'BR', { eventos: 40, pessoas: 20 }, { aula: 'oposicao', capitulo: 'c1', exercicio: 'ex1.Kd7', acertou: 'sim' }),
  l('aula_saida', 'BR', { eventos: 4, pessoas: 4 }, { aula: 'oposicao', capitulo: 'c1', exercicio: 'ex2' }),
  l('aula_saida', 'BR', { eventos: 2, pessoas: 2 }, { aula: 'oposicao', capitulo: 'c2' }),
  l('campanha_link_aberto', 'BR', { pessoas: 18 }, { fonte: 'instagram' }),
  l('campanha_instalacao', 'BR', { pessoas: 7 }, { fonte: 'instagram' }),
  l('campanha_link_aberto', 'PT', { pessoas: 3 }, { fonte: 'youtube' }),
];
