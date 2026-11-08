// A Play Developer API (ofertas de produto único: `monetization.onetimeproducts
// .purchaseOptions.offers`) ainda não está ligada: falta a conta de serviço da
// Function no Play Console (Usuários e permissões, uma vez). Até lá toda
// promoção nova fica "Não publicada" com o motivo `naoConfigurada`, e o preço
// vem do valor de lançamento. O cliente real entra aqui, com a mesma interface.
import { ErroPlay, type PlayOfertas } from './promocoes';

/** Preço de lançamento do vitalício (R$ 60,00), até a leitura pela Play. */
export const PRECO_LANCAMENTO_CENTAVOS = 6000;

export const playNaoConfigurada: PlayOfertas = {
  async precoCentavos() {
    return PRECO_LANCAMENTO_CENTAVOS;
  },
  async criarOferta() {
    throw new ErroPlay('naoConfigurada', 'Play Developer API não configurada.');
  },
  async ofertaExiste() {
    return false;
  },
  async desativarOferta() {
    throw new ErroPlay('naoConfigurada', 'Play Developer API não configurada.');
  },
};
