import 'progress_summary.dart';

/// O que a junção encontrou.
class SyncResult {
  const SyncResult({required this.summary, required this.hadRemote});

  /// O progresso junto, que agora vale no aparelho e na conta.
  final ProgressSummary summary;

  /// A conta já tinha progresso de outro aparelho (a tela "Bem-vindo de
  /// volta").
  final bool hadRemote;
}
