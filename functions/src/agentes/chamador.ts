// AG-5b.3 · Reconferência do chamador do porteiro (E1.21 §6.4): além do `invoker: 'private'` (IAM do Cloud Run),
// o código confere o ID token do Google — assinatura, `email` da conta porteiro-agentes e `aud` do importarLote.
// Se alguém der run.invoker a outra conta por engano, o porteiro ainda recusa.
import { OAuth2Client } from 'google-auth-library';

export interface DadosDoToken {
  email?: string;
  email_verified?: boolean;
  aud?: string | string[];
}

/** Confere a assinatura do token e devolve o conteúdo (lança se inválido ou vencido). */
export type VerificarToken = (token: string) => Promise<DadosDoToken>;

export class ChamadorRecusado extends Error {}

/** Conta de serviço que o workflow do GitHub assume pelo WIF. */
export function emailDoPorteiro(projeto: string | undefined): string {
  return `porteiro-agentes@${projeto ?? 'sem-projeto'}.iam.gserviceaccount.com`;
}

/** O `aud` é a URL da function (Cloud Run `importarlote-…run.app` ou `…cloudfunctions.net/importarLote`). */
function audDoPorteiro(aud: DadosDoToken['aud']): boolean {
  const lista = Array.isArray(aud) ? aud : aud ? [aud] : [];
  return lista.some((a) => {
    try {
      const u = new URL(a);
      return u.protocol === 'https:' && (u.hostname.startsWith('importarlote-') || u.pathname === '/importarLote');
    } catch {
      return false;
    }
  });
}

export async function conferirChamador(
  authorization: string | undefined,
  verificar: VerificarToken,
  esperado: string,
): Promise<void> {
  const m = /^Bearer (.+)$/.exec(authorization ?? '');
  if (!m) throw new ChamadorRecusado('Sem token.');
  let dados: DadosDoToken;
  try {
    dados = await verificar(m[1]);
  } catch {
    throw new ChamadorRecusado('Token inválido.');
  }
  if (dados.email !== esperado || dados.email_verified !== true) throw new ChamadorRecusado('Conta não autorizada.');
  if (!audDoPorteiro(dados.aud)) throw new ChamadorRecusado('Token para outro destino.');
}

/** Verificação real: certificados públicos do Google (a audiência é conferida em `conferirChamador`). */
export function verificadorGoogle(): VerificarToken {
  const cliente = new OAuth2Client();
  return async (token) => {
    const ticket = await cliente.verifyIdToken({ idToken: token });
    return (ticket.getPayload() ?? {}) as DadosDoToken;
  };
}
