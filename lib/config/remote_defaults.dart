// Gerado por tools/gen_remote_defaults.py a partir de
// firebase/remoteconfig.template.json. Não edite: mude o modelo e rode o
// script.

/// As chaves do Remote Config (E1.32 §1).
abstract final class RemoteKeys {
  static const updateMinBuild = 'update_min_build';
  static const updateRecommendedBuild = 'update_recommended_build';
  static const adsEnabled = 'ads_enabled';
  static const adsFreeLessons = 'ads_free_lessons';
  static const adsMinGapSeconds = 'ads_min_gap_seconds';
  static const volta3dTitulo = 'volta_3d_titulo';
  static const volta3dCorpo = 'volta_3d_corpo';
  static const voltaAulaTitulo = 'volta_aula_titulo';
  static const voltaAulaCorpo = 'volta_aula_corpo';
  static const voltaTorneioTitulo = 'volta_torneio_titulo';
  static const voltaTorneioCorpo = 'volta_torneio_corpo';
}

/// O valor de cada chave quando o app nunca buscou ou está sem Firebase.
const remoteDefaults = <String, Object>{
  RemoteKeys.updateMinBuild: 0,
  RemoteKeys.updateRecommendedBuild: 0,
  RemoteKeys.adsEnabled: true,
  RemoteKeys.adsFreeLessons: 2,
  RemoteKeys.adsMinGapSeconds: 180,
  RemoteKeys.volta3dTitulo: 'O final do dia está esperando',
  RemoteKeys.volta3dCorpo:
      'Um final novo por dia. Venha ver se você acerta o de hoje.',
  RemoteKeys.voltaAulaTitulo: 'A aula ficou no meio',
  RemoteKeys.voltaAulaCorpo:
      'Volte de onde parou. Falta pouco para fechar o capítulo.',
  RemoteKeys.voltaTorneioTitulo: 'Saiu um final de torneio novo',
  RemoteKeys.voltaTorneioCorpo:
      'Um final de uma partida de verdade. Tente resolver.',
};
