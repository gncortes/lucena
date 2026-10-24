import 'package:flutter/widgets.dart';

/// A prévia do Pilares do Xadrez (T82): venda, mapa e capítulo.
abstract final class CoursePreviewKeys {
  static const sale = Key('coursePreview.sale');
  static const saleScroll = Key('coursePreview.sale.scroll');
  static Key tab(int index) => Key('coursePreview.sale.tab.$index');
  static const buy = Key('coursePreview.sale.buy');
  static const priceCard = Key('coursePreview.sale.price');
  static Key faq(int index) => Key('coursePreview.sale.faq.$index');
  static Key part(int index) => Key('coursePreview.sale.part.$index');
  static const map = Key('coursePreview.map');
  static const mapContinue = Key('coursePreview.map.continue');
  static const mapTest = Key('coursePreview.map.test');
  static Key mapChapter(String id) => Key('coursePreview.map.chapter.$id');
  static const chapter = Key('coursePreview.chapter');
  static Key chapterLesson(String id) =>
      Key('coursePreview.chapter.lesson.$id');
  static const chapterExercises = Key('coursePreview.chapter.exercises');
  static const chapterStart = Key('coursePreview.chapter.start');
}
