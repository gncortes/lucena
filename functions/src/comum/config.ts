// Opções comuns a todas as Functions do Lucena.
import { setGlobalOptions } from 'firebase-functions/options';

/** São Paulo: perto dos alunos e do Firestore servido no Brasil. */
export const REGIAO = 'southamerica-east1';

/** Fuso das rotinas agendadas (fechamento do dia às 03:00 de Brasília). */
export const FUSO = 'America/Sao_Paulo';

setGlobalOptions({ region: REGIAO, maxInstances: 10 });
