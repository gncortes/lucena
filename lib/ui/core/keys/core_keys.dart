import 'package:flutter/widgets.dart';

/// Chaves dos componentes compartilhados de `core/widgets` (E1.08, lote 1).
abstract final class CoreKeys {
  static const actionsFooter = Key('core.actionsFooter');
  static const sectionTitle = Key('core.sectionTitle');
  static const snackBar = Key('core.snackBar');
  static const emptyState = Key('core.emptyState');
  static const emptyAction = Key('core.emptyAction');
  static const skeleton = Key('core.skeleton');
  static const skeletonBlock = Key('core.skeletonBlock');
  static const card = Key('core.card');
  static const busySpinner = Key('core.busySpinner');
  static const infoChip = Key('core.infoChip');
  static const nicknameField = Key('core.nicknameField');

  /// O aviso de que um link externo não abriu (Gap 6 do Sobre).
  static const linkFailure = Key('core.linkFailure');
}
