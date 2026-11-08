// Compra conferida na Play (R24, H-R5-3A): `purchases.productsv2.getproductpurchasev2`
// lê a compra pelo token e `purchases.products.acknowledge` a reconhece (sem
// isso a Play devolve o dinheiro em 3 dias). Decisão do Gabriel: no dev e no
// emulador a Play é simulada por tokens de teste; em produção o cliente real
// entra aqui, com a mesma interface, quando a conta de serviço estiver no Play Console.
import { createHash } from 'node:crypto';

/** Estado da compra (`purchaseStateContext.purchaseState`). */
export type EstadoCompra = 'PURCHASED' | 'PENDING' | 'CANCELLED';

/** Uma linha da compra (`productLineItem`). */
export interface LinhaCompra {
  productId: string;
  offerId: string | null;
  offerTags: string[];
}

/** O que a conferência usa de `ProductPurchaseV2`. */
export interface CompraPlay {
  estado: EstadoCompra;
  orderId: string;
  linhas: LinhaCompra[];
  /** `obfuscatedExternalAccountId`: o app manda o uid no `launchBillingFlow`. */
  conta: string | null;
  /** `regionCode` (ISO 3166-1 alfa-2) do país da compra. */
  regiao: string | null;
  reconhecida: boolean;
  teste: boolean;
}

export class ErroPlayCompra extends Error {
  constructor(
    readonly motivo: 'naoConfigurada' | 'tokenInvalido' | 'outro',
    msg: string = motivo,
  ) {
    super(msg);
  }
}

export interface PlayCompras {
  consultar(token: string): Promise<CompraPlay>;
  reconhecer(produto: string, token: string): Promise<void>;
}

export const playComprasNaoConfigurada: PlayCompras = {
  async consultar() {
    throw new ErroPlayCompra('naoConfigurada', 'Play Developer API não configurada.');
  },
  async reconhecer() {
    throw new ErroPlayCompra('naoConfigurada', 'Play Developer API não configurada.');
  },
};

/** Prefixo dos tokens de teste aceitos pela Play simulada. */
export const PREFIXO_TESTE = 'teste:';

/**
 * Play simulada (dev e emulador). Token: `teste:<estado>[:<offerId>][:<uid>]`,
 * com estado `compra`, `pendente` ou `cancelada`; `-` no offerId = preço cheio;
 * sem uid, a compra vale para quem conferir. O mesmo token dá sempre o mesmo
 * `orderId`; o reconhecimento fica guardado na instância.
 */
export function playComprasSimulada(produto: string): PlayCompras {
  const reconhecidas = new Set<string>();
  return {
    async consultar(token) {
      if (!token.startsWith(PREFIXO_TESTE)) throw new ErroPlayCompra('tokenInvalido', 'Token fora da Play simulada.');
      const [estadoTxt, offerTxt, uid] = token.slice(PREFIXO_TESTE.length).split(':');
      const estados: Record<string, EstadoCompra> = { compra: 'PURCHASED', pendente: 'PENDING', cancelada: 'CANCELLED' };
      const estado = estados[estadoTxt ?? ''];
      if (!estado) throw new ErroPlayCompra('tokenInvalido', `Estado de teste desconhecido: ${estadoTxt}.`);
      const offerId = offerTxt && offerTxt !== '-' ? offerTxt : null;
      const hash = createHash('sha256').update(token).digest('hex').slice(0, 16).toUpperCase();
      return {
        estado,
        orderId: `GPA.TESTE-${hash}`,
        linhas: [{ productId: produto, offerId, offerTags: offerId ? ['promocao'] : [] }],
        conta: uid || null,
        regiao: 'BR',
        reconhecida: reconhecidas.has(token),
        teste: true,
      };
    },
    async reconhecer(_produto, token) {
      reconhecidas.add(token);
    },
  };
}

/** Dev (`lucena-dev-gnc`) e emulador usam a Play simulada (decisão do Gabriel). */
export function playSimuladaNoAmbiente(env: NodeJS.ProcessEnv = process.env): boolean {
  return env.FUNCTIONS_EMULATOR === 'true' || env.GCLOUD_PROJECT === 'lucena-dev-gnc';
}
