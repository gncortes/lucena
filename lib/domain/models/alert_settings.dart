import 'package:freezed_annotation/freezed_annotation.dart';

part 'alert_settings.freezed.dart';

/// O que o Lucena pode avisar (Perfil > Avisos, E1.21). Cada chave é um canal
/// do Android; as três de push só existem com o Firebase.
@freezed
abstract class AlertSettings with _$AlertSettings {
  const factory AlertSettings({
    /// Um final novo de torneio na região (push, tópicos `torneio_*`).
    @Default(true) bool tournaments,

    /// O final do dia e os lembretes locais (sequência, lição, semana).
    @Default(true) bool daily,

    /// Recursos novos do Lucena (push, tópico [AlertTopics.news]).
    @Default(false) bool news,

    /// Uma aula de finais nova (push, tópico [AlertTopics.lessons]).
    @Default(true) bool lessons,

    /// A hora dos lembretes locais, em minutos desde a meia-noite (4c: 19h).
    @Default(AlertSettings.defaultReminder) int reminderMinutes,
  }) = _AlertSettings;

  const AlertSettings._();

  /// 19:00.
  static const defaultReminder = 19 * 60;

  /// Quantas chaves estão ligadas. Sem push ([push] falso), só a local conta.
  int enabled({required bool push}) => push
      ? [tournaments, daily, news, lessons].where((on) => on).length
      : (daily ? 1 : 0);

  /// Quantas chaves existem: quatro com push, uma sem.
  static int total({required bool push}) => push ? 4 : 1;
}

/// Os nomes dos tópicos do FCM.
abstract final class AlertTopics {
  /// Todos os aparelhos (campanhas do console).
  static const everyone = 'all';
  static const news = 'novidades';
  static const lessons = 'aulas';

  /// O final do dia pelo push (o painel manda; antes era só local).
  static const daily = 'dia';

  /// `pais_BR`, ou `pais_BR_PR` com o estado: o público do push segmentado
  /// (E1.19 3.8).
  static String country(String code, [String? state]) =>
      state == null ? 'pais_$code' : 'pais_${code}_$state';

  /// `idioma_pt`: a versão da mensagem no idioma do app.
  static String language(String code) => 'idioma_$code';

  /// `torneio_BR`, ou `torneio_BR_PR` com o estado.
  static String tournament(String country, [String? state]) =>
      state == null ? 'torneio_$country' : 'torneio_${country}_$state';
}
