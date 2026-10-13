import 'package:flutter/widgets.dart';

abstract final class LessonSoundKeys {
  static const dialog = Key('lesson.sound.dialog');
  static const close = Key('lesson.sound.close');
  static const sound = Key('lesson.sound.enabled');
  static const teacherVoice = Key('lesson.sound.teacherVoice');
  static const speeds = Key('lesson.sound.speeds');
  static Key speed(double value) => ValueKey('lesson.sound.speed.$value');
}
