// Respostas do runFunnelReport (v1alpha) no formato gravado da Data API: sem breakdown, os nomes dos passos vêm
// numerados ("1. ...") e os números como texto. Período 19–25/11/2026 (Entrada no app).
import type { RespostaFunil } from '../../src/fechamento/atencao';

const linha = (passo: string, pessoas: number, conclusao: string) => ({
  dimensionValues: [{ value: passo }],
  metricValues: [{ value: String(pessoas) }, { value: conclusao }, { value: '0' }, { value: '0' }],
});

const cabecalho = {
  dimensionHeaders: [{ name: 'funnelStepName' }],
  metricHeaders: [
    { name: 'activeUsers', type: 'TYPE_INTEGER' },
    { name: 'funnelStepCompletionRate', type: 'TYPE_INTEGER' },
    { name: 'funnelStepAbandonments', type: 'TYPE_INTEGER' },
    { name: 'funnelStepAbandonmentRate', type: 'TYPE_INTEGER' },
  ],
};

export const FUNIL_ENTRADA_19_25: RespostaFunil = {
  funnelTable: {
    ...cabecalho,
    rows: [
      linha('1. Primeira abertura', 400, '0.9'),
      linha('2. Boas-vindas', 360, '0.75'),
      linha('3. Fim das boas-vindas', 270, '0.9'),
      linha('4. Nível definido', 243, '0'),
    ],
  },
};

/** Funil de poucos: só o primeiro passo tem gente; os outros não vêm na resposta. */
export const FUNIL_POUCOS: RespostaFunil = {
  funnelTable: { ...cabecalho, rows: [linha('1. Convite para a conta', 12, '0.5')] },
};
