import 'package:flutter/widgets.dart';

/// Curso liberado (H-R5-62): o presente ou a compra que abriu o curso.
abstract final class CourseUnlockedKeys {
  static const screen = Key('courseUnlocked');
  static const close = Key('courseUnlocked.close');
  static const title = Key('courseUnlocked.title');
  static const speech = Key('courseUnlocked.speech');

  /// "Montar o meu plano" (sem plano) ou "Ir para o curso" (com plano).
  static const action = Key('courseUnlocked.action');
}
