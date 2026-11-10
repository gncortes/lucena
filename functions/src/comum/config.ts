// Opções comuns a todas as Functions do Lucena.
import { setGlobalOptions } from 'firebase-functions/options';

/** São Paulo: perto dos alunos e do Firestore servido no Brasil. */
export const REGIAO = 'southamerica-east1';

/** Fuso das rotinas agendadas (fechamento do dia às 03:00 de Brasília). */
export const FUSO = 'America/Sao_Paulo';

/**
 * Opções das callables que o app chama: só o app oficial (App Check: Play Integrity em prod, provedor de
 * depuração cadastrado no console em dev). Token inválido ou ausente: 401 antes do código rodar. No Emulator
 * Suite fica desligado, para os testes chamarem sem token. As callables do painel web ficam de fora: já exigem
 * admin e o painel ainda não tem App Check.
 */
export const SO_APP = { enforceAppCheck: process.env.FUNCTIONS_EMULATOR !== 'true' } as const;

/** Teto baixo de instâncias: limita o custo no Blaze (dev e prod). */
setGlobalOptions({ region: REGIAO, maxInstances: 3 });
